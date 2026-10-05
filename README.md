# AI Notation Studio v0.7.0

AI Notation Studio ist ein MuseScore-Studio-Plugin für KI-gestützte Analyse, Komposition und Bearbeitung direkt an der Partitur.

## Aktuelle Funktionen

- Auswahl analysieren
- neue Stimme zu einer Auswahl komponieren
- freie Komposition ohne Vorlage
- vorhandene Komposition fortsetzen
- aus einem Motiv entwickeln
- genau eine Variante erzeugen
- für eine andere Besetzung bearbeiten
- partiturbezogener Chat mit **Besprechen** und **Ändern**
- MuseScore-eigenes Rückgängig/Wiederholen
- Kommunikationsprotokoll
- Diagnose
- Tokenkontrolle
- integrierte GitHub-Updatefunktion

## Musikalische Architektur

Kompositionsfunktionen arbeiten zweistufig:

1. **Musikalische Fassung** — vollständig komponiert, ohne JSON-/Tick-Zwang.
2. **Technische Umsetzung** — Übertragung der fertigen Musik in MuseScore-Daten.

Es gibt keine Vorentwurfsphase.

## Update

Im Plugin genügt künftig:

1. **Update prüfen**
2. **Update installieren**
3. MuseScore neu starten

Es gibt nur einen Updateweg über den aktuellen Stand auf GitHub/`main`.

## Entwicklung

Ab v0.7.0 gibt es nur noch eine aktive Entwicklungslinie: `main`.

Rollback erfolgt über versionierte Git-Commits, nicht über parallele Nutzerzweige.

## Bedienoberfläche v0.7.4

Die Oberfläche trennt jetzt bewusst zwei Arbeitsbereiche:

- **Komposition / Analyse**: eigentlicher musikalischer Auftrag an die KI.
- **Partitur-Chat**: Gespräch über die Partitur; Änderungen werden nur vorbereitet und erst nach bewusster Übernahme zum Kompositionsauftrag.

Ein neuer **Info**-Button erklärt die Arbeitsweise direkt im Plugin.
