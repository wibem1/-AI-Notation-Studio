# Testplan ab v0.5.8

## A. Start

- [ ] Plugin wird von MuseScore erkannt.
- [ ] Plugin-Fenster öffnet sich.
- [ ] Version 0.5.8 wird angezeigt.
- [ ] Keine QML-/JavaScript-Fehlermeldung beim Start.

## B. Einstellungen

- [ ] Providerwahl funktioniert.
- [ ] Modellfeld funktioniert.
- [ ] OpenAI-Key bleibt erhalten.
- [ ] Anthropic-Key bleibt erhalten.
- [ ] Google-Key bleibt erhalten.

## C. Auswahl

- [ ] einzelne Note wird gelesen.
- [ ] mehrtaktige Bereichsauswahl wird gelesen.
- [ ] mehrere Stimmen werden korrekt erfasst.
- [ ] Auswahl über mehrere Systeme wird korrekt erfasst.

## D. Analyse

- [ ] „Auswahl analysieren“ liefert eine plausible Antwort.
- [ ] Antwort bezieht sich tatsächlich auf die Auswahl.

## E. Neue Stimme

- [ ] `makeCompositionPrompt()` läuft ohne undefinierte Variablen.
- [ ] musikalische Kompositionsstufe funktioniert.
- [ ] technische Umsetzungsstufe funktioniert.
- [ ] neue Stimme lässt sich einfügen.
- [ ] Zielinstrument stimmt.
- [ ] Zeitraum entspricht der Auswahl.

## F. Freie Komposition

- [ ] gewünschte Besetzung wird angelegt.
- [ ] gewünschte Taktzahl wird hergestellt.
- [ ] Noten landen in den richtigen Parts.
- [ ] Klavier mit zwei Systemen funktioniert.
- [ ] Tempo und Tonart werden korrekt übernommen, soweit v0.5.8 dies unterstützt.
- [ ] überschüssige Takte werden korrekt behandelt.

## G. Regression

- [ ] Zwei-Stufen-Verfahren bleibt erhalten.
- [ ] bereits funktionierende Auswahl wird nicht beschädigt.
- [ ] Providerwechsel beschädigt gespeicherte Keys nicht.

## Freigabe

Eine neue Version wird erst nach dokumentiertem Praxistest als stabil bezeichnet.
