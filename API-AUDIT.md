# API-Audit – AI Notation Studio v0.5.8

Stand: vollständiger Audit des tatsächlich hochgeladenen Codes auf Branch `develop`.

Ziel: MuseScore Studio 4.7.x.

## Legende

- **A** = in der öffentlichen Plugin-API dokumentiert und im aktuellen 4.7-Quellcode weiterhin vorhanden
- **B** = im aktuellen MuseScore-4.7-Quellcode/API-v1-Bridge verifiziert, aber nicht als stabiler High-Level-Aufruf der aktuellen 4.7-Extension-Dokumentation beschrieben
- **C** = problematisch, fehleranfällig oder im Plugin konkret falsch verwendet

## Architektur

v0.5.8 verwendet die klassische Plugin-API:

- `import MuseScore 3.0`
- Root `MuseScore { ... }`
- `menuPath`
- `requiresScore`
- `pluginType: "dialog"`
- `curScore`

Diese API ist im aktuellen MuseScore-4.7-Quellcode weiterhin als `src/engraving/api/v1` vorhanden. Die neuere offizielle 4.7-Dokumentation beschreibt dagegen primär die Extension-Architektur mit Manifest und `MuseApi.*`.

**Bewertung: B.** Funktional weiterhin vorhanden, aber nicht die neue bevorzugte 4.7-Architektur.

## A — dokumentierte Score-/Selection-/Cursor-API

Folgende im Plugin verwendete Aufrufe sind dokumentiert und im aktuellen Quellcode vorhanden:

### Score

- `curScore.selection`
- `curScore.parts`
- `curScore.nstaves`
- `curScore.nmeasures`
- `curScore.firstMeasure`
- `curScore.lastMeasure`
- `curScore.newCursor()`
- `curScore.appendPart(instrumentId)`
- `curScore.appendPartByMusicXmlId(musicXmlId)`
- `curScore.appendMeasures(n)`
- `curScore.addText(type, text)`
- `curScore.startCmd()`
- `curScore.endCmd(rollback)`

`startCmd` besitzt in MuseScore 4 zusätzlich optional einen Aktionsnamen; der Aufruf ohne Argument bleibt gültig.

### Selection

- `selection.elements`
- `selection.isRange`
- `selection.clear()`
- `selection.selectRange(startTick, endTick, startStaff, endStaff)`

Für `selectRange` gilt ausdrücklich:

- `startTick` inklusive
- `endTick` exklusiv
- `startStaff` inklusive
- `endStaff` exklusiv

Darum ist für alle Systeme korrekt:

```qml
selection.selectRange(startTick, endTick, 0, curScore.nstaves)
```

Die Korrektur in v0.5.8 ist damit API-konform.

### Cursor

- `cursor.staffIdx`
- `cursor.voice`
- `cursor.rewind(...)`
- `cursor.rewindToTick(tick)`
- `cursor.setDuration(num, den)`
- `cursor.addNote(pitch)`
- `cursor.add(element)`

## A/B — Part-Struktur

Der aktuelle 4.7-Quellcode exponiert:

- `part.startTrack`
- `part.endTrack`
- `part.instrumentId`

Daraus ist die Berechnung

```qml
(part.endTrack - part.startTrack) / 4
```

für die Anzahl der Systeme eines Parts plausibel, weil MuseScore vier Voices pro Staff verwendet.

**Bewertung: A/B.** Die Properties sind im aktuellen API-v1-Quellcode vorhanden; die konkrete Ableitung über Division durch 4 hängt an MuseScores Trackmodell.

## A — Instrument-IDs

Die verwendeten internen IDs sind im aktuellen MuseScore-Bestand verifiziert:

- Violine: `violin`
- Viola: `viola`
- Cello: `violoncello`
- Kontrabass: `contrabass`
- Klavier: `piano`

`appendPart()` erwartet ausdrücklich einen Instrument-Identifier aus `instruments.xml`.

## A/B — MusicXML-Instrumente

`appendPartByMusicXmlId(...)` ist dokumentiert und im aktuellen 4.7-Quellcode vorhanden.

Im Plugin werden verwendet:

- `strings.violin`
- `strings.viola`
- `strings.cello`
- `strings.contrabass`
- `keyboard.piano`

Die Methode selbst ist A. Die konkreten IDs sollten im Praxistest weiterhin kontrolliert werden, weil sie nicht direkt aus dem QML-Code verifiziert werden können.

## B — Elementerzeugung

Das Plugin verwendet:

```qml
newElement(Element.KEYSIG)
newElement(Element.TEMPO_TEXT)
```

`newElement(int)` und die betreffenden Elementtypen sind im aktuellen MuseScore-4.7-API-v1-Quellcode vorhanden.

**Bewertung: B.** Quellcode-verifiziert, aber nicht Teil der neuen 4.7-Extension-High-Level-Dokumentation.

## B — Tonart

Das Plugin setzt bei einem KeySig-Element:

```qml
ks.actualKey = fifths
ks.concertKey = fifths
```

Beide Properties sind seit MuseScore 4.6 im aktuellen API-v1-Quellcode exponiert.

**Bewertung: B.**

## B — Tempo

Das Plugin erzeugt `Element.TEMPO_TEXT`, setzt:

```qml
tempoText.tempo = bpm / 60.0
tempoText.text = "♩ = " + Math.round(bpm)
```

und fügt das Element per Cursor ein.

Die Elementerzeugung ist im aktuellen Quellcode vorhanden. Der interne Tempo-Wert als Viertelnoten pro Sekunde erklärt die Umrechnung `BPM / 60`.

**Bewertung: B.** Praktisch zu testen.

## B — Action-Codes

Das Plugin verwendet:

- `cmd("time-delete")`
- `cmd("del-empty-measures")`

Beide Action-Codes sind im aktuellen MuseScore-4.7-Quellcode registriert:

- `time-delete` → Remove selected range
- `del-empty-measures` → Remove empty trailing measures

**Bewertung: B.** Die Strings sind nicht geraten; sie sind im aktuellen Quellcode verifiziert. Trotzdem sind sie stärker an MuseScores interne Action-Registry gekoppelt als normale API-Methoden.

## C — bestätigter Codefehler

In `makeCompositionPrompt()` steht:

```qml
"AUFTRAG DES NUTZERS:\n" + userText + "\n\n"
```

Im Plugin existiert keine Definition von `userText`.

Korrekt wäre der bereits an anderen Stellen verwendete Inhalt:

```qml
instructionBox.text.trim()
```

**Bewertung: C — echter Fehler.**

## C — Titelbehandlung

Das Plugin verwendet:

```qml
curScore.addText("title", titleText)
```

`addText("title", ...)` ist zwar dokumentiert, fügt aber einen neuen Titeltext hinzu. In einer bereits vorhandenen Partitur kann dadurch ein zweiter Titel entstehen.

**Bewertung: C für unseren Einsatzzweck.**

Für Metadaten wäre `setMetaTag("workTitle", ...)` sicherer; ob damit der bereits sichtbare Titeltext automatisch ersetzt wird, muss separat praktisch geprüft werden.

## C — freie Komposition löscht vorhandenen Taktbereich

`prepareEmptyScoreLength()` wählt den kompletten Taktbereich der geöffneten Partitur aus und führt anschließend `time-delete` aus.

Das ist API-seitig zulässig, aber funktional riskant: Bei einer nicht ausdrücklich als leere Ausgangspartitur verwendeten Datei könnte vorhandenes Material gelöscht werden.

**Bewertung: C als Workflow-Risiko.**

Der Code versucht dies durch die Voraussetzung „genau ein Part“ und durch die Beschreibung „frische Ausgangspartitur“ abzusichern, prüft aber nicht, ob die Partitur tatsächlich leer ist.

## C — Fehlerbehandlung rund um startCmd/endCmd

Die Einfügefunktionen rufen im `catch` vorsorglich `endCmd(true)` auf. Das kann auch dann passieren, wenn der Fehler bereits vor `startCmd()` entstand.

Der zweite `try/catch` verhindert zwar einen Folgeabbruch, aber der Transaktionszustand wird nicht explizit verfolgt.

**Bewertung: C — robustheitsrelevant.**

Empfehlung: lokale Bool-Variable `cmdStarted` verwenden und nur dann rollbacken.

## Ergebnis

### Unproblematisch / dokumentiert
Selection, Cursor, Parts, Append-Funktionen, Measure-Zugriff und Undo-Transaktionen sind grundsätzlich API-konform.

### Quellcode-verifiziert
`newElement`, KeySig-Properties, Tempo-Elemente und die beiden Action-Codes sind im aktuellen MuseScore-4.7-Quellcode vorhanden.

### Vor der nächsten Funktionsentwicklung zu korrigieren

1. undefiniertes `userText`
2. Titelbehandlung über `addText("title", ...)`
3. freie Komposition darf vorhandenes Material nicht unbeabsichtigt löschen
4. Transaktionszustand bei `startCmd/endCmd` sauber verfolgen

Erst danach sollte die nächste Funktionsstufe auf `develop` beginnen.
