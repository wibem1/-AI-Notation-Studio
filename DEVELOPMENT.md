# Entwicklung

## Ausgangspunkt

Der reale Git-Baseline-Stand ist **v0.5.8**.

Aktuelle Architektur:

- QML-Plugin mit `import MuseScore 3.0`
- Root: `MuseScore { ... }`
- `pluginType: "dialog"`
- Zielanwendung: MuseScore Studio 4.x
- Quellcode: `AI-Notation-Studio.qml`

Ein Umbau auf die neuere Extension-API ist eine mögliche spätere Architekturänderung, aber **nicht** Bestandteil von v0.5.8.

## Branches

- `main`: letzter tatsächlich verwendeter/freigegebener Stand
- `develop`: laufende Entwicklung
- größere Umbauten bei Bedarf in `feature/...`

## Verbindlicher Ablauf

1. Ausgangsfehler oder gewünschte Funktion dokumentieren.
2. MuseScore-API prüfen.
3. Änderung auf `develop`.
4. Versionsnummer nur ändern, wenn der Plugin-Code geändert wurde.
5. `CHANGELOG.md`, `API-AUDIT.md` und `KNOWN-ISSUES.md` aktualisieren.
6. Testplan durchführen.
7. Erst danach nach `main` übernehmen.

## Musikalische Architektur

Für Kompositionsfunktionen gilt das Zwei-Stufen-Prinzip:

1. **Musikalische Komposition** ohne JSON-/Tick-Zwang.
2. **Technische Umsetzung** der fertigen musikalischen Fassung für MuseScore.

Dieses Prinzip hat sich qualitativ bewährt und soll erhalten bleiben.

## Entwicklungsregeln

- Keine Patch-Ketten ohne Ursachenanalyse.
- Keine geratenen MuseScore-API-Aufrufe.
- Keine Behauptung „behoben“, bevor die Änderung praktisch getestet wurde.
- Keine neue Funktion ohne Dokumentation.
- Repository statt lose ZIP-Folge als maßgebliche Entwicklungsbasis.
