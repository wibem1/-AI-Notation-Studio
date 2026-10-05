# API-Audit – AI Notation Studio 0.8.0 RC

Zielplattform: MuseScore Studio 4.7.x  
Extension-API: `apiversion: 2`

## Einstufung

- **A** = öffentlich dokumentierte MuseScore-API / offizielle 4.7-Extension-Struktur
- **B** = in der offiziellen API2-Brücke bzw. im aktuellen MuseScore-4.7-Quellcode verifiziert
- **C** = intern, ungeeignet oder nicht verifiziert; soll nicht verwendet werden

## A

### Extension

- `manifest.json`
- `"type": "form"`
- `"apiversion": 2`
- `ExtensionBlank`
- `MuseApi.Engraving`
- `MuseApi.Interactive`
- `MuseApi.Controls`

### Score / Partitur

- `api.engraving.curScore`
- `score.parts`
- `score.nmeasures`
- `score.nstaves`
- `score.firstMeasure`
- `score.lastMeasure`
- `score.newCursor()`
- `score.appendMeasures(n)`
- `score.appendPart(instrumentId)`
- `score.appendPartByMusicXmlId(id)`
- `score.startCmd(...)`
- `score.endCmd(rollback)`
- `score.metaTag(...)`
- `score.setMetaTag(...)`

### Selection

- `selection.elements`
- `selection.isRange`
- `selection.startSegment`
- `selection.endSegment`
- `selection.startStaff`
- `selection.endStaff`
- `selection.clear()`
- `selection.selectRange(...)`

`endTick` und `endStaff` sind exklusiv.

### Cursor

- `cursor.staffIdx`
- `cursor.voice`
- `cursor.rewind(...)`
- `cursor.rewindToTick(tick)`
- `cursor.setDuration(num, den)`
- `cursor.addNote(pitch)`
- `cursor.add(element)`

### Parts

- `part.startTrack`
- `part.endTrack`
- `part.instrumentId`

## B

Bewusst isoliert:

- `api.engraving.newElement(...)`
- `api.engraving.cmd(...)`
- `api.engraving.mscoreMajorVersion`
- `api.engraving.mscoreMinorVersion`
- `api.engraving.mscoreUpdateVersion`

Verifizierte Action-Codes:

- `time-delete`
- `action://notation/undo`
- `action://notation/redo`

## C

In der aktuellen Architektur bewusst nicht vorgesehen:

- automatisches Öffnen mit `newScore()`
- `pluginType: "dialog"`
- Legacy-Root `MuseScore { ... }`
- `menuPath` / `requiresScore`
- `addText("title", ...)` zum Ersetzen eines Titels
- unbekannte oder geratene Action-Codes
- separate Schatten-Undo-Historie

## Chat

Der Chat führt keine neue MuseScore-Schreib-API ein. Er liest nur die bereits auditierten Score- und Selection-Daten. Im Modus **Ändern** wird zunächst ausschließlich ein Textauftrag erzeugt.
