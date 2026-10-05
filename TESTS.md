# Testplan v0.7.0

## Start und Update

- [ ] Plugin öffnet sich als v0.7.0.
- [ ] Updateprüfung funktioniert weiterhin.
- [ ] Provider, Modell und Keys bleiben erhalten.

## Bestehende Funktionen

- [ ] Auswahl lesen
- [ ] Auswahl analysieren
- [ ] neue Stimme zu Auswahl
- [ ] freie Komposition
- [ ] Zwei-Stufen-Verfahren

## Neue Kontextmodi

- [ ] Fortsetzen am Partiturende
- [ ] Fortsetzen außerhalb des Partiturendes wird sicher abgewiesen
- [ ] Aus Motiv entwickeln
- [ ] Variante erzeugen: genau eine Variante
- [ ] andere Besetzung
- [ ] neue Zielparts haben die richtigen Instrumente
- [ ] Klavier besitzt zwei Systeme

## Chat

- [ ] Besprechen verändert die Partitur nicht
- [ ] markierte Passage wird als Kontext berücksichtigt
- [ ] Ändern erzeugt einen Bearbeitungsauftrag
- [ ] Bearbeitungsauftrag lässt sich ins Auftragsfeld übernehmen
- [ ] Neuer Chat leert den Verlauf
- [ ] Chat bleibt nach Neustart erhalten

## Undo/Redo

- [ ] Rückgängig nimmt die letzte Plugin-Änderung zurück
- [ ] Wiederholen stellt sie wieder her
- [ ] normale MuseScore-Historie bleibt konsistent

## Diagnose und Protokoll

- [ ] Kommunikationsprotokoll wird angezeigt
- [ ] Diagnose enthält keine API-Keys
- [ ] Tokenwerte werden für verwendete Provider erfasst
- [ ] unbekannte Kosten werden als nicht berechenbar bezeichnet

## v0.7.2 – leere Endtakte

- [ ] Ausgangspartitur mit 32 leeren Takten, Auftrag 16 Takte.
- [ ] Komposition landet in den ersten 16 Takten.
- [ ] Nach dem Einfügen bleiben genau 16 Takte übrig.
- [ ] Kommunikationsprotokoll zeigt before/requested/after.

## v0.7.4 – Layout / Info / Updater

- [ ] v0.7.3 erkennt v0.7.4 über **Update prüfen**.
- [ ] **Update installieren** schreibt die neue Datei und bestätigt v0.7.4.
- [ ] Nach MuseScore-Neustart steht oben v0.7.4.
- [ ] Info-Dialog öffnet und schließt korrekt.
- [ ] Komposition/Analyse und Partitur-Chat sind optisch eindeutig getrennt.
- [ ] Chat-Modi **Nur besprechen** / **Änderung vorbereiten** funktionieren.
- [ ] Vorschlag lässt sich bewusst als Kompositionsauftrag übernehmen.

## v0.7.6 – Gedächtnis

- [ ] Allgemeine Vorbelegungen bleiben nach MuseScore-Neustart erhalten.
- [ ] Zwei unterschiedliche Scores erhalten getrennte Chatverläufe.
- [ ] Score A lädt nicht den Chat von Score B.
- [ ] Score-Gedächtnis bleibt nach Speichern, Schließen und erneutem Öffnen erhalten.
- [ ] Generelles Gedächtnis gilt in beiden Scores.
- [ ] Score-Gedächtnis lässt sich leeren, ohne das generelle Gedächtnis zu verändern.
- [ ] Generelles Gedächtnis lässt sich leeren, ohne Score-Gedächtnisse zu verändern.

## v0.7.8 – Technisches / Updater-Test

- [ ] v0.7.7 erkennt v0.7.8 über **Update prüfen**.
- [ ] **Update installieren** schreibt v0.7.8 ohne manuellen Terminal-Schritt.
- [ ] Nach MuseScore-Neustart steht oben v0.7.8.
- [ ] Provider, Modell und API-Key stehen unten unter **Technisches**.
- [ ] Der obere Bereich **Komposition / Analyse** enthält keine Provider-/Key-Felder mehr.
- [ ] Gespeicherte Provider-, Modell- und Key-Werte bleiben erhalten.

## v0.7.9 – Technisches einklappbar

- [ ] **Technisches** lässt sich auf- und zuklappen.
- [ ] Provider, Modell und API-Key sind im eingeklappten Zustand verborgen.
- [ ] Der letzte Auf-/Zuklapp-Zustand bleibt nach Plugin-Neustart erhalten.
- [ ] Update von v0.7.8 auf v0.7.9 funktioniert ohne Terminal-Schritt.

## v0.7.10 – Loader-Brücke

- [ ] Update von v0.7.9 auf v0.7.10 wird gefunden und installiert.
- [ ] Nach dem einmaligen MuseScore-Neustart startet v0.7.10 normal.
- [ ] Ohne veröffentlichte `AI-Notation-Studio-App.qml` fällt die Updateprüfung sauber auf die monolithische Datei zurück.
- [ ] Späterer Live-Test: eine veröffentlichte App-Version wird als versionierte lokale QML-Datei geschrieben und nach Versionsprüfung ohne MuseScore-Neustart geladen.
- [ ] Nach erneutem Start wird die zuletzt aktivierte Live-App aus den gespeicherten Einstellungen geladen.

## v0.8.0 – Live-Update-Test

- [ ] In v0.7.10 findet **Update prüfen** v0.8.0 als Live-Update.
- [ ] **Update installieren** schreibt und prüft die lokale versionierte App-Datei.
- [ ] Direkt danach wechselt die sichtbare Oberfläche auf **v0.8.0**, ohne MuseScore-Neustart.
- [ ] Komposition/Analyse, Chat, Gedächtnis und **Technisches** sind weiterhin vorhanden.
- [ ] Provider/Modell/API-Key bleiben erhalten.
- [ ] Schließen des Plugin-Fensters beendet MuseScore nicht.
- [ ] Nach einem späteren MuseScore-Neustart lädt der Host die gespeicherte Live-App wieder.
