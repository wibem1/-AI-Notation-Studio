# Bekannte Probleme und offene Punkte

Stand: **v0.6.0 RC**

## Updatefunktion — noch praktisch zu testen

- `FileIO.pluginDirectoryPath()` liefert auf dem Zielsystem den tatsächlichen Plugin-Ordner.
- `FileIO.isPathWriteable(...)` erlaubt das Überschreiben der eigenen QML-Datei.
- QML-Datei kann während laufendem Plugin ersetzt werden.
- Nach MuseScore-Neustart wird die neue Version tatsächlich geladen.
- Stable/Testversion-Umschaltung bleibt nach Neustart erhalten.

## Sonstige praktische Tests

- `time-delete`
- `del-empty-measures`
- KeySig/Tempo
- Klavier mit zwei Systemen
- MusicXML-Instrumente
- `workTitle`-Verhalten

## Sicherheitsprinzip

Der Updater schreibt ausschließlich die Datei `AI-Notation-Studio.qml` im von MuseScore gemeldeten Plugin-Ordner. Andere Dateien werden nicht verändert.
