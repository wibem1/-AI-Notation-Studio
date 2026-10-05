# AI Notation Studio

MuseScore-Studio-4.7-Extension für KI-gestützte Analyse, Komposition und Bearbeitung direkt an der Partitur.

## Entwicklungsstatus

**Aktueller Stand: 0.8.0 Release Candidate**

Dieser Stand ist noch nicht als `stable` freigegeben. Vor einer stabilen Freigabe muss der Testplan in `TESTS.md` vollständig durchgeführt werden.

## Funktionen

- Auswahl analysieren
- neue Stimme zu einer Auswahl komponieren
- freie Komposition
- vorhandene Komposition fortsetzen
- aus einem Motiv entwickeln
- eine Variante erzeugen
- für eine andere Besetzung bearbeiten
- partiturbezogener Chat: **Besprechen** / **Ändern**
- MuseScore-eigenes Undo/Redo
- Diagnose und Kommunikationsprotokoll
- Token- und Kostenkontrolle

## Architektur

- MuseScore Studio 4.7.x
- Extension API 2
- `manifest.json`
- `ExtensionBlank`
- `MuseApi.Engraving`
- Zwei-Stufen-Verfahren: **musikalische Fassung → technische MuseScore-Umsetzung**

## Entwicklungsregeln

Das Repository ist ab jetzt die maßgebliche Quelle.

- `main`: geprüfte, dokumentierte Stände
- `develop`: laufende Entwicklung
- keine neue Version ohne Changelog
- keine neue MuseScore-Funktion ohne API-Audit
- keine Stable-Freigabe ohne Testplan
- Fehler zuerst diagnostizieren, nicht durch Patch-Ketten überdecken

Siehe außerdem:

- `CHANGELOG.md`
- `DEVELOPMENT.md`
- `API-AUDIT.md`
- `KNOWN-ISSUES.md`
- `TESTS.md`
