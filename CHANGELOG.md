# Changelog

Ab diesem Repository-Stand wird die Entwicklung fortlaufend dokumentiert.

## 0.5.8 — aktueller Baseline-Stand

- Auswahl wird über `curScore.selection.elements` gelesen.
- Analyse einer markierten Passage.
- Komposition einer neuen Stimme zu einer markierten Passage.
- Freie Komposition ohne Vorlage.
- Zwei-Stufen-Verfahren:
  1. musikalische Komposition
  2. technische Umsetzung für MuseScore
- Provider: OpenAI, Anthropic, Google.
- Instrumente für neue Stimmen: Violine, Viola, Cello, Kontrabass, Klavier.
- Korrektur von `selection.selectRange(...)`: `endStaff` ist exklusiv; daher wird `curScore.nstaves` verwendet.

## Frühere Stände

Frühere Versionen entstanden vor Einrichtung dieses Git-Repositories. Sie sind nicht vollständig als Git-Historie vorhanden.

## Hinweis

Die zwischenzeitlich in der Dokumentation auftauchende Versionsreihe 0.6.x–0.8.x war keine reale veröffentlichte Entwicklungslinie dieses Plugins und wurde entfernt.
