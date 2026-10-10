# SimpleMinCut: Stoer–Wagner in Swift

A Swift package of about 150 lines that computes a global minimum cut with the
Stoer–Wagner algorithm ([SW94], "A Simple Min-Cut Algorithm"). It is the
implementation companion to my 1998 ETH semester thesis *Minimale Schnitte in
Graphen* ([`mincut11.pdf`](mincut11.pdf)) and the blog post
[Minimum cuts in graphs — revisiting my 1998 ETH thesis](https://kausch.li/mincut-thesis-summary/).

The goal is readability, not speed: a weighted adjacency matrix, a linear scan
instead of a priority queue, and no flow computations at all. The whole
algorithm fits on one screen, and the test suite checks every answer against
brute force.

## The idea

![One Stoer–Wagner phase step by step, then four phases with cut weights 4, 3, 7, 5; the minimum is 3](MinimumCutsInGraphsAlgo.png)

The algorithm runs `|V| − 1` phases. Each phase (`MinimumCutPhase`):

1. Starts with `A = {a}`.
2. While `A ≠ V`, adds the vertex `z ∉ A` with maximal `w(A, z)`.
3. Takes the last two vertices added, `s` (second-to-last) and `t` (last).
   The *phase cut* `({t}, V\{t})` is a minimum `s`–`t` cut; its weight is remembered.
4. Merges `s` and `t`.

The lightest phase cut over all phases is the minimum cut (Lemma 2.1 of the thesis).

## Package layout

The package has one library, one command-line tool and one test target
(Swift 6 tools, `swift-argument-parser` for the CLI).

| File | Lines | Role |
| --- | --- | --- |
| `Sources/SimpleMinCut/Graph.swift` | 53 | Undirected weighted graph as a symmetric matrix |
| `Sources/SimpleMinCut/StoerWagner.swift` | 95 | `minimumCut()`, the phase loop and the result type |
| `Sources/simple-mincut-cli/SimpleMinCutCommand.swift` | 78 | Reads a graph from a file and prints the cut |
| `Tests/SimpleMinCutTests/SimpleMinCutTests.swift` | 130 | Examples plus a brute-force oracle |

## Usage as a library

```swift
import SimpleMinCut

let g = Graph(vertexCount: 4, edges: [
    (0, 1, 3), (1, 2, 1), (2, 3, 3), (3, 0, 1),
])

let cut = try g.minimumCut()
print(cut.weight)      // 2.0
print(cut.partition)   // one side S, e.g. [2, 3]
```

- `Graph` stores weights in `weight: [[Double]]`. `addEdge` adds to the
  existing value, so parallel edges collapse into one summed edge. That is
  exactly what a merge needs later.
- Loops, zero and negative weights are rejected with a precondition. With
  negative weights min-cut becomes NP-complete, so the algorithm's guarantee
  would be gone.
- The result, `MinimumCut`, carries the weight and one side `S` in original
  vertex numbers.
- A graph with fewer than two vertices throws
  `MinimumCutError.tooFewVertices`, because a cut needs two non-empty sides.
- `minimumCut(start:)` takes an optional start vertex. It changes the
  intermediate steps, not the result.

## CLI

```
swift run simple-mincut <file> [--start n]
```

Input format (whitespace-separated): `|V|`, then `|E|`, then `|E|` triples
`u v weight` (vertices are `0 ..< |V|`). The standard example from [SW94] is
in `examples/stoer-wagner.txt`:

```
$ swift run simple-mincut examples/stoer-wagner.txt
Minimaler Schnitt:
  Gewicht: 4.0
  S      : [2, 3, 6, 7]
  V \ S  : [0, 1, 4, 5]
```

## How it works

### One phase: growing A

A phase grows a set `A` from a start vertex, always adding the vertex most
strongly connected to `A`. The code keeps one running number per vertex,
`connectivity[z] = w(A, z)`, so it never recomputes a sum:

```swift
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
```

Three details keep it short:

- **No special start case.** All values start at 0, and `max(by:)` returns the
  first of equal maxima, so the first pick is `active[0]`, the start vertex `a`.
- **The tuple shift** `(s, t) = (t, …)` keeps the last two additions without
  extra bookkeeping.
- **The incremental update** adds only the new vertex's edges to each
  remaining vertex: a single row of the matrix.

When `t` is added last, `A` is everything except `t`. So the phase cut
`({t}, V\{t})` is a minimum `s`–`t` cut of the current graph — the lemma the
whole correctness proof rests on.

### The outer loop: merge and remember

`minimumCut(start:)` runs `|V| − 1` phases on a working copy of the matrix.
Three pieces of state carry the merges:

- `w` — the weights between supervertices, updated in place.
- `members[v]` — the original vertices inside supervertex `v`, so the final cut
  can be reported in the caller's numbering.
- `active` — the supervertices not merged away yet; `swapAt(0, start)` puts the
  chosen start vertex first.

```swift
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
```

The merge is two additions per neighbour: row and column `t` are folded into
`s`, and `t` leaves `active`. Its old row stays in the matrix but is never read
again. The phase weight is the sum of row `t` over the active vertices.

A disconnected graph needs no special case: some phase then has a `t` with no
edges into `A`, and the loop reports a cut of weight 0.

## Complexity

This variant runs in `O(|V|³)` time and `O(|V|²)` memory: each phase scans and
updates every active vertex once per addition. That is fine for dense graphs of
a few thousand vertices. The bound from the paper,
`O(|V||E| + |V|² log |V|)`, needs adjacency lists and a Fibonacci heap instead
of the linear scan.

## Tests

```
swift test
```

The tests use Swift Testing and cover:

- the 8-vertex example from [SW94] (minimum cut 4, `S = {2, 3, 6, 7}`);
- a triangle, a path, a disconnected graph (cut 0), parallel edges and the
  too-few-vertices error;
- the same result from every start vertex;
- 200 random graphs with 2–8 vertices and weights 1–9, checked against a
  brute-force search over all `2^(|V|−1)` partitions, with a seeded generator
  so failures are reproducible.

## Roadmap

The repository is the plain algorithm. The two practical improvements from the
thesis each fit in a few lines.

**Min-degree initial guess.** Every single vertex `v` is a cut of weight
`deg(v)`. Starting `best` at the lightest vertex instead of infinity costs one
pass over the matrix:

```swift
let v0 = (0 ..< vertexCount).min { weight[$0].reduce(0, +) < weight[$1].reduce(0, +) }!
var best = MinimumCut(weight: weight[v0].reduce(0, +), partition: [v0])
```

**Early merge.** Suppose vertex `z` joins `A` with `w(A, z) ≥ best`, and `y`
was added just before it. Applying the phase lemma to the subgraph on
`A ∪ {z}` shows that every cut separating `y` and `z` costs at least
`w(A, z)`. Such a cut cannot beat `best`, so `y` and `z` can be merged right
away and the phase ends early:

```swift
let c = connectivity[remaining[i]]!
(s, t) = (t, remaining.remove(at: i))
if s != t && c >= best { return (s, t, isPhaseCut: false) }  // merge, no candidate
```

The two reinforce each other: a good `best` from the start makes early merges
fire sooner. On random graphs the minimum cut is almost always a single
lightest vertex, so the guess is usually already optimal and most phases stop
early.

Next steps, in order of payoff:

1. Return `connectivity[t]` from the phase instead of re-summing row `t`.
2. Add the min-degree guess and early merge, with a counter for phases ended
   early.
3. Replace the dictionary with a flat `[Double]` and benchmark random graphs
   against a two-cluster graph, where the minimum cut is not a single vertex.
4. An adjacency-list version with a heap for large sparse graphs.

## References

- [SW94] M. Stoer, F. Wagner: *A Simple Min-Cut Algorithm*. ESA 1994 / J. ACM 44(4), 1997.
- T. Kausch: *Minimale Schnitte in Graphen*, semester thesis, ETH Zürich, 1998 ([`mincut11.pdf`](mincut11.pdf)).
- Blog: [Minimum cuts in graphs — revisiting my 1998 ETH thesis](https://kausch.li/mincut-thesis-summary/)
