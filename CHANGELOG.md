# Changelog

## 0.6.0 — Release Candidate

- Integrierte GitHub-Updatefunktion ergänzt.
- Es gibt genau einen Updatekanal: `main`.
- Keine Stable/Testversion-Auswahl.
- Remote-QML wird per HTTPS geladen.
- Versionsnummer wird aus der heruntergeladenen QML-Datei gelesen und verglichen.
- Update wird nur angeboten, wenn die Remote-Version neuer ist.
- Zielpfad wird mit `FileIO.pluginDirectoryPath()` bestimmt.
- Neue Version wird nach Neustart von MuseScore aktiv.

## 0.5.9 — Stabilisierung

- undefiniertes `userText` behoben
- vorhandene Noten vor destruktivem Taktlöschen geschützt
- `addText("title", ...)` durch `setMetaTag("workTitle", ...)` ersetzt
- `startCmd/endCmd` mit `cmdStarted` abgesichert

## 0.5.8 — Baseline

Erster belastbarer Git-Ausgangspunkt.
