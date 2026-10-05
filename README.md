# AI Notation Studio v0.6.0 RC

Aktueller Entwicklungsstand auf `develop`.

## Status

- `main`: letzter freigegebener Stand
- `develop`: laufende Entwicklung

v0.6.0 ergänzt eine integrierte GitHub-Updatefunktion und verwendet **nur einen Updateweg**.

## Updatefunktion

Das Plugin prüft ausschließlich die aktuelle Version auf:

- `main`

Ablauf:

1. `Update prüfen`
2. bei neuer Version `Update installieren`
3. MuseScore neu starten

Es gibt keine Auswahl zwischen Stable/Testversion und keine parallelen Updatekanäle.

## Korrekturen aus v0.5.9

- undefiniertes `userText` behoben
- vorhandene Noten vor vollständigem Taktlöschen geschützt
- Titel als `workTitle` statt als zusätzlicher Titeltext
- `startCmd()/endCmd()` mit Transaktionsstatus abgesichert
