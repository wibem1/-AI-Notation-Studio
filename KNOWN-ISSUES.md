# Bekannte Probleme und Grenzen

Stand: **v0.10.0 – 06.10.2026**

## Bewusste Grenzen

- **Fortsetzen** ist nur erlaubt, wenn die Auswahl am Partiturende endet. Dadurch werden Kollisionen mit bereits vorhandener Musik vermieden.
- **Variante erzeugen** erzeugt genau eine Variante pro Lauf.
- **Chat – Ändern** schreibt nicht direkt in die Partitur, sondern erzeugt einen Bearbeitungsauftrag.
- Kosten werden nicht geschätzt, solange kein verifizierter Modellpreis hinterlegt ist.
- Diagnose und Kommunikationsprotokoll werden im Plugin angezeigt; es gibt noch keinen Dateiexport.
- Die MusicXML-Umsetzung erkennt gängige englische und deutsche Instrumentnamen. Unbekannte Klangzuordnungen erzeugen einen Hinweis und verwenden eine Klavier-Klangvorbelegung; die Instrumentbezeichnung und das CS1-Original bleiben erhalten.

## Praktisch zu testen

- neue Kontextmodi mit mehreren Parts
- Klavier mit zwei Systemen
- Taktartwechsel beim Fortsetzen
- Undo/Redo nach größeren Einfügeaktionen
- Chat-Persistenz nach MuseScore-Neustart
- Tokenfelder der tatsächlich verwendeten Modelle

## v0.7.2

Die bisher unzuverlässige Vorab-Verkürzung leerer Ausgangspartituren wurde entfernt. Offen ist nur noch der Praxistest, ob `del-empty-measures` auf dem Zielsystem die nach der Komposition verbliebenen leeren Endtakte korrekt entfernt.

## v0.10.0

- Kontextfassungen werden über MusicXML als neue Partitur geöffnet. MuseScore-spezifisches Layout, Plugins und Spezialnotation können bei einem MusicXML-Roundtrip anders erscheinen; das Ausgangsdokument bleibt erhalten.
- Auswahlbeginn innerhalb eines Taktes benötigt im CS1-Ergebnis die angeforderten Anfangspausen. Nicht passende Kontext-Taktlängen werden mit einem konkreten Fehler gemeldet, statt die Ausgangspartitur falsch auszurichten.
- Der lokale Kontextimport unterstützt MusicXML score-partwise mit festen Taktlängen; freie Taktarten senza-misura sind noch nicht unterstützt.
- Seltene, nicht abbildbare Markierungen bleiben im CS1-Original erhalten und werden als Hinweise ausgewiesen. Die neue Partitur ist kein Nachweis, dass jede Spezialnotation nativ übernommen wurde.
- Unterschiedliche Modelle erhalten den gleichen festgehaltenen Auftrag und die erste Ausgabe. Die Trennung „fertige Musik → Formatübertragung“ wird durch Prompts verlangt; völlige musikalische Unverändertheit eines zweiten KI-Aufrufs kann nicht garantiert werden.
- Praktischer MuseScore-Test und musikalischer Vergleich der Arbeitsweisen stehen noch aus.
