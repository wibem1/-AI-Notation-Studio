# Changelog

## 0.6.0 — Release Candidate

- Integrierte GitHub-Updatefunktion ergänzt.
- Zwei Updatekanäle:
  - Stable → `main`
  - Testversion → `develop`
- Remote-QML wird per HTTPS geladen.
- Versionsnummer wird aus der heruntergeladenen QML-Datei gelesen und verglichen.
- Update wird nur angeboten, wenn die Remote-Version neuer ist.
- Vor Installation wird geprüft, ob die Datei plausibel eine AI-Notation-Studio-QML ist.
- Zielpfad wird mit `FileIO.pluginDirectoryPath()` bestimmt.
- Schreiben erfolgt nur, wenn `FileIO.isPathWriteable(...)` dies erlaubt.
- Neue Version wird nach Neustart von MuseScore aktiv.

## 0.5.9 — Stabilisierung

- undefiniertes `userText` behoben
- vorhandene Noten vor destruktivem Taktlöschen geschützt
- `addText("title", ...)` durch `setMetaTag("workTitle", ...)` ersetzt
- `startCmd/endCmd` mit `cmdStarted` abgesichert

## 0.5.8 — Baseline

Erster belastbarer Git-Ausgangspunkt.
