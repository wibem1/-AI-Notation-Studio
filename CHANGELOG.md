# Changelog

Alle relevanten Änderungen von AI Notation Studio werden ab jetzt hier fortlaufend dokumentiert.

## 0.8.0 — Release Candidate

- Partiturbezogener Chat ergänzt.
- Chat-Modi **Besprechen** und **Ändern**.
- Markierte Passage wird dem Chat als musikalischer Kontext mitgegeben.
- Im Modus **Ändern** wird nur ein Bearbeitungsauftrag erzeugt; keine automatische Partituränderung.
- Chatverlauf wird lokal gespeichert; für den API-Kontext werden standardmäßig die letzten 12 Nachrichten verwendet.
- Chat-Aufrufe fließen in Diagnose, Kommunikationsprotokoll und Tokenkontrolle ein.

Status: **Release Candidate / noch nicht als stabil freigegeben**.

## 0.7.1

- Vollständiger A/B/C-Audit der verwendeten MuseScore-Schnittstellen.
- Variantenmodus vereinfacht: genau eine Variante pro Lauf.
- Keine bekannte Verwendung einer API der Klasse C.

## 0.7.0

- Neue Modi: Fortsetzen, Aus Motiv entwickeln, Varianten, andere Besetzung.
- Kontextuelle Zwei-Stufen-Verarbeitung eingeführt.
- Token-Erfassung pro Provider verbessert.

## 0.6.2

- MuseScore-eigenes Rückgängig/Wiederholen ergänzt.
- Keine separate Undo-Historie im Plugin.

## 0.6.1

- Kommunikationsprotokoll ergänzt.
- Laufdiagnose ergänzt.
- Token- und Kostenkontrolle ergänzt.
- Unbekannte Modellpreise werden nicht geschätzt.

## 0.6.0

- Neuaufbau als MuseScore-4.7-Extension.
- `manifest.json`, `apiversion: 2`, `ExtensionBlank`, `MuseApi.Engraving`.
- Legacy-Root `MuseScore { pluginType: "dialog" }` entfernt.
- Titelbehandlung und Taktvorbereitung überarbeitet.
- API-Check ergänzt.

## Vor 0.6.0

Vor-Git-Entwicklungsstände wurden als Chat-Artefakte erzeugt und sind nicht als stabile Releases zu behandeln.
