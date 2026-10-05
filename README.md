# AI Notation Studio v0.5.9 RC

Aktueller Entwicklungsstand auf `develop`.

## Status

**v0.5.8 bleibt der stabile Git-Baseline-Stand auf `main`.**

**v0.5.9 ist ein Release Candidate auf `develop`** und enthält ausschließlich Stabilitätskorrekturen aus dem vollständigen MuseScore-4.7-API-Audit.

## Korrekturen in v0.5.9

- undefiniertes `userText` durch `instructionBox.text.trim()` ersetzt
- vorhandene Noten werden vor dem vollständigen Taktlöschen erkannt; freie Komposition bricht dann ab
- Titel wird nicht mehr per `addText("title", ...)` als zweiter Titel eingefügt, sondern als `workTitle`-Metadatum gesetzt
- `startCmd()/endCmd()` wird jetzt mit `cmdStarted` abgesichert; Rollback nur bei tatsächlich gestarteter Transaktion

## Unverändert

- klassische MuseScore-QML-Plugin-Architektur
- Zwei-Stufen-Verfahren: musikalische Komposition → technische Umsetzung
- OpenAI, Anthropic, Google
- Auswahl lesen, analysieren, neue Stimme, freie Komposition
- Instrument- und Taktlogik aus v0.5.8

## Entwicklungsorganisation

- `main`: v0.5.8
- `develop`: v0.5.9 RC
- erst nach bestandenem Testplan wird v0.5.9 nach `main` übernommen
