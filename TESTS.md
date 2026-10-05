# Testplan v0.6.0 RC

## A. Start

- [ ] Plugin öffnet sich.
- [ ] Version 0.6.0 wird angezeigt.
- [ ] Keine QML-/JavaScript-Fehlermeldung.

## B. Updatefunktion

- [ ] `Update prüfen` erreicht GitHub/main.
- [ ] gleiche Version wird als aktuell gemeldet.
- [ ] ältere Remote-Version führt nicht zu Downgrade.
- [ ] neuere Version wird erkannt.
- [ ] `Update installieren` schreibt erfolgreich in den Plugin-Ordner.
- [ ] nach MuseScore-Neustart ist die neue Version aktiv.
- [ ] Updatefehler beschädigt die vorhandene QML-Datei nicht.

## C. Regression

- [ ] Auswahl lesen funktioniert.
- [ ] Analyse funktioniert.
- [ ] Neue Stimme funktioniert.
- [ ] Freie Komposition funktioniert.
- [ ] Provider/Keys bleiben erhalten.
- [ ] Zwei-Stufen-Verfahren bleibt unverändert.

## Freigabe

v0.6.0 erst nach bestandenem Praxistest nach `main` übernehmen.
