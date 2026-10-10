/// Result of a minimum cut computation.
///
/// A cut `(S, V\S)` splits the vertex set into two non-empty sets. `weight`
/// is the sum of the weights of all edges with one endpoint in `S` and the
/// other in `V\S`.
public struct MinimumCut: Equatable {
    /// Weight of the cut (sum of the edge weights crossing the cut).
    public let weight: Double

    /// One side `S` of the cut, given by the *original* vertex indices. The
    /// other side is `V \ S`.
    public let partition: Set<Int>

    public init(weight: Double, partition: Set<Int>) {
        self.weight = weight
        self.partition = partition
    }
}

public enum MinimumCutError: Error, Equatable {
    /// The graph has fewer than two vertices -- a cut is not defined.
    case tooFewVertices
}

extension Graph {
    /// Computes a global minimum cut using the simple algorithm of Stoer and
    /// Wagner ([SW94], chapter 2 of the thesis).
    ///
    /// The algorithm consists of `|V| - 1` phases. Each phase determines a
    /// minimum `s`-`t` cut of the current graph (`MinimumCutPhase`) and then
    /// merges the two vertices `s` and `t` added last. The lightest phase cut
    /// over all phases is the minimum cut.
    ///
    /// The graph must be connected for the result to equal the standard
    /// min-cut; for a disconnected graph the algorithm returns a cut of
    /// weight `0`.
    ///
    /// - Parameter start: Start vertex `a` of the first phase (default `0`).
    ///   The choice does not affect the result, only the intermediate steps.
    /// - Returns: Weight and one side of the minimum cut.
    /// - Complexity: `O(|V|^3)` in this simple variant with a linear search
    ///   for the most strongly connected vertex. With a Fibonacci heap a
    ///   phase can be brought down to `O(|E| + |V| log |V|)`.
    public func minimumCut(start: Int = 0) throws -> MinimumCut {
        guard vertexCount >= 2 else { throw MinimumCutError.tooFewVertices }
        precondition(start >= 0 && start < vertexCount, "Startknoten ausserhalb 0 ..< \(vertexCount)")

        var w = weight                                    // weights of the supervertices
        var members = (0 ..< vertexCount).map { [$0] }    // original vertices per supervertex
        var active = Array(0 ..< vertexCount)             // supervertices not merged yet
        active.swapAt(0, start)                           // `a` is added to `A` first

        var best = MinimumCut(weight: .infinity, partition: [])

        while active.count > 1 {
            let (s, t) = Self.minimumCutPhase(w: w, active: active)

            let phaseWeight = active.reduce(0) { $0 + (($1 == t) ? 0 : w[t][$1]) }
            if phaseWeight < best.weight {
                best = MinimumCut(weight: phaseWeight, partition: Set(members[t]))
            }

            // Merge `t` into `s`.
            for x in active where x != s && x != t {
                w[s][x] += w[t][x]
                w[x][s] += w[x][t]
            }
            members[s] += members[t]
            active.removeAll { $0 == t }
        }

        return best
    }

    /// `MinimumCutPhase(G, a)`: `A` grows from `a = active[0]` by repeatedly
    /// adding the vertex `z ∉ A` with maximal `w(A, z)`. Returns the
    /// second-to-last (`s`) and last (`t`) added vertex; the phase cut is
    /// `({t}, V\{t})`.
    private static func minimumCutPhase(w: [[Double]], active: [Int]) -> (s: Int, t: Int) {
        var remaining = active
        var connectivity = [Int: Double](uniqueKeysWithValues: active.map { ($0, 0) })
        var s = active[0], t = active[0]
        while !remaining.isEmpty {
            let i = remaining.indices.max { connectivity[remaining[$0]]! < connectivity[remaining[$1]]! }!
            (s, t) = (t, remaining.remove(at: i))
            for z in remaining { connectivity[z]! += w[t][z] }
        }
        return (s, t)
    }
}
