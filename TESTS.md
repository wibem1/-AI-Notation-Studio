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

## 0.9.0 CompactScore

Automatisch geprüft: Qt-QJSEngine-Roundtrip, vollständige 16 Takte der Elegie und des Herbstlichen Abendgesangs, feste Klavier-Stimmenverteilung, Tuplets, Bögen, Atemzeichen, Pedal, Tempo, MusicXML-4.0-XSD, Erhalt der Quelldaten, Import-/Öffnen-Funktionen mit FileIO/MuseScore-Testobjekten, drei Provider-Anfragen, Mehrblock-Antworten, Tokenlimit, Schlüsselmaskierung und 0,04792 USD für 1245/4543 Anthropic-Tokens inklusive 2969 bereits enthaltener Thinking-Tokens. QML-Start und Syntax geprüft.

Praktisch noch zu prüfen: Update auf 0.9.0, echte freie Komposition mit gespeichertem Key, „Komposition in MuseScore öffnen“, Layout/Wiedergabe/Partiturspeicherung; Import der Elegie und des Herbstlichen Abendgesangs. Besonders Pedalwechsel, Atemzeichen und Klavierstimmen in der verwendeten MuseScore-Version kontrollieren.

## 0.10.0 – drei Arbeitsweisen / alle Kompositionsmodi

Bestanden: alle 18 Modus-/Arbeitsweise-Kombinationen im tatsächlichen Qt-JavaScript, Ideen-Stopp und bearbeiteter Text in Stufe 2, getrennte Provider/Modelle/Keys, Prüfung fehlender zweiter Keys vor dem ersten Aufruf, festgehaltener Kontext, Erhalt der musikalischen Erstfassung bei Fehlern, Wiederholung der Übertragung, Stufenkosten inklusive unbekannter Modellpreise, Schutz vor mehrfach ausgelösten Netzwerkcallbacks. Die zwei bestehenden CS1-Kompositionen bleiben unverändert erfolgreich. Kombinierte Partituren, neue Parts, Fortsetzung, Leertakte, Auswahlpausen, Auftakte, Klavier-Zweisystemigkeit und klingende Tonhöhen bei B-Instrumenten gegen MusicXML 4.0 getestet. QML-Start, Rendering, Scrollbarkeit und Bearbeitung des Ideenfeldes geprüft.

Praxistest in MuseScore noch erforderlich: Update auf 0.10.0; Idee mit Modell A erzeugen, bearbeiten, mit Modell B komponieren; Musik-zuerst-Ablauf; Kontextfassungen öffnen und vor allem Fortsetzung, Partzuordnung, Ausdruck/Wiedergabe und Speicherung überprüfen. Musikalische Qualitätsvergleiche wurden nicht durch technische Tests ersetzt. Native Importtests wurden hier mit API-Testobjekten simuliert, nicht in einer installierten MuseScore-Anwendung durchgeführt.

## 0.10.2 – Starter und sichtbare Ladefehler

`python tests/test_loader.py` und `python tests/test_loader.py --qt5` prüfen den originalen Host mit dem korrigierten Settings-Testobjekt, den minimalen Starter mit der vollständigen App, Windows-/UNC-Dateipfade und die sichtbare Rückkehr bei fehlenden Dateien und fehlenden QML-Modulen. Qt 6 prüft zusätzlich die tatsächlich gerenderte Hintergrundfarbe der Fehlerfläche. Qt 5 prüft die Instanziierung und Zustände, da Window-Grab im Offscreen-Backend fehlt. Echte API-Keys und KI-Anfragen werden nicht verwendet. Ein realer Windows-11-MuseScore-Test bleibt ausstehend.

## 0.10.4 – Scrollen

Der UI-Test prüft den Haupt-Flickable mit überhohem Inhalt, einen echten Mausklick auf die vertikale Scrollleiste sowie ein Mausradereignis. Beide bewegen contentY. Der Loaderstart wird zusätzlich unter Qt 5 geprüft.

## 0.10.5 – Updatefunktion

`python tests/test_update.py` führt die echten QML-Updaterfunktionen im Qt-JS-Interpreter mit deterministischen HTTP-Antworten aus. Geprüft: einmalige Antwortverarbeitung, neuer/gleicher Versionsstand, Schreiben und Lesen unter Windows-Dateipfaden, Aktivierungsquelle sowie HTTP-Fehler mit Rücksetzung des Beschäftigtzustands. Kein externer Netzaufruf.

## 0.10.7 – Bildschirm und Fenstergröße

Der Hosttest prüft, dass die Anfangsgröße unterhalb der verfügbaren Bildschirmgröße bleibt. Mit QT_SCALE_FACTOR=1.5 wird zusätzlich der Start bei Skalierung geprüft. Der UI-Test läuft nun auch mit --qt5 und prüft eine verkleinerte Fensterhöhe (500), die zugehörige tatsächliche Scrollbereichhöhe und die Erreichbarkeit des Inhaltsendes.

## 0.10.8 – Tatsächlich beschnittene MuseScore-Einbettung

`python tests/test_clipped_window.py` erstellt einen festen 900 hohen Plugin-Elternbereich in einem 500 hohen nativen Fenster. Im unveränderten Analysemodus reproduziert Qt 6 an 0.10.7 den Fall: 850 hoher Inhalt passt in den 864 hohen Flickable, wird aber vom Fenster abgeschnitten. Auch Qt 5 reproduziert den übergroßen Viewport, mit anderen Stilmaßen. Der neue Code begrenzt den Flickable auf 464; Mausrad, Scrollleistenklick, Inhaltsende und Verkleinerung des tatsächlichen Fensters auf 400 werden unter beiden Qt-Versionen geprüft.

## 0.10.9 – Update und Wiederöffnung

`python tests/test_update_restart.py` (auch `--qt5`) verwendet die vollständigen QML-Dateien und echten Datenträgerzugriff über einen FileIO-Testadapter. Ein Update wird geschrieben, geprüft, geladen und in Active.json gespeichert. Nach Zerstörung des Pluginobjekts lädt derselbe Engine-Cache die neue Version; ein zusätzlicher Prozess lädt ebenfalls die neue Version. Veraltete Settings-Einträge werden bewusst vorgegeben und ignoriert. Ein manipulierter Datensatz mit Pfad außerhalb des Pluginordners wird abgewiesen. Keine echten Netzaufrufe oder API-Keys.

## 0.10.10 – Modellauswahl

`python tests/test_model_catalog.py` prüft die echten Modellkatalogfunktionen im Qt-JS-Interpreter mit deterministischen API-Antworten: drei Header-/Endpunktverträge, Pagination, Filter, Duplikate, eigene Modelle, keyfreier Cache, HTTP-Fehler und verspätete Antworten. Der UI-Test prüft unter Qt 5 und 6 beide echten ComboBoxes samt Auswahl, Speicherung und manuellem Modellnamen. Keine echten API-Abfragen. Der Update-Neustarttest wird für die aktuelle App-Fassung erneut ausgeführt.
