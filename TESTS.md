# Testplan v0.5.9 RC

## A. Start

- [ ] Plugin wird von MuseScore erkannt.
- [ ] Plugin-Fenster öffnet sich.
- [ ] Version 0.5.9 wird angezeigt.
- [ ] Keine QML-/JavaScript-Fehlermeldung beim Start.

## B. Einstellungen

- [ ] Providerwahl funktioniert.
- [ ] Modellfeld funktioniert.
- [ ] OpenAI-Key bleibt erhalten.
- [ ] Anthropic-Key bleibt erhalten.
- [ ] Google-Key bleibt erhalten.

## C. Auswahl und Analyse

- [ ] einzelne Note wird gelesen.
- [ ] mehrtaktige Bereichsauswahl wird gelesen.
- [ ] mehrere Stimmen/Systeme werden korrekt erfasst.
- [ ] Analyse bezieht sich tatsächlich auf die Auswahl.

## D. Neue Stimme

- [ ] `makeCompositionPrompt()` läuft ohne undefinierte Variable.
- [ ] musikalische Kompositionsstufe funktioniert.
- [ ] technische Umsetzungsstufe funktioniert.
- [ ] neue Stimme lässt sich einfügen.
- [ ] Zielinstrument und Zeitraum stimmen.

## E. Freie Komposition

- [ ] leere Ausgangspartitur kann vorbereitet werden.
- [ ] Partitur mit vorhandenen Noten wird vor `time-delete` abgewiesen und bleibt unverändert.
- [ ] gewünschte Besetzung wird angelegt.
- [ ] gewünschte Taktzahl wird hergestellt.
- [ ] Klavier mit zwei Systemen funktioniert.
- [ ] Tonart und Tempo werden gesetzt.
- [ ] `workTitle` wird gesetzt, ohne einen zweiten Titeltext hinzuzufügen.

## F. Transaktionen

- [ ] normaler Abschluss hinterlässt konsistente Undo-Historie.
- [ ] Fehler nach `startCmd()` führt zu Rollback.
- [ ] Fehler vor `startCmd()` ruft kein `endCmd(true)` auf.

## G. Regression

- [ ] Zwei-Stufen-Verfahren bleibt erhalten.
- [ ] Providerwechsel beschädigt gespeicherte Keys nicht.
- [ ] Auswahlfunktion aus v0.5.8 bleibt funktionsfähig.

## Freigabe

v0.5.9 wird erst nach bestandenem Praxistest nach `main` übernommen.
