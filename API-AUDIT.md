# API-Audit – AI Notation Studio v0.5.8

Dieser Audit bezieht sich ausschließlich auf den tatsächlich hochgeladenen Quellcode `AI-Notation-Studio.qml`.

## Aktuelle Plugin-Architektur

v0.5.8 verwendet die klassische QML-Plugin-Schnittstelle:

- `import MuseScore 3.0`
- `MuseScore { ... }`
- `menuPath`
- `requiresScore`
- `pluginType: "dialog"`
- `curScore`

Die neuere MuseScore-4.7-Extension-Architektur mit `manifest.json`, `ExtensionBlank` und `MuseApi.*` ist **nicht** Bestandteil von v0.5.8.

## Im aktuellen Code verwendete zentrale MuseScore-Zugriffe

- `curScore.selection`
- `selection.elements`
- `selection.isRange`
- `selection.clear()`
- `selection.selectRange(...)`
- `curScore.newCursor()`
- `curScore.appendPart(...)`
- `curScore.appendMeasures(...)`
- `curScore.startCmd()`
- `curScore.endCmd()`
- Cursor-Zugriffe auf Staff, Voice, Tick, Duration und Note
- `cmd("time-delete")`

## Verifizierte Besonderheit

`selection.selectRange(startTick, endTick, startStaff, endStaff)` behandelt `endStaff` exklusiv.

Daher ist für alle Systeme korrekt:

```qml
selection.selectRange(startTick, endTick, 0, curScore.nstaves)
```

## Noch zu auditieren

Vor weiteren größeren Umbauten müssen die folgenden im v0.5.8-Code verwendeten Stellen vollständig gegen die aktuelle MuseScore-4.7-Dokumentation bzw. den Quellcode geprüft werden:

- `cmd("time-delete")`
- `appendPart(...)` und verwendete Instrument-IDs
- `startCmd()/endCmd()`
- Cursor-Schreiboperationen
- Verhalten beim Löschen überschüssiger Takte
- Verhalten beim Erzeugen von Klavierparts mit zwei Systemen

Bis dieser Audit abgeschlossen ist, werden diese Punkte nicht als vollständig abgesichert bezeichnet.
