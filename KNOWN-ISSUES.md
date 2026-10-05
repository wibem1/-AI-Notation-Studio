# Bekannte Probleme und Grenzen

Stand: 0.8.0 RC

## Noch praktisch zu verifizieren

- Installation und Start der neuen 4.7-Extension auf dem Zielsystem.
- Taktkürzung über `time-delete` in der aktuellen MuseScore-Version.
- Undo/Redo über die verifizierten MuseScore-Action-Codes.
- Einfügen mehrerer Parts und Klavier mit zwei Systemen.
- Titel-/Metadatenverhalten in realen Partituren.
- Chat-Persistenz über Neustart von MuseScore hinweg.
- Tokenfelder der aktuell verwendeten Provider/Modelle.

## Bewusste Grenzen

- Kosten werden nur berechnet, wenn ein verifizierter Modellpreis hinterlegt ist.
- Der Chat schreibt nie automatisch in die Partitur.
- Der Variantenmodus erzeugt genau eine Variante pro Lauf.
- Neue Partituren werden nicht über `newScore()` automatisch geöffnet, da dies in der MuseScore-API nicht vollständig implementiert ist.

## API-Klasse B

Besonders sorgfältig zu testen:

- `api.engraving.newElement(...)`
- `api.engraving.cmd("time-delete")`
- `api.engraving.cmd("action://notation/undo")`
- `api.engraving.cmd("action://notation/redo")`
