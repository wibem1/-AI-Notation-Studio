# Bekannte Probleme und offene Punkte

Stand: **v0.6.0 RC**

## Updatefunktion — noch praktisch zu testen

- `FileIO.pluginDirectoryPath()` liefert auf dem Zielsystem den tatsächlichen Plugin-Ordner.
- `FileIO.isPathWriteable(...)` erlaubt das Überschreiben der eigenen QML-Datei.
- Nach MuseScore-Neustart wird die neue Version geladen.

## Wichtig

Es gibt **nur einen Updateweg über `main`**. Keine parallelen Stable-/Testkanäle.

## Sonstige praktische Tests

- `time-delete`
- `del-empty-measures`
- KeySig/Tempo
- Klavier mit zwei Systemen
- MusicXML-Instrumente
- `workTitle`-Verhalten
