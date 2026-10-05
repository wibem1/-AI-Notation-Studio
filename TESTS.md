# Verbindlicher Release-Test

Eine Version darf erst als **stable** gelten, wenn alle relevanten Punkte bestanden sind.

## A. Installation und Start

- [ ] Extension wird von MuseScore Studio 4.7 erkannt.
- [ ] AI Notation Studio lässt sich öffnen.
- [ ] Version wird korrekt angezeigt.
- [ ] Keine QML-/JavaScript-Fehlermeldung beim Start.
- [ ] API-Check zeigt Takte, Systeme und Parts korrekt.

## B. Einstellungen und Provider

- [ ] OpenAI-Key bleibt nach Neustart erhalten.
- [ ] Anthropic-Key bleibt nach Neustart erhalten.
- [ ] Google-Key bleibt nach Neustart erhalten.
- [ ] Modellwahl bleibt erhalten.
- [ ] Kein API-Key erscheint in Diagnose oder Protokoll.

## C. Auswahl und Analyse

- [ ] Einzelne Noten können gelesen werden.
- [ ] Mehrtaktige Auswahl kann gelesen werden.
- [ ] Mehrere Systeme/Parts werden korrekt erkannt.
- [ ] „Auswahl analysieren“ liefert eine plausible Antwort.

## D. Komposition

- [ ] Neue Stimme zu Auswahl funktioniert.
- [ ] Freie Komposition funktioniert.
- [ ] Fortsetzen funktioniert.
- [ ] Aus Motiv entwickeln funktioniert.
- [ ] Variante erzeugen funktioniert.
- [ ] Andere Besetzung funktioniert.
- [ ] Zwei-Stufen-Verfahren bleibt erhalten.

## E. MuseScore-Schreiben

- [ ] Gewünschte Taktzahl wird korrekt hergestellt.
- [ ] Noten landen im richtigen Part.
- [ ] Klavier verwendet korrekt zwei Systeme.
- [ ] Instrument-IDs stimmen.
- [ ] Titel/Metadaten verhalten sich korrekt.
- [ ] Tonart wird korrekt gesetzt.
- [ ] Tempo wird korrekt gesetzt.

## F. Undo/Redo

- [ ] Rückgängig nimmt die letzte Plugin-Änderung korrekt zurück.
- [ ] Wiederholen stellt sie korrekt wieder her.
- [ ] MuseScores normale Undo-Historie bleibt konsistent.

## G. Chat

- [ ] Besprechen verändert die Partitur nicht.
- [ ] Markierte Passage wird als Kontext berücksichtigt.
- [ ] Ändern erzeugt einen eindeutigen Bearbeitungsauftrag.
- [ ] Bearbeitungsauftrag lässt sich übernehmen.
- [ ] Neuer Chat leert den Verlauf.
- [ ] Chatverlauf bleibt nach Neustart erhalten.

## H. Diagnose und Kosten

- [ ] Protokoll unterscheidet Nutzer, App, KI, Technik und MuseScore.
- [ ] Diagnose enthält Version, Provider, Modell und Partiturstruktur.
- [ ] Eingabe- und Ausgabetokens werden korrekt erfasst.
- [ ] Unbekannte Preise werden als „nicht berechenbar“ angezeigt.
- [ ] Keine Zugangsdaten werden exportiert.

## Freigabe

- [ ] Alle kritischen Tests bestanden.
- [ ] `KNOWN-ISSUES.md` aktualisiert.
- [ ] `CHANGELOG.md` aktualisiert.
- [ ] `API-AUDIT.md` aktualisiert.
- [ ] Version als stable freigegeben.
