# Bekannte Probleme und offene Punkte

Stand: **v0.5.8**

## Bestätigter Codefehler

In `makeCompositionPrompt()` wird derzeit `userText` verwendet, obwohl im aktuellen Plugin kein entsprechender Wert definiert ist. Das kann den Modus **Neue Stimme zu Auswahl** beim Erzeugen des musikalischen Prompts abbrechen. Dieser Fehler ist dokumentiert, aber in v0.5.8 noch nicht behoben.

## Offene technische Punkte

- Taktlöschung über `time-delete` muss in der realen Anwendung erneut geprüft werden.
- Das korrekte Anlegen verschiedener Instrumente und besonders eines Klaviers mit zwei Systemen muss praktisch geprüft werden.
- Die freie Komposition erzeugt neue Parts; deren Struktur muss bei allen unterstützten Instrumenten kontrolliert werden.
- Die aktuelle Version besitzt noch keine systematische Diagnose-/Protokollfunktion.
- Es gibt noch keinen eingebauten Chat.
- Es gibt noch kein eigenes Undo/Redo-Bedienfeld im Plugin.

## Entwicklungsorganisation

Mit Einrichtung dieses Repositories ist v0.5.8 der erste belastbare Git-Ausgangspunkt. Künftige Änderungen müssen auf `develop` entstehen und dokumentiert werden.
