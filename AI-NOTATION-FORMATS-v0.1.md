# AI Notation Mini/Maxi v0.1

Status: **Entwurfs- und Vergleichsformat. Noch nicht in der App aktiv.**

## Ziel

Die beiden Formate testen, ob ein reiches, an MuseScore orientiertes Partiturformat die musikalische Qualität einer KI-Komposition verbessert, verschlechtert oder unverändert lässt.

Grundsatz:

> In die Formate kommt nur, was MuseScore 4.6.x als echtes Notationselement oder als darstellbaren musikalischen Text umsetzen kann.

Die Formate sind **keine MSCX-Kopie** und **keine MNX-Implementierung**. MSCX liefert die Nähe zu den realen MuseScore-Objekten; MNX liefert Anregungen für eine klare musikalische JSON-Semantik.

## Mini v0.1

Mini hält die technische Last klein. Enthalten sind:
- Partitur, Instrumente, Takte, bis zu vier Stimmen
- Noten, Akkorde, Pausen
- Tonart, Taktart, Tempo
- Punktierung und Haltebogen
- einfache Dynamik
- staccato, staccatissimo, tenuto, accent, marcato
- einfacher Legatobogen
- Ausdruckstext und Spielanweisung als Text

Mini soll möglichst wenig vom eigentlichen Komponieren ablenken.

## Maxi v0.1

Maxi erweitert denselben Kern um zusätzliche Ausdrucksmöglichkeiten, die MuseScore 4.6.x nativ kennt:
- volle Standard-Dynamikpalette
- Hairpins und Crescendo/Diminuendo-Linien
- Slurs mit Linienart
- Fermaten
- Atemzeichen
- Ausdruckstext
- Spieltechnik-Annotationen
- Ornamente
- Arpeggien
- Tremolo
- Tuplets
- Ottava
- Pedal
- Glissando/Portamento
- Trillerlinien
- Tempowechsel

## Bewusst nicht enthalten

Nicht aufgenommen werden vorerst:
- MIDI-CC, Velocity-Automation, Pitch-Bend-Automation
- MuseScore-interne EIDs oder MSCX-IDs
- absolute Roh-Ticks
- Layoutkoordinaten
- VST- oder SWAM-spezifische Parameter
- erfundene musikalische Semantik ohne MuseScore-Zielobjekt

## MuseScore-4.6.x-Abbildung

Die MuseScore-4.6-Plugin-API enthält unter anderem diese Elementtypen:
`ARPEGGIO`, `BREATH`, `TIE`, `ARTICULATION`, `ORNAMENT`, `FERMATA`, `DYNAMIC`, `EXPRESSION`, `TEMPO_TEXT`, `STAFF_TEXT`, `PLAYTECH_ANNOTATION`, `TUPLET`, `HAIRPIN`, `OTTAVA`, `PEDAL`, `TRILL`, `GLISSANDO`, `SLUR`, `TREMOLO_SINGLECHORD` und `TREMOLO_TWOCHORD`.

Für Dynamik, Fermaten, Hairpins, Ottava, Triller, Tremolo, Glissando und Arpeggio stellt die API passende Typ-Enums bereit.

Wichtig: Dass ein Elementtyp in der API vorhanden ist, beweist die grundsätzliche Abbildbarkeit. Die konkrete Erzeugung und Parametrisierung durch unser QML-Plugin wird für die Umsetzung einzeln getestet.

## Vergleichstest

Beide Varianten bekommen:
- denselben Kompositionsauftrag
- dasselbe KI-Modell
- dieselben musikalischen Randbedingungen

Bewertet werden vor allem:
- musikalische Gestalt und Form
- Melodik
- Rhythmus
- Harmonik
- Phrasierung
- Dynamik
- Artikulation
- Ausdruck und Lebendigkeit

Maxi ist ein Möglichkeitsraum, keine Checkliste. Die KI soll nur Ausdrucksmittel verwenden, die musikalisch sinnvoll sind.
