import ArgumentParser
import Foundation
import SimpleMinCut

struct SimpleMinCutCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simple-mincut",
        abstract: "Berechnet einen minimalen Schnitt mit dem Algorithmus von Stör und Wagner.",
        discussion: """
            Eingabeformat (Whitespace-getrennt): |V|, |E|, danach |E| Tripel `u v gewicht` \
            (Knoten sind 0 ..< |V|). Ohne Datei wird das Standardbeispiel \
            aus [SW94] gerechnet (8 Knoten, minimaler Schnitt 4).
            """
    )

    @Argument(help: "Eingabedatei mit dem Graphen.", completion: .file())
    var file: String?

    @Option(name: .shortAndLong, help: "Startknoten a der ersten Phase.")
    var start: Int = 0

    mutating func run() throws {
        let graph = try loadGraph()
        try validateStart(for: graph)
        try printCut(of: graph)
    }

    // MARK: - Helpers

    /// Loads the graph from `file`, or falls back to the [SW94] example.
    private func loadGraph() throws -> Graph {
        if let file {
            guard let text = Self.readFile(file), let graph = Self.parseGraph(text) else {
                throw ValidationError("Datei '\(file)' nicht lesbar oder ungueltiges Format.")
            }
            return graph
        }
        throw ValidationError("Keine Datei angegeben")
    }

    private func validateStart(for graph: Graph) throws {
        guard (0 ..< graph.vertexCount).contains(start) || graph.vertexCount < 2 else {
            throw ValidationError("Startknoten muss in 0 ..< \(graph.vertexCount) liegen.")
        }
    }

    private func printCut(of graph: Graph) throws {
        do {
            let cut = try graph.minimumCut(start: start)
            let complement = (0 ..< graph.vertexCount).filter { !cut.partition.contains($0) }
            print("Minimaler Schnitt:")
            print("  Gewicht: \(cut.weight)")
            print("  S      : \(cut.partition.sorted())")
            print("  V \\ S  : \(complement)")
        } catch MinimumCutError.tooFewVertices {
            throw ValidationError("Graph braucht mindestens 2 Knoten.")
        }
    }

    private static func readFile(_ path: String) -> String? {
        try? String(contentsOfFile: path, encoding: .utf8)
    }

    private static func parseGraph(_ text: String) -> Graph? {
        var it = text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" }).makeIterator()
        func next<T: LosslessStringConvertible>(_ type: T.Type) -> T? {
            guard let tok = it.next() else { return nil }
            return T(String(tok))
        }
        guard let n = next(Int.self), let m = next(Int.self) else { return nil }
        var graph = Graph(vertexCount: n)
        for _ in 0 ..< m {
            guard let u = next(Int.self), let v = next(Int.self), let w = next(Double.self) else { return nil }
            graph.addEdge(u, v, weight: w)
        }
        return graph
    }
}
