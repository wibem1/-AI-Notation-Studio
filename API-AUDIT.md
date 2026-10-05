# API-Audit – AI Notation Studio v0.7.0

Ziel: MuseScore Studio 4.7.x.

## Grundarchitektur

Das Plugin verwendet weiterhin die klassische QML-Plugin-API:

- `import MuseScore 3.0`
- `MuseScore { ... }`
- `curScore`
- `FileIO 3.0`

Diese API ist im aktuellen MuseScore-4.7-Quellcode unter `src/engraving/api/v1` weiterhin vorhanden.

## Verwendete Score-/Selection-/Cursor-API

Quellcode- bzw. API-verifiziert:

- `curScore.selection`
- `selection.elements`
- `selection.isRange`
- `selection.clear()`
- `selection.selectRange(...)`
- `curScore.parts`
- `curScore.nstaves`
- `curScore.nmeasures`
- `curScore.firstMeasure`
- `curScore.lastMeasure`
- `curScore.newCursor()`
- `curScore.appendMeasures(...)`
- `curScore.appendPart(...)`
- `curScore.appendPartByMusicXmlId(...)`
- `curScore.startCmd(...)`
- `curScore.endCmd(rollback)`
- `curScore.setMetaTag(...)`
- `cursor.staffIdx`
- `cursor.voice`
- `cursor.rewind(...)`
- `cursor.rewindToTick(...)`
- `cursor.setDuration(...)`
- `cursor.addNote(...)`
- `cursor.add(...)`

`selectRange` verwendet exklusives `endStaff`; deshalb bleibt `0 .. curScore.nstaves` korrekt.

## Elementerzeugung

Im aktuellen MuseScore-4.7-API-v1-Quellcode verifiziert:

- `newElement(Element.KEYSIG)`
- `actualKey`
- `concertKey`
- `newElement(Element.TEMPO_TEXT)`

## MuseScore-Actions

Im aktuellen 4.7-Quellcode registriert und daher nicht geraten:

- `time-delete`
- `del-empty-measures`
- `action://notation/undo`
- `action://notation/redo`

Undo/Redo verwendet ausschließlich MuseScores eigene Historie.

## Parts und Instrumente

`Part.startTrack`, `Part.endTrack` und `Part.instrumentId` sind im API-v1-Quellcode vorhanden.

Verifizierte interne Instrument-IDs:

- `violin`
- `viola`
- `violoncello`
- `contrabass`
- `piano`
- `flute`
- `oboe`
- `bb-clarinet`
- `bassoon`
- `horn`
- `bb-trumpet`
- `trombone`
- `tuba`

## Updater

`FileIO` stellt ausdrücklich bereit:

- `pluginDirectoryPath()`
- `isPathWriteable(path)`
- `write(data)`

Damit wird kein fest codierter macOS-Pfad verwendet.

## Neue Funktionen v0.7.0

### Fortsetzen

Verwendet nur:
- gelesene Selection-Daten
- vorhandene `score.parts`
- Cursor-Schreiboperationen
- `appendMeasures`, falls zusätzlicher Platz nötig ist

Zur Sicherheit wird nur fortgesetzt, wenn die Auswahl am Partiturende endet.

### Motiv / Variante / andere Besetzung

Neue Zielparts werden ausschließlich über `appendPart(instrumentId)` angelegt. Noten werden über Cursor eingefügt.

### Partitur-Chat

Der Chat verwendet keine neue MuseScore-Schreib-API. Er liest nur:
- Partiturstruktur
- markierte Elemente

Im Modus **Ändern** erzeugt der Chat nur einen Textauftrag.

### Diagnose / Protokoll / Token

Keine zusätzlichen MuseScore-Schreibzugriffe.

## Noch praktisch zu verifizieren

- Verhalten der neuen Modi in realen mehrstimmigen Partituren
- Klavierparts mit zwei Systemen
- Fortsetzen bei Taktartwechseln
- sichtbares Titelverhalten von `workTitle`
- alle neu hinzugefügten Instrument-IDs im Zielsystem

## v0.7.2 – leere Endtakte

Die frühere Strategie mit künstlicher Bereichsauswahl plus `time-delete` wurde für die freie Komposition entfernt. Verwendet wird jetzt ausschließlich die in MuseScore 4.7 registrierte Aktion `del-empty-measures` / `REMOVE_EMPTY_TRAILING_MEASURES_COMMAND`, und zwar erst nach dem Einfügen der Musik. Das entspricht direkt der vorgesehenen MuseScore-Funktion „Remove empty trailing measures“.

## v0.7.6 – Gedächtnis

Für das Score-Gedächtnis werden ausschließlich die dokumentierten MuseScore-API-v1-Methoden `Score.metaTag(tag)` und `Score.setMetaTag(tag, value)` verwendet. Diese sind im aktuellen MuseScore-4.7-Quellcode als Q_INVOKABLE exponiert. Metadaten werden beim Speichern des Scores mitgeschrieben. Das generelle Gedächtnis verwendet weiterhin QML `Settings` und ist damit score-unabhängig.
