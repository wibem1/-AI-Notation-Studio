# Entwicklung

## Eine aktive Linie

Ab v0.7.0 wird die Entwicklung bewusst vereinfacht:

- `main` ist die einzige aktive Entwicklungslinie.
- Jede Änderung bekommt einen eigenen Git-Commit.
- Jede veröffentlichte Version erhält eine eindeutige Versionsnummer.
- Rollback erfolgt über Git-Historie, nicht über parallele Zweige.

## Verbindlicher Ablauf

1. API prüfen.
2. Änderung implementieren.
3. statisch kontrollieren.
4. Dokumentation aktualisieren.
5. über die eingebaute Updatefunktion ausliefern.
6. praktisch in MuseScore testen.
7. bei Fehlern auf den letzten funktionierenden Commit zurückgehen.

## Musikalisches Prinzip

Ab 0.10.0 gilt für alle Kompositionsmodi dieselbe CS1-Umsetzung. Die explizite Auswahl bestimmt den Ablauf: direkt, Idee → Komposition, vollständige Musik → Formatübertragung. Nur der Ideenmodus hält für die Bearbeitung an. Ein Auftrag erfasst Kontext, musikalische Angaben und beide Modellkonfigurationen vor dem ersten Netzwerkaufruf. Keys bleiben in Settings und werden nicht im Auftrag, im Score-Gedächtnis oder im Protokoll gespeichert.

## Loader-Architektur ab v0.7.10

v0.7.10 ist die Brücke vom monolithischen Plugin zur getrennten Loader/App-Struktur. Der klassische Einstieg `AI-Notation-Studio.qml` bleibt der MuseScore-Plugin-Host. Er enthält einen Loader, der künftig versionierte App-Dateien mit jeweils neuer URL lädt. Dadurch soll der bekannte QML-Komponenten-Cache umgangen werden, ohne MuseScore nach jedem Update neu zu starten.

Der Update-Feed prüft zuerst `AI-Notation-Studio-App.qml`. Ist diese Datei noch nicht veröffentlicht oder ungültig, wird auf `AI-Notation-Studio.qml` zurückgefallen. Eine Live-App wird lokal unter `AI-Notation-Studio-App-<Version>.qml` gespeichert, nachgelesen, anhand der Versionsnummer geprüft und erst danach aktiviert.

## v0.8.0 – erste Live-App

Die Datei `AI-Notation-Studio-App.qml` ist ab v0.8.0 der Update-Feed für die eigentliche Anwendung. Der Host lädt nach erfolgreichem Download lokal eine Datei mit versionsspezifischem Namen, z. B. `AI-Notation-Studio-App-0.8.0.qml`. Die unterschiedliche URL ist bewusst Teil des Designs, damit die neue QML-Komponente nicht unter derselben gecachten URL wie die vorherige Version läuft.

Die App bleibt selbst ein `MuseScore`-API-Objekt, wird aber vom Host als QQuickItem über `Loader` eingebettet. Weil ein geladenes Unterobjekt nicht über MuseScores normalen Plugin-Startpfad gestartet wird, stellt es `bootstrapRun()` bereit; der Host ruft diese Funktion in `Loader.onLoaded` auf.

## CompactScore-Laufzeit ab 0.9.0

Die Quellmodule `compactscore.js`, `compactscore-musicxml.js`, `compactscore-costs.js` und `compactscore-context.js` sind in die QML eingebettet. Nach Änderungen mit `NODE_PATH=<Babel-installation>/node_modules node scripts/embed-compactscore.cjs` neu erzeugen; benötigt @babel/core und @babel/preset-env (getestet mit 8.0.6). Dies ist ausschließlich ein Entwicklungsschritt. Danach die App identisch nach `versions/AI-Notation-Studio-App-0.10.0.qml` kopieren.

`python tests/test_compactscore.py` benötigt PySide6 und lxml und prüft den tatsächlich eingebetteten Code mit QJSEngine, die zwei realen CS1-Beispiele gegen MusicXML 4.0 sowie die API-Anfragen und Kosten. MuseScore bleibt der notwendige praktische Endtest.

## Tests 0.10.0

`python tests/test_workflows.py` prüft alle 18 Kombinationen aus sechs Modi und drei Arbeitsweisen mit deterministischen Provider-Antworten. Zusätzlich werden zusammengeführte MusicXML-Partituren gegen XSD validiert, Originalnoten verglichen, Auswahlpausen, Auftakte und transponierende Instrumente geprüft. `python tests/test_ui.py` startet die echte QML-Oberfläche offscreen mit den in `tests/qml-stubs` enthaltenen API-Testobjekten und prüft das editierbare Ideenfeld. Keine Tests verwenden echte API-Keys oder erzeugen kostenpflichtige Anfragen. Die Testobjekte ersetzen keinen realen MuseScore-Praxistest.

## Hosttest ab 0.10.1

Der Host 0.7.11 importiert Qt.labs.settings ausdrücklich. Bei Loader-Aktivierungen wird zuerst die alte Quelle entfernt, dann das neue Ziel gesetzt und zuletzt der Loader aktiviert. Fehler deaktivieren den Loader über Qt.callLater, um eine Rückkopplung während der active-Binding-Auswertung zu vermeiden. Beide QML-Dateien verwenden identische Windows-/UNC-URL-Konvertierung. Die App-Snapshots bleiben selbstständig; der Host erkennt optional die mitgelieferte aktuelle App. Der neue Integrationstest startet Host und App unter Qt 5 und 6; reine App-Standalone-Tests hätten den bisherigen Hostfehler nicht gefunden.
