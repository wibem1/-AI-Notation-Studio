# Changelog

## 0.5.9 — Release Candidate

Stabilisierung nach vollständigem MuseScore-4.7-API-Audit. Keine neuen Funktionen.

- Fehler behoben: `makeCompositionPrompt()` verwendete die undefinierte Variable `userText`.
- Schutz ergänzt: freie Komposition löscht vorhandene Noten nicht mehr. Vor `time-delete` wird die Vollbereichsauswahl auf Note-/Chord-Elemente geprüft.
- Titelbehandlung geändert: `addText("title", ...)` entfernt; stattdessen `setMetaTag("workTitle", ...)`.
- Transaktionsbehandlung abgesichert: `cmdStarted` verhindert `endCmd(true)` ohne vorheriges `startCmd()`.
- Keine neuen Modi oder Funktionen.

Status: **noch nicht praktisch freigegeben**.

## 0.5.8 — Baseline

- Auswahl wird über `curScore.selection.elements` gelesen.
- Analyse einer markierten Passage.
- Komposition einer neuen Stimme zu einer markierten Passage.
- Freie Komposition ohne Vorlage.
- Zwei-Stufen-Verfahren: musikalische Komposition → technische Umsetzung für MuseScore.
- Provider: OpenAI, Anthropic, Google.
- Instrumente: Violine, Viola, Cello, Kontrabass, Klavier.
- Korrektur von `selection.selectRange(...)`: `endStaff` ist exklusiv; daher wird `curScore.nstaves` verwendet.

## Frühere Stände

Frühere Versionen entstanden vor Einrichtung dieses Git-Repositories und sind nicht vollständig als Git-Historie vorhanden.
