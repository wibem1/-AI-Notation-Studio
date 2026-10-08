# Changelog

## 0.10.10 – 08.10.2026

- Editierbare Modellauswahl für Direkt/Stufe 1 und Stufe 2.
- Modelllisten aus den drei Anbieter-APIs; Pagination, Textmodellfilter, lokal gespeicherter Katalog und Erhalt der Auswahl bei Fehlern.
- Bestehende Keys, eigene Modellnamen und dauerhafter Updateweg bleiben erhalten.

## 0.10.9 – 08.10.2026 / Starter 0.7.17

- Dauerhafte Startauswahl als geprüfte lokale Active.json-Datei. Starter und App lesen sie frisch vom Datenträger statt getrennte Settings-Kopien für die aktive Version zu verwenden.
- Auswahl wird nach erfolgreicher App-Initialisierung geschrieben und nachgelesen. Bei ungültigen/fehlenden Dateien wird das Bundle geladen.
- Vollständiger Test: Live-Installation, Plugin schließen/erneut öffnen mit demselben Engine-Cache, zusätzlicher frischer Prozess.

## 0.10.8 – 08.10.2026

- Scrollbereich an die tatsächliche native Fensterhöhe gebunden, auch wenn MuseScores eingebetteter Elternbereich größer bleibt.
- Fehler mit unverändertem Analysemodus nachgestellt: 900 hoher Elternbereich, 500 hohes Fenster, 864 hoher Flickable und 850 hoher Inhalt; dadurch war Scrollen unnötig aus Sicht des Flickable, obwohl der Inhalt abgeschnitten war. Neue tatsächliche Scrollhöhe ist 464.
- Starter unverändert; Installation über eingebautes Live-Update.

## 0.10.7 – 08.10.2026 / Starter 0.7.16

- Fensterhöhe und -breite anhand des verfügbaren Bildschirms begrenzt; Pluginobjekte folgen der Größe ihres Elternfensters. Dadurch bleibt die Scrollleiste auch bei Windows-Skalierung innerhalb des Fensters.
- Qt-5-Bedienungstest um Mausrad und Scrollleisteninteraktion ergänzt.

## 0.10.6 – 08.10.2026 / Starter 0.7.15

- Starter lädt die mitgelieferte App über den eindeutigen Dateinamen AI-Notation-Studio-App-0.10.6.qml. Ältere Cache-URLs werden übergangen.
- Eingebaute Updateprüfung aus 0.10.5 beibehalten.

## 0.10.5 – 08.10.2026

- Updateprüfung repariert: fehlende lokale finished-Variable verhindert nicht mehr die Verarbeitung der HTTP-Antwort. Starter unverändert.
- Updateprüfung, Versionsvergleich und Schreiben/Prüfen/Aktivieren einer versionierten App werden gezielt mit deterministischen HTTP-/FileIO-Antworten getestet.

## 0.10.4 – 08.10.2026 / Starter 0.7.14

- Hauptbereich als explizit interaktiven Flickable mit dauerhaft sichtbarer vertikaler Scrollleiste umgesetzt. Inhaltsbreite reserviert Platz für die Scrollleiste.

## 0.10.3 – 08.10.2026 / Starter 0.7.13

- Unterschiedliche Namen im Pluginmanager: AI Notation Studio und AI Notation Studio – interne App (nicht starten). Nur den Starter aktivieren.

## 0.10.2 – 08.10.2026 / Starter 0.7.12

- Minimaler Starter ohne Controls-/Labs-Import; sichtbare QML-Fehler mit Dateipfad statt unsichtbarer Konsolenausgabe.
- MuseScores nativen Settings-Typ ausdrücklich verwendet; vorhandene Kategorie und Keys beibehalten.
- Testobjekt um den tatsächlich von MuseScore exportierten Settings-Typ ergänzt. Die bisherige Aussage über einen fehlenden Host-Import wird damit korrigiert.
- Explizite implizite Fenstergrößen; App und Starter weiterhin ein gemeinsames Plugin.

## 0.10.1 – 08.10.2026 / Host 0.7.11

- Qt.labs.settings-Import im Host ergänzt. **Korrektur in 0.10.2:** Der angenommene fehlende Settings-Typ entstand nur durch ein unvollständiges Testobjekt.
- Windows-Laufwerksbuchstaben, Leerzeichen, Unicode, UNC und lokale File-URLs korrekt behandelt; Updater schreibt lokale Pfade.
- Loader zeigt die App erst nach erfolgreichem Start, aktiviert keine alte Quelle vor dem neuen Ziel und stellt bei Fehlern eine bedienbare Oberfläche wieder her.
- Mitgelieferte App wird beim Hoststart erkannt; ältere App-Versionen werden nicht über die aktuelle App geladen.
- Host-/App-Integration zusätzlich zu den bisherigen Standalone-Tests geprüft.


## 0.10.0 – 06.10.2026

- Drei gespeicherte Arbeitsweisen für alle Kompositionsmodi: direkt, editierbare Idee mit bewusster Freigabe, vollständige Musik mit automatischer CS1-Übertragung.
- Getrennte Anbieter und Modelle je Stufe; vorhandene Keys werden weiterverwendet und vor dem Auftrag geprüft.
- Kosten pro Stufe, Auftragssumme und vollständige Stufendaten in der Diagnose.
- Alle sechs Modi verwenden CS1, einschließlich Dynamik, Artikulationen, Bögen und Pedal.
- Kontextaufträge sichern das Original und öffnen über MusicXML eine kombinierte Kopie. Auswahlposition, Taktartwechsel, Auftakte, Klaviersysteme und Instrumententransposition werden lokal berücksichtigt.
- Idee und musikalische Erstfassung bleiben bei Fehlern der zweiten Stufe erhalten; Formatübertragung kann wiederholt werden.
- Oberfläche scrollbar, damit Idee, Ergebnis und Modellfelder in kleineren Fenstern erreichbar bleiben.


## 0.9.0 – CompactScore CS1

- Freie Komposition direkt in CS1 statt zweier KI-Aufrufe.
- Import von CS1 und Mini/Maxi-JSON; neue MuseScore-Partitur über MusicXML.
- Ausdruckszeichen, Mehrstimmigkeit und Tuplets als native Notation.
- Original-CS1 als separate Datei und Score-Metadatum.
- Kosten pro Aufruf und Sitzung, Cache-Nutzung und Thinking-Token-Anzeige in der Diagnose.
- Alle Textblöcke der drei Anbieter werden gelesen; abgeschnittene Antworten bleiben zur Diagnose erhalten und werden nicht importiert.
- Live-App 0.9.0 als selbstständige QML; Host und andere Bearbeitungsmodi bleiben erhalten.


## 0.7.0

Neue Funktionen:

- **Fortsetzen**: setzt eine Auswahl am Partiturende in den vorhandenen Parts fort.
- **Aus Motiv entwickeln**: entwickelt eine markierte Passage zu einer neuen musikalischen Fassung.
- **Variante erzeugen**: erzeugt pro Lauf genau eine Variante.
- **Für andere Besetzung bearbeiten**: erzeugt eine idiomatische Neuinstrumentierung der Auswahl.
- **Partitur-Chat**:
  - Besprechen: keine Partituränderung
  - Ändern: erzeugt einen konkreten Bearbeitungsauftrag, schreibt aber nicht automatisch
- **Rückgängig/Wiederholen** über MuseScores eigene Undo-Historie.
- **Kommunikationsprotokoll** mit Nutzer-, App-, KI-, API- und MuseScore-Ereignissen.
- **Diagnose** mit Pluginversion, Modell, Modus, Partiturstruktur, Auswahl und technischen Daten.
- **Tokenkontrolle** für OpenAI, Anthropic und Google.
- Zielbesetzungen erweitert um Flöte, Oboe, Klarinette, Fagott, Horn, Trompete, Posaune und Tuba.

Bestehende Prinzipien:

- Zwei-Stufen-Verfahren bleibt erhalten.
- Keine Vorentwürfe.
- Update weiterhin ausschließlich über `main`.

## 0.6.0

- integrierte GitHub-Updatefunktion
- ein einziger Updatekanal über `main`

## 0.5.9

- `userText`-Fehler behoben
- Schutz vor versehentlichem Löschen vorhandener Noten
- Titel als `workTitle`
- Transaktions-Rollback abgesichert

## 0.5.8

Erster belastbarer Git-Baseline-Stand.

## 0.7.2

- Entfernung leerer Endtakte neu aufgebaut.
- Kein Vorab-Löschen leerer Takte mehr per `time-delete`.
- Freie Komposition wird zuerst vollständig eingefügt.
- Danach wird ausschließlich MuseScores eigene Aktion `del-empty-measures` verwendet.
- Resultierende Taktzahl wird geprüft und im Kommunikationsprotokoll festgehalten.

## 0.7.4

- Layout klar in **Komposition / Analyse** und **Partitur-Chat** getrennt.
- Hauptbutton heißt jetzt **Auftrag ausführen**.
- Chat-Modi klarer benannt: **Nur besprechen** und **Änderung vorbereiten**.
- Chat erklärt ausdrücklich, dass er nicht automatisch in die Partitur schreibt.
- Neuer **Info**-Button mit Erklärung der Arbeitsbereiche, des Zwei-Stufen-Prinzips, Undo/Redo, Diagnose und Update.
- Diese Version dient zugleich als kontrollierter Test des eingebauten Updaters.

## 0.7.6

- Zwei getrennte Gedächtnisebenen eingeführt.
- **Generelles Gedächtnis** für allgemeine Arbeitsvorlieben und Vorbelegungen der Eingabe- und Auswahlfelder.
- **Score-Gedächtnis** für Chat, letzten Auftrag, musikalische Fassung, technische Daten und Score-spezifische Notizen.
- Score-Gedächtnis wird über MuseScores `metaTag()/setMetaTag()` direkt im jeweiligen Score abgelegt.
- Globaler Chatverlauf wurde durch Score-spezifischen Chatverlauf ersetzt.
- Neuer **Gedächtnis**-Dialog mit Anzeigen, Speichern, Neu laden und Leeren.

## 0.7.8

- Provider, Modell und API-Key aus dem oberen musikalischen Arbeitsbereich entfernt.
- Neuer eigener Bereich **Technisches** am unteren Rand der Oberfläche.
- Der Bereich **Komposition / Analyse** enthält jetzt nur noch musikalisch relevante Bedienelemente.
- Version 0.7.8 dient zugleich als kontrollierter Updater-Test von v0.7.7.

## 0.7.9

- Bereich **Technisches** ist jetzt einklappbar.
- Der Auf-/Zuklapp-Zustand wird als generelle Bedienpräferenz gespeichert.
- Beim nächsten Start wird der zuletzt verwendete Zustand wiederhergestellt.

## 0.7.10

- Übergangsversion zur neuen Loader-Architektur.
- Vorbereitung für versionierte App-Dateien, die über einen QML-Loader mit neuer URL geladen werden können.
- Neuer Live-Update-Kanal `AI-Notation-Studio-App.qml` mit Rückfall auf die bisherige monolithische Plugin-Datei.
- Künftige Live-Updates werden als `AI-Notation-Studio-App-<Version>.qml` neben dem Plugin gespeichert, geprüft und ohne MuseScore-Neustart aktiviert.
- Die aktive Live-App wird in den MuseScore-Einstellungen gespeichert und beim nächsten Start wieder geladen.
- Für den einmaligen Wechsel von v0.7.9 auf v0.7.10 ist weiterhin ein MuseScore-Neustart erforderlich.

## 0.8.0

- Erste getrennte, live ladbare App-Version.
- Der stabile Host v0.7.10 lädt die App über einen QML-`Loader` aus einer eigenen versionierten Datei.
- Die App initialisiert sich über `bootstrapRun()`, wenn sie vom Host geladen wird.
- Provider, Gedächtnis, Kompositionsfunktionen, Chat, Diagnose und der einklappbare Bereich **Technisches** bleiben Bestandteil der App.
- Ziel des Tests: Installation und sofortige Aktivierung von v0.8.0 ohne MuseScore-Neustart.
