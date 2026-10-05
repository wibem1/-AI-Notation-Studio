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

Kompositionsfunktionen arbeiten zweistufig:

1. endgültige musikalische Fassung
2. technische MuseScore-Umsetzung

Keine Vorentwurfsphase.
