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
