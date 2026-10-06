# Changelog

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
