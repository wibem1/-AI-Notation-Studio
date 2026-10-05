# Bekannte Probleme und offene Punkte

Stand: **v0.5.9 RC**

## In v0.5.9 korrigiert

- [x] undefiniertes `userText`
- [x] zweiter Titel durch `addText("title", ...)`
- [x] kein Schutz vor Löschen vorhandener Noten bei freier Komposition
- [x] ungesicherter Rollback ohne expliziten `startCmd`-Status

## Noch praktisch zu testen

- `cmd("time-delete")` in der realen Anwendung
- `cmd("del-empty-measures")`
- Erkennung vorhandener Note-/Chord-Elemente vor Taktlöschung
- `setMetaTag("workTitle", ...)`: Metadatum wird korrekt gesetzt; sichtbarer vorhandener Titel wird dadurch möglicherweise nicht automatisch ersetzt
- `newElement(Element.KEYSIG)`
- `actualKey` / `concertKey`
- `newElement(Element.TEMPO_TEXT)`
- Klavier mit zwei Systemen
- MusicXML-IDs für alle Zielinstrumente

## Entwicklungsorganisation

- `main` bleibt v0.5.8
- `develop` enthält v0.5.9 RC
- Freigabe erst nach bestandenem Test
