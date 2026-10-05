# Bekannte Probleme und Grenzen

Stand: **v0.7.0**

## Bewusste Grenzen

- **Fortsetzen** ist nur erlaubt, wenn die Auswahl am Partiturende endet. Dadurch werden Kollisionen mit bereits vorhandener Musik vermieden.
- **Variante erzeugen** erzeugt genau eine Variante pro Lauf.
- **Chat – Ändern** schreibt nicht direkt in die Partitur, sondern erzeugt einen Bearbeitungsauftrag.
- Kosten werden nicht geschätzt, solange kein verifizierter Modellpreis hinterlegt ist.
- Diagnose und Kommunikationsprotokoll werden im Plugin angezeigt; es gibt noch keinen Dateiexport.
- Zielinstrumente werden über eine feste, API-verifizierte Liste abgebildet. Unbekannte Bezeichnungen fallen derzeit auf Violine zurück und sollten vermieden werden.

## Praktisch zu testen

- neue Kontextmodi mit mehreren Parts
- Klavier mit zwei Systemen
- Taktartwechsel beim Fortsetzen
- Undo/Redo nach größeren Einfügeaktionen
- Chat-Persistenz nach MuseScore-Neustart
- Tokenfelder der tatsächlich verwendeten Modelle
