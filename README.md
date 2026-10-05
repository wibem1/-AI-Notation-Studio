# AI Notation Studio v0.5.8

Aktueller, tatsächlich hochgeladener Ausgangsstand für die weitere Entwicklung.

## Status

**v0.5.8 ist der Git-Baseline-Stand.**

Maßgeblicher Quellcode:

- `AI-Notation-Studio.qml`

Die ZIP-Datei bleibt nur als Archiv erhalten. Für die weitere Entwicklung ist der entpackte QML-Quellcode maßgeblich.

## Aktuelle Funktionen

- Auswahl in MuseScore lesen
- Auswahl musikalisch analysieren
- neue Stimme zu einer vorhandenen Auswahl komponieren
- freie Komposition ohne Vorlage
- Zwei-Stufen-Verfahren: musikalische Komposition → technische Umsetzung
- OpenAI, Anthropic und Google
- lokale Speicherung von Provider, Modell und API-Key
- Einfügen erzeugter Musik in MuseScore

## Wichtige Korrektur in v0.5.8

MuseScore verwendet bei

```qml
selection.selectRange(startTick, endTick, startStaff, endStaff)
```

ein exklusives `endStaff`.

Daher ist für die gesamte Partitur korrekt:

```qml
curScore.selection.selectRange(startTick, endTick, 0, curScore.nstaves)
```

und nicht `curScore.nstaves - 1`.

## Entwicklungsorganisation ab jetzt

- `main`: letzter tatsächlich verwendeter bzw. freigegebener Stand
- `develop`: laufende Entwicklung
- jede Änderung wird im `CHANGELOG.md` dokumentiert
- bekannte Probleme stehen in `KNOWN-ISSUES.md`
- MuseScore-API-Nutzung wird in `API-AUDIT.md` geprüft
- vor einer neuen stabilen Version gilt der Testplan in `TESTS.md`

Die zuvor versehentlich verwendete Bezeichnung 0.8.0 gehört nicht zur realen Versionsgeschichte und wird nicht weitergeführt.
