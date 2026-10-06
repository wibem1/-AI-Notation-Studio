# AI Notation Studio v0.9.0

AI Notation Studio ist ein MuseScore-Studio-Plugin für KI-gestützte Analyse, Komposition und Bearbeitung direkt an der Partitur.

## Neu in 0.9.0

Freie Komposition erzeugt direkt CompactScore CS1 mit einem KI-Aufruf. **Komposition in MuseScore öffnen** erzeugt über MusicXML eine neue Partitur. Die vorhandene Partitur bleibt erhalten. Über **CS1 / JSON importieren** können vorhandene CS1- oder AI-Notation-Mini/Maxi-Texte eingefügt werden. Analyse, zusätzliche Stimme und die übrigen Bearbeitungsmodi behalten ihre bisherigen Abläufe.

Die drei Anbieter verwenden die vorhandenen gespeicherten API-Keys. Kosten werden pro Aufruf und Sitzung als geschätzte USD-Beträge aus dem gemeldeten Tokenverbrauch angezeigt. Unbekannte Modelle oder fehlende Nutzungsdaten werden als nicht berechenbar ausgewiesen. Thinking-Tokens werden bei Anthropic nicht doppelt abgerechnet; Cache-Tarife werden berücksichtigt. Tarife und ihre Quellen stehen in `compactscore-costs.js` und in der Diagnose.

MusicXML übernimmt unter anderem Stimmen, Akkorde, Pausen, Punktierungen, Tuplets, Dynamik, Artikulationen, Bögen, Haltebögen, Fermaten, Pedal und Tempo. Nicht umsetzbare seltene Markierungen erscheinen als Hinweise. Das vollständige CS1 bleibt als `.cs` neben der erzeugten `.musicxml` im Pluginverzeichnis und im Score-Metadatum `AI-Notation-Studio-Source-CS1` erhalten. Den geöffneten Score anschließend speichern.

Installation über **Update prüfen → Update installieren**. Der bestehende Host bleibt unverändert. Der gesamte Laufzeitcode ist in der App-QML enthalten; es sind keine zusätzlichen JS-Dateien zur Installation erforderlich.

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

## Gedächtnis ab v0.7.6

AI Notation Studio trennt jetzt zwei Ebenen:

- **Generelles Gedächtnis**: allgemeine Regeln, Arbeitsvorlieben und Vorbelegungen der Eingabe- und Auswahlfelder.
- **Score-Gedächtnis**: nur Informationen zum geöffneten Score, darunter Chat, letzter Auftrag und musikalische Arbeitsstände.

Das Score-Gedächtnis wird als MuseScore-Metadatum im jeweiligen Score gespeichert. Dadurch bleiben verschiedene Scores voneinander getrennt.

## Oberfläche v0.7.8

Technische Einstellungen sind jetzt vom musikalischen Arbeitsbereich getrennt. **Provider, Modell und API-Key** befinden sich gesammelt im unteren Bereich **Technisches**. Dadurch bleibt **Komposition / Analyse** auf die musikalische Arbeit konzentriert.
