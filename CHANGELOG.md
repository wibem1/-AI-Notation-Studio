# Changelog

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
