# AI Notation Studio v0.10.10

AI Notation Studio ist ein MuseScore-Studio-Plugin für KI-gestützte Analyse, Komposition und Bearbeitung direkt an der Partitur.

## Modellauswahl ab 0.10.10

Unter **Technisches** stehen für Direkt/Stufe 1 sowie für Stufe 2 editierbare Auswahlfelder. Mit **Modelle laden** wird die Liste für den jeweiligen Anbieter über den gespeicherten API-Key abgerufen. Die Listen bleiben lokal gespeichert. Eigene Modellnamen können weiterhin eingegeben werden; vorhandene Auswahl und Keys bleiben erhalten. Für Stufe 2 zunächst **Dasselbe wie Stufe 1** ausschalten. Ohne gespeicherten Key erscheint ein entsprechender Hinweis. Bei Ladefehlern bleiben bisherige Liste und Modellwahl erhalten.

Die Listen verwenden die dokumentierten Anbieter-Endpunkte: [OpenAI](https://developers.openai.com/api/reference/resources/models/methods/list), [Anthropic](https://platform.claude.com/docs/en/api/models/list), [Google Gemini](https://ai.google.dev/api/models). Nicht für Textkomposition geeignete Audio-, Bild- und Embedding-Modelle werden ausgefiltert; Gemini-Modelle benötigen generateContent. Die Modell-ID wird unverändert an den bestehenden Kompositionsaufruf übergeben. Verfügbarkeit und Zugriffsrechte richten sich nach dem API-Konto. Modelllisten enthalten keine API-Keys.

## Dauerhafte Updates ab 0.10.9

Starter 0.7.17 und die Datei **AI-Notation-Studio-App-0.10.9.qml** einmal im Pluginordner installieren und MuseScore neu starten. Der Starter liest bei jedem Öffnen die lokal gespeicherte Datei **AI-Notation-Studio-Active.json**; sie benennt ausschließlich die geprüfte aktive App-Version. Eine erfolgreiche App-Initialisierung schreibt und prüft diese Auswahl. Die Startversion wird nicht mehr über mehrere Settings-Instanzen koordiniert. Die Provider-Keys bleiben im bisherigen Settings-Bereich.

Der Neustarttest installiert per echter QML-Updatefunktion eine neuere Datei, zerstört und öffnet das Plugin im selben Engine-Cache und startet zusätzlich einen neuen Prozess. In beiden Fällen wird die neue Version geladen. Ungültige Datensätze und fehlende Dateien fallen auf das mitgelieferte Bundle zurück.

## Wechsel von älteren Fassungen

Starter 0.7.15 lädt die mitgelieferte Datei **AI-Notation-Studio-App-0.10.6.qml** über eine neue URL. Dadurch wird der QML-Cache früherer Dateien umgangen. Diese Datei und AI-Notation-Studio.qml im selben Pluginordner ablegen. Nur den Starter aktivieren. Ältere App-Dateien können deaktiviert bleiben. Nach dem Austausch MuseScore vollständig neu starten. Spätere Versionen werden weiterhin über die Updatefunktion als versionierte Dateien installiert.

## Einträge im Pluginmanager

**AI Notation Studio** ist der einzige zu aktivierende Starter. **AI Notation Studio – interne App (nicht starten)** gehört dazu und bleibt im Pluginmanager deaktiviert. Beide QML-Dateien müssen im selben Ordner liegen. Ab 0.10.3 haben die Einträge unterschiedliche Namen.

## Startkorrektur 0.10.2 – 08.10.2026 / Starter 0.7.12

Der Starter verwendet nur QtQuick, MuseScore und FileIO. Die eigentliche Oberfläche wird getrennt geladen. Fehler beim Kompilieren oder Starten der App werden mit Dateipfad und QML-Fehlertext auf einer einfachen, auswählbaren Diagnosefläche angezeigt. Der Starter benötigt weder QtQuick.Controls noch Qt.labs.settings. Beide Dateien verwenden ausdrücklich MuseScores eigenen Settings-Typ; Kategorie und bestehende Keys bleiben erhalten.

Die frühere Behauptung, dem ursprünglichen Host fehle ein Settings-Import, war falsch: MuseScore exportiert diesen Typ bereits. Im Testobjekt fehlte diese Registrierung. Der Test bildet sie jetzt nach. Das zusätzliche Qt.labs.settings-Modul ist keine notwendige Laufzeitabhängigkeit mehr. Ob dessen Fehlen das konkrete Windows-Fenster verursacht hat, ist ohne dortigen Fehlertext noch nicht bestätigt.

Bei leerem Fenster MuseScore vollständig schließen und im vorhandenen Pluginordner **beide** Dateien `AI-Notation-Studio.qml` und `AI-Notation-Studio-App.qml` ersetzen. Nur `AI-Notation-Studio.qml` im Pluginmanager aktivieren. Die App-Datei ist ein Bestandteil desselben Plugins. Anschließend MuseScore neu starten. Fehlertexte können von der neuen Startfläche kopiert werden.

## Arbeitsweisen ab 0.10.0 – 06.10.2026

Alle sechs Kompositionsmodi verwenden CompactScore CS1. Im Feld **Arbeitsweise** stehen drei Abläufe zur Wahl:

| Arbeitsweise | Erste Stufe | Zweite Stufe |
|---|---|---|
| Direkt komponieren | Fertige Komposition in CS1 | entfällt |
| Idee entwickeln → komponieren | Kurze Idee, im Plugin editierbar | Erst nach **Jetzt komponieren**: vollständige Komposition in CS1 |
| Musik zuerst → nach CS1 übertragen | Vollständig ausgearbeitete musikalische Fassung | Automatische, möglichst unveränderte Übertragung nach CS1 |

Unter **Technisches** gilt der bisherige Anbieter mit seinem Modell für Direkt, Stufe 1, Analyse und Chat. Für zweistufige Abläufe kann **Dasselbe wie Stufe 1** deaktiviert und ein anderer Anbieter mit eigenem Modell für Stufe 2 gewählt werden. Beide Stufen verwenden die bereits gespeicherten Provider-Keys. Fehlt der zweite Key, wird vor dem ersten kostenpflichtigen Aufruf darauf hingewiesen. Der Key wird über die vorhandenen Anbieter-/Key-Felder eingerichtet. Arbeitsweise und Modellwahl werden gespeichert.

Nach einem Auftrag zeigen die Kostenzeilen Anbieter, Modell, Betrag je Aufruf sowie die Summe des Auftrags. Tokens, Cache-Nutzung, Thinking-Tokens und Laufzeiten je Stufe stehen in der Diagnose. Die erste Ausgabe wird dem zweiten Modell als Eingabe mitgegeben und entsprechend erneut berechnet. Modelle werden während des Auftrags festgehalten; ein Wechsel der sichtbaren Felder verändert einen laufenden Auftrag nicht.

**Fertige Fassung in MuseScore öffnen** überträgt die Musik einschließlich Ausdruckszeichen per MusicXML. Freie Komposition öffnet ein neues Stück. Die übrigen Modi öffnen eine kombinierte Kopie der beim Auftragsbeginn gesicherten Ausgangspartitur: neue Stimme, Motiv, Variante und Bearbeitung als zusätzliche Parts am Auswahlbeginn; Fortsetzung am Partiturende in denselben Parts. Das Original bleibt erhalten. Die Kopie kann durch MuseScores MusicXML-Import ein anderes Layout erhalten. Den geöffneten Score anschließend speichern.

Die bearbeitete Idee, fertige musikalische Fassung, Stufenmodelle und Kosten gehören zum Score-Gedächtnis. Vorhandene ältere technische JSON-Ergebnisse bleiben einfügbar; neue Aufträge verwenden ausschließlich CS1. Über **CS1 / JSON importieren** lassen sich CS1 sowie AI-Notation-Mini/Maxi-Texte laden. Analyse und Chat behalten ihre unabhängigen Abläufe.

Die drei Anbieter verwenden die vorhandenen gespeicherten API-Keys. Kosten werden pro Aufruf und Sitzung als geschätzte USD-Beträge aus dem gemeldeten Tokenverbrauch angezeigt. Unbekannte Modelle oder fehlende Nutzungsdaten werden als nicht berechenbar ausgewiesen. Thinking-Tokens werden bei Anthropic nicht doppelt abgerechnet; Cache-Tarife werden berücksichtigt. Tarife und ihre Quellen stehen in `compactscore-costs.js` und in der Diagnose.

MusicXML übernimmt unter anderem Stimmen, Akkorde, Pausen, Punktierungen, Tuplets, Dynamik, Artikulationen, Bögen, Haltebögen, Fermaten, Pedal und Tempo. Nicht umsetzbare seltene Markierungen erscheinen als Hinweise. Das vollständige CS1 bleibt als `.cs` neben der erzeugten `.musicxml` im Pluginverzeichnis und im Score-Metadatum `AI-Notation-Studio-Source-CS1` erhalten. Den geöffneten Score anschließend speichern.

Installation über **Update prüfen → Update installieren**. Für 0.10.2 den Starter einmal manuell ersetzen. Der gesamte Laufzeitcode ist in der App-QML enthalten; es sind keine zusätzlichen JS-Dateien zur Installation erforderlich.

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

Alle Arbeitsweisen führen zu CS1 und derselben lokalen MusicXML-Umsetzung. Nur „Idee entwickeln“ enthält eine bewusst gewählte Ideenphase und wartet auf den Nutzer. Bei „Musik zuerst“ ist die erste Ausgabe bereits die fertige Komposition, kein Vorentwurf. Eine höhere musikalische Qualität durch zusätzliche Aufrufe wird nicht vorausgesetzt.

## Update

Im Plugin genügt künftig:

1. **Update prüfen**
2. **Update installieren**
3. Die neue Live-App wird geladen; ein Neustart ist normalerweise nicht nötig.

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
