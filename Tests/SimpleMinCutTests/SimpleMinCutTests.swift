import Testing
@testable import SimpleMinCut

/// Brute-force reference: tries all 2^(n-1) partitions and returns the
/// smallest cut value. Serves as an oracle for small random graphs.
private func bruteForceMinCut(_ g: Graph) -> Double {
    let n = g.vertexCount
    var best = Double.infinity
    // Fix vertex 0 on side S to count each partition only once.
    for mask in 0 ..< (1 << (n - 1)) {
        var inS = [Bool](repeating: false, count: n)
        inS[0] = true
        for b in 0 ..< (n - 1) where (mask >> b) & 1 == 1 {
            inS[b + 1] = true
        }
        // V\S must not be empty.
        if inS.allSatisfy({ $0 }) { continue }
        var weight = 0.0
        for u in 0 ..< n {
            for v in (u + 1) ..< n where inS[u] != inS[v] {
                weight += g.weight[u][v]
            }
        }
        best = min(best, weight)
    }
    return best
}

@Test
func standardExampleFromStoerWagner() throws {
    // 8 vertices (1..8 in the original figure), minimum cut = 4.
    let g = Graph(vertexCount: 8, edges: [
        (0, 1, 2), (0, 4, 3),
        (1, 2, 3), (1, 4, 2), (1, 5, 2),
        (2, 3, 4), (2, 6, 2),
        (3, 6, 2), (3, 7, 2),
        (4, 5, 3),
        (5, 6, 1),
        (6, 7, 3),
    ])
    let cut = try g.minimumCut()
    #expect(cut.weight == 4)
    // Expected partition: {2,3,6,7} vs. {0,1,4,5} (either side).
    let s = cut.partition
    let expected: Set<Int> = [2, 3, 6, 7]
    #expect(s == expected || s == Set(0 ..< 8).subtracting(expected))
}

@Test
func triangleCut() throws {
    let g = Graph(vertexCount: 3, edges: [(0, 1, 1), (1, 2, 2), (0, 2, 3)])
    // The smallest cut separates vertex 1: 1 + 2 = 3.
    let cut = try g.minimumCut()
    #expect(cut.weight == 3)
    #expect(cut.partition == [1] || cut.partition == [0, 2])
}

@Test
func pathGraph() throws {
    // 0 - 1 - 2 - 3 - 4, all weights 5. Every cut costs 5.
    let g = Graph(vertexCount: 5, edges: [(0, 1, 5), (1, 2, 5), (2, 3, 5), (3, 4, 5)])
    let cut = try g.minimumCut()
    #expect(cut.weight == 5)
}

@Test
func disconnectedGraphHasZeroCut() throws {
    // Two separate edges -> cut of weight 0.
    let g = Graph(vertexCount: 4, edges: [(0, 1, 7), (2, 3, 9)])
    let cut = try g.minimumCut()
    #expect(cut.weight == 0)
}

@Test
func startVertexDoesNotChangeResult() throws {
    let g = Graph(vertexCount: 6, edges: [
        (0, 1, 3), (1, 2, 1), (2, 0, 3),
        (3, 4, 3), (4, 5, 1), (5, 3, 3),
        (2, 3, 1),
    ])
    let weights = try (0 ..< 6).map { try g.minimumCut(start: $0).weight }
    #expect(Set(weights) == [1])
}

@Test
func tooFewVerticesThrows() {
    #expect(throws: MinimumCutError.tooFewVertices) {
        _ = try Graph(vertexCount: 1).minimumCut()
    }
}

@Test
func multiEdgesAccumulate() throws {
    var g = Graph(vertexCount: 2)
    g.addEdge(0, 1, weight: 1.5)
    g.addEdge(0, 1, weight: 2.5)
    let cut = try g.minimumCut()
    #expect(cut.weight == 4.0)
}

@Test
func matchesBruteForceOnRandomGraphs() throws {
    var rng = SeededGenerator(seed: 0xC0FFEE)
    for _ in 0 ..< 200 {
        let n = Int.random(in: 2 ... 8, using: &rng)
        var g = Graph(vertexCount: n)
        for u in 0 ..< n {
            for v in (u + 1) ..< n where Bool.random(using: &rng) {
                g.addEdge(u, v, weight: Double(Int.random(in: 1 ... 9, using: &rng)))
            }
        }
        let got = try g.minimumCut().weight
        let want = bruteForceMinCut(g)
        #expect(got == want, "n=\(n) got \(got) want \(want)")
    }
}

/// Deterministic PRNG for reproducible tests.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
