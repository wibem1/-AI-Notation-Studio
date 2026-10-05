# AI Notation Studio v0.6.0 RC

Aktueller Entwicklungsstand auf `develop`.

## Status

- `main`: v0.5.8 Baseline
- `develop`: v0.6.0 RC

v0.6.0 baut auf den Stabilitätskorrekturen aus v0.5.9 auf und ergänzt eine integrierte GitHub-Updatefunktion.

## Updatefunktion

Das Plugin kann jetzt selbst nach neuen Versionen suchen und seine eigene QML-Datei aktualisieren.

Kanäle:

- **Stable** → `main`
- **Testversion** → `develop`

Ablauf:

1. `Update prüfen`
2. bei neuer Version `Update installieren`
3. MuseScore neu starten

Die Updatequelle wird vor dem Schreiben grob validiert. Geschrieben wird ausschließlich in den Plugin-Ordner, den MuseScore selbst über `FileIO.pluginDirectoryPath()` liefert.

## Korrekturen aus v0.5.9

- undefiniertes `userText` behoben
- vorhandene Noten vor vollständigem Taktlöschen geschützt
- Titel als `workTitle` statt als zusätzlicher Titeltext
- `startCmd()/endCmd()` mit Transaktionsstatus abgesichert

## Unverändert

- klassische MuseScore-QML-Plugin-Architektur
- Zwei-Stufen-Verfahren
- OpenAI, Anthropic, Google
- Auswahl lesen, analysieren, neue Stimme, freie Komposition
