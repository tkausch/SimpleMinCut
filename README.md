# Simple Min-Cut Algorithm (Swift)

Swift-Implementierung des **einfachen min-Cut Algorithmus von Stör und Wagner**
([SW94], "A Simple Min-Cut Algorithm") aus Kapitel 2 der Semesterarbeit
*Minimale Schnitte in Graphen* (`mincut11.pdf`).

Der Algorithmus findet einen global minimalen Schnitt `(S, V\S)` eines
ungerichteten Graphen mit positiven Kantengewichten – **ohne** Flussberechnung.

## Idee

`|V| - 1` Phasen. Jede Phase (`MinimumCutPhase`):

1. Starte mit `A = {a}`.
2. Solange `A ≠ V`: füge den Knoten `z ∉ A` mit maximalem `w(A, z)` hinzu.
3. Die zuletzt hinzugefügten Knoten `s` (vorletzter) und `t` (letzter) liefern
   den *Phasenschnitt* `({t}, V\{t})`; merke sein Gewicht.
4. Verschmelze `s` und `t`.

Der leichteste Phasenschnitt über alle Phasen ist der minimale Schnitt
(Korrektheit: Lemma 2.1 der Arbeit).

Laufzeit dieser Variante: `O(|V|³)` (Linearsuche des am stärksten verbundenen
Knotens auf einer Adjazenzmatrix). Mit einer Fibonacci-Halde ließe sich eine
Phase auf `O(|E| + |V| log |V|)` drücken.

## Weiterführende Literatur

Blogartikel zur Semesterarbeit:
[Mincut Thesis Summary](https://kausch.li/mincut-thesis-summary/)

## Verwendung als Library

```swift
import SimpleMinCut

let g = Graph(vertexCount: 4, edges: [
    (0, 1, 3), (1, 2, 1), (2, 3, 3), (3, 0, 1),
])

let cut = try g.minimumCut()
print(cut.weight)      // 2.0
print(cut.partition)   // eine Seite S, z. B. [2, 3]
```

## CLI

```
swift run simple-mincut <datei> [--start n]
```

Eingabeformat (Whitespace-getrennt): `|V|`, dann `|E|`, dann `|E|` Tripel
`u v gewicht` (Knoten sind `0 ..< |V|`). Die Datei ist ein Pflichtargument;
das Standardbeispiel aus [SW94] liegt unter `examples/stoer-wagner.txt`.

```
$ swift run simple-mincut examples/stoer-wagner.txt
Minimaler Schnitt:
  Gewicht: 4.0
  S      : [2, 3, 6, 7]
  V \ S  : [0, 1, 4, 5]
```

## Tests

```
swift test
```

Enthält u. a. einen Brute-Force-Vergleich (`O(2^|V|)`) über 200 Zufallsgraphen.
