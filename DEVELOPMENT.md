# Entwicklung

## Grundsatz

Das GitHub-Repository ist ab jetzt die maßgebliche Quelle. ZIP-Dateien sind nur noch abgeleitete Test- oder Release-Artefakte.

## Branches

- `main`: nur geprüfte und dokumentierte Stände.
- `develop`: laufende Entwicklung.
- größere Änderungen optional in `feature/...`-Branches.

## Release-Ablauf

1. Änderung auf `develop`.
2. Versionsnummer und `CHANGELOG.md` aktualisieren.
3. `API-AUDIT.md`, `KNOWN-ISSUES.md` und `TESTS.md` prüfen.
4. Testcheck vollständig durchführen.
5. Release Candidate festhalten.
6. Erst nach bestandenem Praxistest nach `main` übernehmen und als stabil markieren.

## Architektur

AI Notation Studio verwendet MuseScore Studio 4.7 und API-Version 2.

Musikalische Funktionen folgen grundsätzlich einem Zwei-Stufen-Prinzip:

1. **Musikalische Stufe** — Komposition, Analyse oder Bearbeitung ohne technische Ausgabezwänge.
2. **Technische Stufe** — Umsetzung der fertigen musikalischen Fassung in MuseScore-Daten.

Der Chat ist davon getrennt:

- **Besprechen** verändert die Partitur nie.
- **Ändern** erzeugt zunächst nur einen expliziten Bearbeitungsauftrag.
- Eine Partituränderung erfolgt erst über einen normalen Arbeitsmodus.

## Qualitätsregeln

- Keine neue MuseScore-Funktion ohne API-Prüfung.
- Keine geratenen Action-Codes.
- Keine API-Schlüssel in Diagnose oder Protokoll.
- Keine Versionsnummer ohne dokumentierte Änderung.
- Keine Veröffentlichung als `stable`, bevor `TESTS.md` vollständig bestanden ist.
- Bei einem Fehler zuerst reproduzieren und diagnostizieren, nicht sofort patchen.
