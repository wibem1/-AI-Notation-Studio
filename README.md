# AI Notation Studio v0.5.8

## Konkrete Ursache der bisherigen Taktlösch-Fehler

Die MuseScore-API dokumentiert und implementiert:

```cpp
selectRange(int startTick, int endTick, int startStaff, int endStaff)
```

Dabei gilt:

- `startTick`: inklusive
- `endTick`: exklusive
- `startStaff`: inklusive
- `endStaff`: **exklusive**

MuseScore prüft intern:

```cpp
if (startStaff >= endStaff) {
    return false;
}
```

Unsere bisherigen Versionen verwendeten:

```qml
score.selection.selectRange(startTick, endTick, 0, score.nstaves - 1)
```

Bei einer Ausgangspartitur mit genau einem System (`nstaves == 1`) wurde daraus:

```qml
selectRange(..., 0, 0)
```

Diese Auswahl ist laut MuseScore-API ungültig und wurde daher immer mit
`false` abgewiesen. Damit hatte `time-delete` nie einen gültigen Bereich.

## Korrektur in v0.5.8

Jetzt wird korrekt verwendet:

```qml
score.selection.selectRange(startTick, endTick, 0, score.nstaves)
```

Bei einem System also:

```qml
selectRange(..., 0, 1)
```

Damit umfasst die Auswahl tatsächlich das vollständige erste System.

Der gleiche Fehler wurde auch in der zusätzlichen Kürzungsroutine korrigiert.

Sonst wurde an diesem Teil nichts geändert.
