# Bekannte Probleme und offene Punkte

Stand: **v0.5.8**, vollständiger API-Audit durchgeführt.

## Bestätigte Codefehler / Risiken

### 1. Undefiniertes `userText`

In `makeCompositionPrompt()` wird `userText` verwendet, obwohl diese Variable nicht definiert ist.

Folge: **Neue Stimme zu Auswahl** kann bereits beim Erzeugen des Prompts abbrechen.

### 2. Titel wird hinzugefügt statt ersetzt

`curScore.addText("title", titleText)` ist eine gültige API-Funktion, fügt aber einen neuen Titel hinzu. Bei vorhandener Titelseite kann dadurch ein zweiter Titel entstehen.

### 3. Freie Komposition kann vorhandene Takte löschen

`prepareEmptyScoreLength()` verwendet eine vollständige Bereichsauswahl plus `time-delete`. Das ist nur sicher, wenn die Ausgangspartitur tatsächlich leer ist. Der aktuelle Code prüft nur die Partanzahl, nicht den musikalischen Inhalt.

### 4. startCmd/endCmd-Rollback nicht explizit abgesichert

Im Fehlerfall wird `endCmd(true)` aufgerufen, ohne zu speichern, ob `startCmd()` tatsächlich erreicht wurde.

## API-seitig verifiziert, aber praktisch zu testen

- `cmd("time-delete")`
- `cmd("del-empty-measures")`
- `newElement(Element.KEYSIG)`
- `actualKey` / `concertKey`
- `newElement(Element.TEMPO_TEXT)`
- Klavier mit zwei Systemen
- MusicXML-IDs für alle Zielinstrumente

## Entwicklungsorganisation

v0.5.8 bleibt unangetasteter Baseline-Stand auf `main`.

Korrekturen erfolgen ausschließlich auf `develop`. Erst nach bestandenem Test wird eine neue Version freigegeben.
