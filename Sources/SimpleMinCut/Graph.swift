/// An undirected, weighted graph `G = (V, E)`.
///
/// Vertices are numbered `0 ..< vertexCount`. Each edge `e` has a positive
/// weight `w(e)` (see chapter 2 of the thesis "Minimale Schnitte in Graphen",
/// Stoer/Wagner [SW94]).
///
/// The edge weights are stored as a symmetric adjacency matrix. This suits
/// the "simple" min-cut algorithm, which repeatedly merges vertices and works
/// conveniently on a matrix.
public struct Graph {
    /// Number of vertices `|V|`.
    public private(set) var vertexCount: Int

    /// Symmetric weight matrix. `weight[u][v] == weight[v][u]`,
    /// `weight[v][v] == 0`. A value of `0` means "no edge".
    public private(set) var weight: [[Double]]

    /// Creates an edgeless graph with `vertexCount` vertices.
    public init(vertexCount: Int) {
        precondition(vertexCount >= 0, "vertexCount darf nicht negativ sein")
        self.vertexCount = vertexCount
        self.weight = Array(
            repeating: Array(repeating: 0.0, count: vertexCount),
            count: vertexCount
        )
    }

    /// Creates a graph from an edge list `(u, v, w)`.
    ///
    /// - Parameters:
    ///   - vertexCount: Number of vertices.
    ///   - edges: Edges as triples `(u, v, weight)`. Multiple edges between
    ///     the same pair of vertices are summed up.
    public init(vertexCount: Int, edges: [(Int, Int, Double)]) {
        self.init(vertexCount: vertexCount)
        for (u, v, w) in edges {
            addEdge(u, v, weight: w)
        }
    }

    /// Adds an undirected edge `{u, v}` with weight `weight`.
    ///
    /// If the edge already exists, the weight is added (multigraph: parallel
    /// edges are collapsed into one edge with the summed weight).
    public mutating func addEdge(_ u: Int, _ v: Int, weight w: Double) {
        precondition(u >= 0 && u < vertexCount, "Knoten \(u) ausserhalb 0 ..< \(vertexCount)")
        precondition(v >= 0 && v < vertexCount, "Knoten \(v) ausserhalb 0 ..< \(vertexCount)")
        precondition(u != v, "Schleifen (u == v) sind nicht erlaubt")
        precondition(w > 0, "Kantengewichte muessen positiv sein")
        weight[u][v] += w
        weight[v][u] += w
    }
}
