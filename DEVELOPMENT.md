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

Die freie Komposition verwendet ab 0.9.0 direkt CS1 und eine lokale MusicXML-Umsetzung. Die übrigen Kompositionsfunktionen arbeiten zweistufig:

1. endgültige musikalische Fassung
2. technische MuseScore-Umsetzung

Keine Vorentwurfsphase.

## Loader-Architektur ab v0.7.10

v0.7.10 ist die Brücke vom monolithischen Plugin zur getrennten Loader/App-Struktur. Der klassische Einstieg `AI-Notation-Studio.qml` bleibt der MuseScore-Plugin-Host. Er enthält einen Loader, der künftig versionierte App-Dateien mit jeweils neuer URL lädt. Dadurch soll der bekannte QML-Komponenten-Cache umgangen werden, ohne MuseScore nach jedem Update neu zu starten.

Der Update-Feed prüft zuerst `AI-Notation-Studio-App.qml`. Ist diese Datei noch nicht veröffentlicht oder ungültig, wird auf `AI-Notation-Studio.qml` zurückgefallen. Eine Live-App wird lokal unter `AI-Notation-Studio-App-<Version>.qml` gespeichert, nachgelesen, anhand der Versionsnummer geprüft und erst danach aktiviert.

## v0.8.0 – erste Live-App

Die Datei `AI-Notation-Studio-App.qml` ist ab v0.8.0 der Update-Feed für die eigentliche Anwendung. Der Host lädt nach erfolgreichem Download lokal eine Datei mit versionsspezifischem Namen, z. B. `AI-Notation-Studio-App-0.8.0.qml`. Die unterschiedliche URL ist bewusst Teil des Designs, damit die neue QML-Komponente nicht unter derselben gecachten URL wie die vorherige Version läuft.

Die App bleibt selbst ein `MuseScore`-API-Objekt, wird aber vom Host als QQuickItem über `Loader` eingebettet. Weil ein geladenes Unterobjekt nicht über MuseScores normalen Plugin-Startpfad gestartet wird, stellt es `bootstrapRun()` bereit; der Host ruft diese Funktion in `Loader.onLoaded` auf.

## CompactScore-Laufzeit ab 0.9.0

Die drei Quellmodule `compactscore.js`, `compactscore-musicxml.js` und `compactscore-costs.js` sind in die QML eingebettet. Nach Änderungen mit `NODE_PATH=<Babel-installation>/node_modules node scripts/embed-compactscore.cjs` neu erzeugen; benötigt @babel/core und @babel/preset-env (getestet mit 8.0.6). Dies ist ausschließlich ein Entwicklungsschritt. Danach die App identisch nach `versions/AI-Notation-Studio-App-0.9.0.qml` kopieren.

`python tests/test_compactscore.py` benötigt PySide6 und lxml und prüft den tatsächlich eingebetteten Code mit QJSEngine, die zwei realen CS1-Beispiele gegen MusicXML 4.0 sowie die API-Anfragen und Kosten. MuseScore bleibt der notwendige praktische Endtest.
