import QtQuick 2.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import MuseScore 3.0
import FileIO 3.0
import Qt.labs.settings 1.1

MuseScore {
    id: root
    menuPath: ""
    description: "Interne live ladbare App-Komponente von AI Notation Studio"
    version: "0.10.1"
    requiresScore: true
    pluginType: "dialog"
    title: "AI Notation Studio"
    width: 900
    height: 900

    property string selectionJson: ""
    property string statusText: "Bereit."
    property string aiAnswer: ""
    property string musicalDraft: ""
    property string compositionJson: ""
    property var compact: createCompactRuntime()
    property var compositionJob: null
    property string compositionIdea: ""
    property bool ideaReady: false
    property var compositionCosts: []
    property string compactSourceText: ""
    property var compactWarnings: []
    property var lastUsage: null
    property var lastPrices: null
    property var lastCost: null
    property real totalCostUsd: 0
    property bool unknownCosts: false
    property string costText: "Kosten: noch kein KI-Aufruf."
    property bool busy: false
    property string freeInstrumentation: "Violine, Cello"
    property int freeMeasures: 16
    property int uiSize: 18
    property string updateStatus: "Noch nicht geprüft."
    property string updateRemoteVersion: ""
    property string updateSourceText: ""
    property bool updateBusy: false
    property bool updateIsHotApp: false
    property string updaterTargetPath: ""
    property var communicationLog: []
    property int totalInputTokens: 0
    property int totalOutputTokens: 0
    property string pendingContextMode: ""
    property int pendingContextBaseTick: 0
    property int pendingContextMeasures: 0
    property bool pendingContextUseExistingParts: false
    property var pendingContextInstruments: []
    property var chatMessages: []
    property bool chatExpanded: false
    property int chatModeIndex: 0
    property string chatProposedInstruction: ""
    property int chatContextTurns: 12
    property string scoreMemoryNotes: ""
    property bool restoringMemory: false
    property bool technicalExpanded: false
    property bool hotAppActive: false
    property bool hotAppRequested: false
    property string hotAppVersion: ""
    property bool infoOpen: false

    Settings {
        id: settings
        category: "AI-Notation-Studio"
        property string provider: "OpenAI"
        property string modelOpenAI: "gpt-5.6-sol"
        property string modelAnthropic: "claude-sonnet-5"
        property string modelGoogle: "gemini-2.5-pro"
        property string keyOpenAI: ""
        property string keyAnthropic: ""
        property string keyGoogle: ""
        property int freeCompositionCounter: 0
        property string chatHistoryJson: "[]"
        property string generalMemoryText: ""
        property int defaultModeIndex: 0
        property string defaultInstruction: ""
        property string defaultFreeInstrumentation: "Violine, Cello"
        property int defaultFreeMeasures: 16
        property int defaultInstrumentIndex: 0
        property int defaultChatModeIndex: 0
        property bool defaultChatExpanded: false
        property bool defaultTechnicalExpanded: false
        property int compositionStrategy: 0
        property bool sameStageModel: true
        property string secondProvider: "Anthropic"
        property string secondModel: ""
        property string activeHotAppSource: ""
        property string activeHotAppVersion: ""
    }

    FileIO {
        id: compactFile
        onError: function(msg) { statusText = "Ergebnisdatei: " + msg }
    }

    FileIO {
        id: updaterFile
        onError: function(msg) {
            updateStatus = "Update-Datei konnte nicht geschrieben werden: " + msg
        }
    }

    property string compactInstructions: "Gib die fertige Komposition ausschließlich in CompactScore CS1 aus, ohne Markdown oder Vorentwurf. Keine MIDI-Controller, technischen Performancekurven, Nullwerte oder ungenutzten Felder erzeugen. Musikalisch benötigte Angaben beibehalten.\nCS1 ist ein Zeilenformat. S steht einmal am Anfang; P beginnt ein Instrument. Eine Zeile Takt/Stimme enthält die Ereignisse dieser Stimme; alle Stimmen beginnen bei Taktanfang. Leerzeichen trennen Ereignisse. Noten haben immer absolute Tonhöhen mit Oktave, ohne implizite Vorzeichen aus der Tonart.\nBeispiel:\nCS1\nS {\"t\":\"Titel\",\"k\":\"d minor\",\"m\":\"4/4\",\"b\":{\"v\":72,\"x\":\"Andante\"}}\nP {\"i\":\"violin\",\"n\":\"violin\"}\n1/1 R:h D4:q{\"i\":\"a\"} E4:e. F4:s\n2/1 [D4,F4,A4]:h D4:h{\"i\":\"b\",\"f\":\"normal\"}\nE {\"t\":\"dynamic\",\"p\":{\"m\":1,\"b\":3},\"v\":\"p\"}\nE {\"t\":\"expression\",\"p\":{\"m\":1,\"b\":3},\"x\":\"cantabile\"}\nE {\"t\":\"slur\",\"a\":\"a\",\"b\":\"b\"}\nNoten: C4:q; Pause: R:h; Akkord: [C4,E4,G4]:q.\nDauern: b=Brevis,w=Ganze,h=Halbe,q=Viertel,e=Achtel,s=16tel,t=32tel,x=64tel,z=128tel. Ein oder mehrere Punkte verlängern die Dauer. Triolen: (3:2:e C4:e D4:e E4:e ) ; allgemein (n:m:d Dauerfaktor m/n bis ).\nOptionale Attribute direkt am Ereignis als JSON: i=ID nur für referenzierte Noten, a=Artikulationsliste, o=Ornament, l=Bindung start/stop/continue, f=Fermate, r=Arpeggio. Beispiel C4:q{\"a\":[\"tenuto\"],\"l\":\"start\"}. Artikulationen gelten nur für diese Note.\nE-Markierungen gelten für das aktuelle Instrument; G-Markierungen global. Schlüssel: t=type,p=position,v=value,x=text,s=start,e=end,a=startRef,b=endRef,l=style,k=kind,q=tempo. Position: {\"m\":Takt,\"b\":Viertelposition}, 1 ist Taktanfang, 1.5 eine Achtel später. Dynamik und Spieltechnik nur am Beginn oder bei Änderung; Dynamik gilt im Instrument bis zur nächsten Änderung. Bögen verbinden IDs. Haarspange: E {\"t\":\"hairpin\",\"k\":\"crescendo\",\"s\":{\"m\":1,\"b\":1},\"e\":{\"m\":2,\"b\":1}}. Pedal genauso mit t=pedal ohne k. Tempo: G {\"t\":\"tempo\",\"p\":{\"m\":2,\"b\":1},\"q\":{\"v\":60,\"x\":\"rit.\"}}. Schlüsselwechsel: E {\"t\":\"clef\",\"p\":{\"m\":2,\"b\":1},\"v\":\"bass\"}. Sonstige seltene Markierungsfelder behalten den vollständigen Namen mit vorangestelltem ~. Keine unveränderten Zustände wiederholen. Für Auftakte oder verkürzte Takte die tatsächliche Viertellänge explizit als Taktattribut angeben, z. B. B 1 {\"actualDurationQuarters\":1,\"implicit\":true}.\n"

    function isCompactResult() {
        try { var d = JSON.parse(compositionJson); return d.format === "AI-Notation-Maxi" || d.format === "AI-Notation-Mini" } catch (e) { return false }
    }

    function acceptCompactText(text) {
        var clean = String(text).trim().replace(/^```[^\n]*\n/, "").replace(/\n```$/, "")
        var data = clean.indexOf("CS1") === 0 ? compact.score.decode(clean) : compact.score.decode(compact.score.encode(JSON.parse(clean)))
        var converted = compact.xml.convert(data)
        compactSourceText = compact.score.encode(data)
        compactWarnings = compact.score.inspect(data).concat(converted.warnings)
        compositionJson = JSON.stringify(data, null, 2)
        musicalDraft = compactSourceText
        aiAnswer = compactSourceText + (compactWarnings.length ? "\nHinweise:\n" + compactWarnings.join("\n") : "")
        statusText = converted.measures + " Takte, " + converted.parts + " Instrumente. Bereit zum Öffnen in MuseScore." + (compactWarnings.length ? " Hinweise beachten." : "")
    }

    function providerModel(provider) {
        return provider === "Anthropic" ? settings.modelAnthropic : provider === "Google" ? settings.modelGoogle : settings.modelOpenAI
    }

    function providerKey(provider) {
        return provider === "Anthropic" ? settings.keyAnthropic : provider === "Google" ? settings.keyGoogle : settings.keyOpenAI
    }

    function workflowName(index) {
        return ["Direkt komponieren", "Idee entwickeln", "Musik zuerst"][index] || "Direkt komponieren"
    }

    function prepareCompositionJob(mode) {
        var bounds = mode === 2 ? { startTick: 0, endTick: 0 } : selectionBounds()
        if (mode === 3 && bounds.endTick < scoreEndTick(curScore)) throw Error("Fortsetzen benötigt eine Auswahl am Partiturende.")
        var instruments = mode === 1 ? [instrumentBox.currentText] : mode === 2 ? normalizedInstrumentation() : contextTargetInstruments(mode)
        if (!instruments.length) throw Error("Bitte eine Zielbesetzung angeben.")
        var strategy = settings.compositionStrategy
        var first = { provider: providerName(), model: modelBox.text.trim() }
        var second = settings.sameStageModel ? { provider: first.provider, model: first.model } : {
            provider: settings.secondProvider, model: stageTwoModelBox.text.trim() || providerModel(settings.secondProvider)
        }
        if (!first.model || !providerKey(first.provider)) throw Error("Modell oder gespeicherter API-Key für die erste Stufe fehlt.")
        if (strategy !== 0 && (!second.model || !providerKey(second.provider))) throw Error("Modell oder gespeicherter API-Key für Stufe 2 (" + second.provider + ") fehlt. Im Bereich Technisches den Anbieter wählen und seinen Key speichern.")
        var job = { id: String(new Date().getTime()), created: new Date().toISOString(), mode: mode, modeName: modeBox.currentText,
            strategy: strategy, first: first, second: second, instruments: instruments, instruction: instructionBox.text.trim(),
            measures: mode === 1 ? selectionMeasureCount() : mode === 2 ? freeMeasures : contextMeasures(mode),
            selection: selectionJson, preferences: settings.generalMemoryText, sourcePath: "", startQuarter: mode === 3 ? bounds.endTick / 480 : bounds.startTick / 480,
            prefixQuarter: 0, startMeasure: 1, sourceTime: "", idea: "", draft: "" }
        if (mode !== 2) {
            var path = fileUrlToLocalPath(Qt.resolvedUrl("AI-Notation-Studio-Context-" + job.id + ".musicxml"))
            if (!writeScore(curScore, path, "musicxml")) throw Error("Ausgangspartitur konnte nicht für den Kontext gesichert werden.")
            compactFile.source = path
            var source = String(compactFile.read())
            var context = compact.context.inspect(source, job.startQuarter)
            job.sourcePath = path; job.prefixQuarter = context.prefixQuarter; job.startMeasure = context.startMeasure; job.sourceTime = context.timeSignature
            job.sourceMeters = context.meters.slice(context.startMeasure - 1, context.startMeasure - 1 + job.measures)
            if (mode === 1 || mode === 5 || mode === 6) {
                var ending = compact.context.inspect(source, bounds.endTick / 480)
                job.measures = Math.max(1, ending.startMeasure - context.startMeasure + (ending.prefixQuarter > 0 ? 1 : 0))
                job.sourceMeters = context.meters.slice(context.startMeasure - 1, context.startMeasure - 1 + job.measures)
            }
            job.sourceTitle = String(curScore.title || "")
        }
        return job
    }

    function compositionTask(job) {
        var action = ["", "Komponiere eine eigenständige zusätzliche Stimme zur Referenzpassage.",
            "Komponiere ein vollständiges neues Stück ohne musikalische Vorlage.",
            "Setze die Referenzmusik organisch fort. Verwende die vorhandenen Instrumente in gleicher Reihenfolge.",
            "Entwickle aus dem Motiv der Referenzpassage ein vollständiges Stück; das Motiv soll erkennbar bleiben.",
            "Erzeuge genau eine eigenständige Variante der Referenzpassage und bewahre ihre Identität und Funktion.",
            "Bearbeite die Referenzpassage idiomatisch für die Zielbesetzung und bewahre ihre musikalische Identität."][job.mode]
        var task = action + "\nAUFTRAG:\n" + job.instruction + "\nZIELBESETZUNG (Reihenfolge verbindlich): " + job.instruments.join(", ") +
            "\nLÄNGE: " + job.measures + " Takte.\nARBEITSVORLIEBEN:\n" + job.preferences +
            "\nGestalte musikalisch begründete Phrasen, motivische Beziehungen, Harmonik, Rhythmus und Ausdruck. Für die Instrumente spielbar schreiben. Klavier mit rechter und linker Hand. Nutzerangaben haben Vorrang. Für CS1 englische Instrumentnamen wie piano, violin, cello, flute und clarinet verwenden; pro Instrument ein P-Block mit eindeutiger ID. Tonhöhen klingend angeben; instrumentale Transposition übernimmt das Plugin."
        if (job.mode !== 2) task += "\nREFERENZAUSWAHL:\n" + job.selection +
            "\nTaktart am Beginn: " + job.sourceTime + ". Taktarten und tatsächliche Taktlängen der Ausgangspartitur: " + JSON.stringify(job.sourceMeters) + ". Die Taktlängen müssen damit übereinstimmen. Die Ergebnis-Takte werden ab 1 gezählt und ab Ausgangstakt " + job.startMeasure + " eingefügt."
        if (job.prefixQuarter > 0) task += "\nDie Auswahl beginnt " + job.prefixQuarter + " Viertel nach Taktanfang. In jeder Ergebnisstimme den ersten Takt mit genau dieser Dauer als Pausen beginnen; danach die Musik der Auswahl bearbeiten."
        if (job.mode === 1) task += "\nDie neue Stimme muss genau den Zeitraum der Auswahl abdecken; danach im letzten Takt gegebenenfalls Pausen. Keine vorhandenen Stimmen kopieren."
        return task
    }

    function stageRequest(job, prompt, stage, format, config, callback) {
        busy = true
        statusText = stage + " · " + config.provider + " / " + config.model + " …"
        callAI(prompt, function(ok, text) {
            busy = false
            if (!compositionJob || compositionJob.id !== job.id) return
            if (!ok) {
                aiAnswer = text
                statusText = stage + " fehlgeschlagen. Vorhandene Idee oder musikalische Fassung bleibt erhalten."
                saveScoreMemory(true)
                return
            }
            callback(text)
        }, stage, format, { provider: config.provider, model: config.model, jobId: job.id, maxTokens: 32768 })
    }

    function finishComposition(job, text) {
        try {
            acceptCompactText(text)
            var data = JSON.parse(compositionJson)
            if (data.parts.length !== job.instruments.length) throw Error("Die Anzahl der Instrumente passt nicht zur Zielbesetzung.")
            if (job.sourcePath !== "") {
                compactFile.source = job.sourcePath
                var merged = compact.context.combine(String(compactFile.read()), compact.xml.convert(data).xml,
                    { kind: job.mode === 3 ? "append" : "newParts", startQuarter: job.startQuarter })
                compactWarnings = compactWarnings.concat(merged.warnings)
            }
            musicalDraft = job.draft || compactSourceText
            ideaReady = false
            aiAnswer = (job.draft ? "MUSIKALISCHE FASSUNG:\n" + job.draft + "\n\nCS1:\n" : "") + compactSourceText +
                (compactWarnings.length ? "\nHinweise:\n" + compactWarnings.join("\n") : "")
            saveScoreMemory(true)
        } catch (e) {
            compositionJson = ""
            aiAnswer = text + "\n\nUmsetzungsfehler: " + e
            statusText = "Antwort erhalten; Umsetzung prüfen. Idee und musikalische Fassung bleiben erhalten."
            saveScoreMemory(true)
        }
    }

    function runCompositionJob(job) {
        var task = compositionTask(job)
        if (job.strategy === 0) {
            stageRequest(job, task, "Komposition direkt in CS1", compactInstructions, job.first, function(text) { finishComposition(job, text) })
        } else if (job.strategy === 1) {
            stageRequest(job, task + "\nEntwickle ausschließlich eine kurze, musikalisch konkrete KOMPOSITIONSIDEE: Charakter, Form, Motive, Harmonik, Instrumentrollen und Ausdruck. Noch keine vollständig ausnotierte Komposition, kein CS1, keine technischen Daten. Diese Idee wird vor dem Komponieren vom Nutzer geprüft und bearbeitet.",
                "Stufe 1: Idee entwickeln", "", job.first, function(text) {
                    compositionIdea = text; job.idea = text; compositionJob = job; ideaReady = true
                    aiAnswer = "Die Idee steht im editierbaren Feld. Mit „Jetzt komponieren“ entsteht daraus die fertige Komposition."
                    statusText = "Idee bereit zum Bearbeiten. Stufe 2 wurde noch nicht aufgerufen."
                    saveScoreMemory(true)
                })
        } else {
            stageRequest(job, task + "\nSchreibe die vollständige, endgültige musikalische Fassung, keinen Vorentwurf. Alle Instrumente, Takte, Stimmen, absoluten Tonhöhen mit Oktave, Notenwerte, Pausen, Tuplets, Dynamik, Artikulationen, Bögen und Pedal eindeutig festlegen. Taktweise lesbare musikalische Notation, keine technischen JSON-, MIDI-, Tick- oder CS1-Vorgaben. Keine Beschreibung anstelle der konkreten Musik.",
                "Stufe 1: Musik komponieren", "", job.first, function(text) {
                    job.draft = text; musicalDraft = text; compositionJob = job
                    saveScoreMemory(true)
                    realizeComposition(job)
                })
        }
    }

    function realizeComposition(job) {
        var prompt = compositionTask(job) + "\nVOLLSTÄNDIGE MUSIKALISCHE FASSUNG:\n" + job.draft +
            "\nÜbertrage ausschließlich diese fertige Musik nach CS1. Nicht neu komponieren, nichts vereinfachen, keine musikalischen Entscheidungen ändern. Alle Ausdrucksangaben übernehmen."
        stageRequest(job, prompt, "Stufe 2: Musik nach CS1 übertragen", compactInstructions, job.second, function(text) { finishComposition(job, text) })
    }

    function composeFromIdea() {
        if (busy || !ideaReady || !compositionJob) return
        var job = compositionJob
        if (compositionIdea.trim() === "") { statusText = "Bitte eine Kompositionsidee eingeben."; return }
        if (!providerKey(job.second.provider)) { statusText = "Gespeicherter API-Key für " + job.second.provider + " fehlt."; return }
        job.idea = compositionIdea; compositionJob = job
        logEvent("NUTZER", "Bearbeitete Kompositionsidee", { jobId: job.id, idea: compositionIdea })
        saveScoreMemory(true)
        stageRequest(job, compositionTask(job) + "\nVERBINDLICHE, VOM NUTZER GEPRÜFTE KOMPOSITIONSIDEE:\n" + compositionIdea +
            "\nKomponiere jetzt die vollständige Musik entsprechend dieser Idee direkt in CS1.",
            "Stufe 2: Aus Idee komponieren", compactInstructions, job.second, function(text) { finishComposition(job, text) })
    }

    function compositionCostText() {
        var out = [], sum = 0, unknown = false
        for (var i = 0; i < compositionCosts.length; i++) {
            var c = compositionCosts[i]
            out.push(c.stage + " · " + c.provider + " / " + c.model + ": " + (c.cost ? "$" + c.cost.usd.toFixed(5) : "nicht berechenbar"))
            if (c.cost) sum += c.cost.usd
            else unknown = true
        }
        return out.length ? out.join("\n") + "\nAuftrag gesamt: $" + sum.toFixed(5) + (unknown ? " + unbekannte Kosten" : "") + " (geschätzt, USD)" : "Auftrag: noch keine Kosten gemeldet."
    }

    function openCompactScore() {
        if (busy || !isCompactResult()) return
        try {
            var data = JSON.parse(compositionJson)
            var source = compact.score.encode(data)
            var result = compact.xml.convert(data)
            if (compositionJob && compositionJob.sourcePath) {
                compactFile.source = compositionJob.sourcePath
                var combined = compact.context.combine(String(compactFile.read()), result.xml,
                    { kind: compositionJob.mode === 3 ? "append" : "newParts", startQuarter: compositionJob.startQuarter })
                result.xml = combined.xml
                result.warnings = result.warnings.concat(combined.warnings)
            }
            var base = fileUrlToLocalPath(Qt.resolvedUrl("AI-Notation-Studio-Result-" + new Date().getTime()))
            compactFile.source = base + ".musicxml"
            if (!compactFile.write(result.xml) || String(compactFile.read()) !== result.xml) throw Error("MusicXML-Datei konnte nicht gespeichert werden.")
            compactFile.source = base + ".cs"
            if (!compactFile.write(source)) throw Error("CS1-Original konnte nicht gespeichert werden.")
            var imported = readScore(base + ".musicxml", false)
            if (!imported) throw Error("MuseScore konnte die MusicXML-Datei nicht öffnen: " + base + ".musicxml")
            imported.setMetaTag("AI-Notation-Studio-Source-CS1", source)
            imported.setMetaTag(scoreMemoryTagName(), JSON.stringify(currentScoreMemoryObject()))
            statusText = "Neue Partitur geöffnet. Bitte in MuseScore speichern." + (result.warnings.length ? " Hinweise: " + result.warnings.join(" · ") : "")
            logEvent("MUSESCORE", "CS1 über MusicXML geöffnet", { path: base + ".musicxml", warnings: result.warnings })
        } catch (e) { statusText = "Öffnen fehlgeschlagen: " + e; logEvent("MUSESCORE", statusText) }
    }

    Dialog {
        id: compactImportDialog
        title: "CS1 / Mini / Maxi importieren"
        modal: true
        width: 700
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: ScrollView {
            implicitHeight: 420
            TextArea { id: compactImportText; width: parent.width; wrapMode: TextEdit.Wrap; selectByMouse: true; placeholderText: "CS1 oder Mini/Maxi-JSON hier einfügen" }
        }
        onAccepted: {
            try { acceptCompactText(compactImportText.text); compositionJob = null; ideaReady = false; compositionIdea = ""; compositionCosts = [] }
            catch (e) { statusText = "Import fehlgeschlagen: " + e }
        }
    }

    // BEGIN COMPACTSCORE RUNTIME (generated by scripts/embed-compactscore.cjs)
    function createCompactRuntime() {
        function ownKeys(e, r) { var t = Object.keys(e); if (Object.getOwnPropertySymbols) { var o = Object.getOwnPropertySymbols(e); r && (o = o.filter(function (r) { return Object.getOwnPropertyDescriptor(e, r).enumerable; })), t.push.apply(t, o); } return t; }
        function _objectSpread(e) { for (var r = 1; r < arguments.length; r++) { var t = null != arguments[r] ? arguments[r] : {}; r % 2 ? ownKeys(Object(t), !0).forEach(function (r) { _defineProperty(e, r, t[r]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(e, Object.getOwnPropertyDescriptors(t)) : ownKeys(Object(t)).forEach(function (r) { Object.defineProperty(e, r, Object.getOwnPropertyDescriptor(t, r)); }); } return e; }
        function _defineProperty(e, r, t) { return (r = _toPropertyKey(r)) in e ? Object.defineProperty(e, r, { value: t, enumerable: !0, configurable: !0, writable: !0 }) : e[r] = t, e; }
        function _toPropertyKey(t) { var i = _toPrimitive(t, "string"); return "symbol" == _typeof(i) ? i : i + ""; }
        function _toPrimitive(t, r) { if ("object" != _typeof(t) || !t) return t; var e = t[Symbol.toPrimitive]; if (void 0 !== e) { var i = e.call(t, r || "default"); if ("object" != _typeof(i)) return i; throw new TypeError("@@toPrimitive must return a primitive value."); } return ("string" === r ? String : Number)(t); }
        function _createForOfIteratorHelper(r, e) { var t = "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"]; if (!t) { if (Array.isArray(r) || (t = _unsupportedIterableToArray(r)) || e && r && "number" == typeof r.length) { t && (r = t); var _n = 0, F = function F() {}; return { s: F, n: function n() { return _n >= r.length ? { done: !0 } : { done: !1, value: r[_n++] }; }, e: function e(r) { throw r; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var o, a = !0, u = !1; return { s: function s() { t = t.call(r); }, n: function n() { var r = t.next(); return a = r.done, r; }, e: function e(r) { u = !0, o = r; }, f: function f() { try { a || null == t.return || t.return(); } finally { if (u) throw o; } } }; }
        function _typeof(o) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) { return typeof o; } : function (o) { return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o; }, _typeof(o); }
        function _slicedToArray(r, e) { return _arrayWithHoles(r) || _iterableToArrayLimit(r, e) || _unsupportedIterableToArray(r, e) || _nonIterableRest(); }
        function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }
        function _unsupportedIterableToArray(r, a) { if (r) { if ("string" == typeof r) return _arrayLikeToArray(r, a); var t = {}.toString.call(r).slice(8, -1); return "Object" === t && r.constructor && (t = r.constructor.name), "Map" === t || "Set" === t ? Array.from(r) : "Arguments" === t || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t) ? _arrayLikeToArray(r, a) : void 0; } }
        function _arrayLikeToArray(r, a) { (null == a || a > r.length) && (a = r.length); for (var e = 0, n = Array(a); e < a; e++) n[e] = r[e]; return n; }
        function _iterableToArrayLimit(r, l) { var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"]; if (null != t) { var e, n, i, u, a = [], f = !0, o = !1; try { if (i = (t = t.call(r)).next, 0 === l) { if (Object(t) !== t) return; f = !1; } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0); } catch (r) { o = !0, n = r; } finally { try { if (!f && null != t.return && (u = t.return(), Object(u) !== u)) return; } finally { if (o) throw n; } } return a; } }
        function _arrayWithHoles(r) { if (Array.isArray(r)) return r; }
        function csEntries(o) {
          return Object.keys(o).map(function (k) {
            return [k, o[k]];
          });
        }
        function csFromEntries(a) {
          var o = {};
          a.forEach(function (e) {
            Object.defineProperty(o, e[0], {
              value: e[1],
              enumerable: true,
              writable: true,
              configurable: true
            });
          });
          return o;
        }
        var scope = {};
        (function (root) {
          'use strict';

          var VERSION = '0.1.0';
          var DUR = {
            whole: 'w',
            half: 'h',
            quarter: 'q',
            eighth: 'e',
            '16th': 's',
            '32nd': 't',
            '64th': 'x',
            '128th': 'z',
            breve: 'b'
          };
          var REV = csFromEntries(csEntries(DUR).map(function (_ref) {
            var _ref2 = _slicedToArray(_ref, 2),
              a = _ref2[0],
              b = _ref2[1];
            return [b, a];
          }));
          var SC = {
            title: 't',
            composer: 'c',
            key: 'k',
            timeSignature: 'm',
            tempo: 'b'
          };
          var PT = {
            id: 'i',
            instrument: 'n'
          };
          var EV = {
            id: 'i',
            dynamic: 'd',
            articulations: 'a',
            articulation: 'A',
            expressionText: 'e',
            slur: 's',
            tie: 'l',
            ornament: 'o',
            fermata: 'f',
            arpeggio: 'r',
            ratio: 'u'
          };
          var MK = {
            type: 't',
            position: 'p',
            value: 'v',
            text: 'x',
            start: 's',
            end: 'e',
            startRef: 'a',
            endRef: 'b',
            style: 'l',
            kind: 'k',
            tempo: 'q'
          };
          var POS = {
            measure: 'm',
            beat: 'b'
          };
          var TMP = {
            text: 'x',
            bpm: 'v'
          };
          var own = function own(o, k) {
            return Object.prototype.hasOwnProperty.call(o, k);
          };
          function object(o) {
            return o && _typeof(o) === 'object' && !Array.isArray(o);
          }
          function assign(o, k, v) {
            Object.defineProperty(o, k, {
              value: v,
              enumerable: true,
              writable: true,
              configurable: true
            });
          }
          function map(o, dict) {
            var reverse = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
            if (!object(o)) throw Error('Ein Objekt wird erwartet.');
            var result = {};
            var d = reverse ? csFromEntries(csEntries(dict).map(function (_ref3) {
              var _ref4 = _slicedToArray(_ref3, 2),
                k = _ref4[0],
                v = _ref4[1];
              return [v, k];
            })) : dict;
            var _iterator = _createForOfIteratorHelper(csEntries(o)),
              _step;
            try {
              for (_iterator.s(); !(_step = _iterator.n()).done;) {
                var _step$value = _slicedToArray(_step.value, 2),
                  k = _step$value[0],
                  v = _step$value[1];
                var key = reverse ? k.startsWith('~') ? k.slice(1) : d[k] || k : d[k] || '~' + k;
                if (own(result, key)) throw Error('Doppeltes Feld: ' + key);
                assign(result, key, v);
              }
            } catch (err) {
              _iterator.e(err);
            } finally {
              _iterator.f();
            }
            return result;
          }
          function meta(o, d) {
            var reverse = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
            var r = map(o, d, reverse);
            if (own(r, reverse ? 'tempo' : 'b')) {
              var k = reverse ? 'tempo' : 'b';
              if (object(r[k])) r[k] = map(r[k], TMP, reverse);
            }
            return r;
          }
          function marking(m) {
            var reverse = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
            var r = map(m, MK, reverse);
            for (var _i = 0, _arr = reverse ? ['position', 'start', 'end'] : ['p', 's', 'e']; _i < _arr.length; _i++) {
              var _k = _arr[_i];
              if (object(r[_k])) r[_k] = map(r[_k], POS, reverse);
            }
            var k = reverse ? 'tempo' : 'q';
            if (object(r[k])) r[k] = map(r[k], TMP, reverse);
            return r;
          }
          function omit(o, keys) {
            var r = {};
            var _iterator2 = _createForOfIteratorHelper(csEntries(o)),
              _step2;
            try {
              for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
                var _step2$value = _slicedToArray(_step2.value, 2),
                  k = _step2$value[0],
                  v = _step2$value[1];
                if (!keys.includes(k)) assign(r, k, v);
              }
            } catch (err) {
              _iterator2.e(err);
            } finally {
              _iterator2.f();
            }
            return r;
          }
          function json(v) {
            return JSON.stringify(v);
          }
          function suffix(attrs) {
            return Object.keys(attrs).length ? json(map(attrs, EV)) : '';
          }
          function event(e) {
            if (!object(e)) throw Error('Ungültiges Ereignis.');
            if (e.type === 'tupletEnd' && Object.keys(e).length === 1) return ')';
            if (e.type === 'tupletStart' && /^\d+:\d+$/.test(e.ratio || '') && (!own(e, 'duration') || own(DUR, e.duration))) {
              var extra = omit(e, ['type', 'ratio', 'duration']);
              return '(' + e.ratio + (e.duration ? ':' + DUR[e.duration] : '') + suffix(extra);
            }
            if (['note', 'rest', 'chord'].includes(e.type) && own(DUR, e.duration) && (!own(e, 'dots') || Number.isInteger(e.dots) && e.dots >= 1 && e.dots <= 4)) {
              var p = e.type === 'rest' ? 'R' : e.type === 'note' ? e.pitch : Array.isArray(e.pitches) ? '[' + e.pitches.join(',') + ']' : null;
              var validPitch = function validPitch(x) {
                return /^[A-G](?:bb|##|b|#)?-?\d+$/.test(x);
              };
              if (p && (e.type === 'rest' || e.type === 'note' && validPitch(p) || e.type === 'chord' && e.pitches.length && e.pitches.every(validPitch))) {
                return p + ':' + DUR[e.duration] + '.'.repeat(e.dots || 0) + suffix(omit(e, ['type', e.type === 'note' ? 'pitch' : e.type === 'chord' ? 'pitches' : '__none', 'duration', 'dots']));
              }
            }
            return 'J' + json(e);
          }
          function splitTokens(line) {
            var out = [];
            var begin = 0,
              depth = 0,
              quoted = false,
              escape = false;
            for (var i = 0; i <= line.length; i++) {
              var c = line[i];
              if (quoted) {
                if (escape) escape = false;else if (c === '\\') escape = true;else if (c === '"') quoted = false;
                continue;
              }
              if (c === '"') {
                quoted = true;
                continue;
              }
              if (c === '{' || c === '[') depth++;
              if (c === '}' || c === ']') depth--;
              if (depth < 0) throw Error('Unpassende schließende Klammer.');
              if ((c === undefined || /\s/.test(c)) && depth === 0) {
                if (i > begin) out.push(line.slice(begin, i));
                begin = i + 1;
              }
            }
            if (quoted || depth) throw Error('Nicht abgeschlossene Zeichenkette oder Klammer.');
            return out;
          }
          function decodeEvent(token) {
            if (token === ')') return {
              type: 'tupletEnd'
            };
            if (token.startsWith('J')) {
              var _e = JSON.parse(token.slice(1));
              if (!object(_e) || typeof _e.type !== 'string') throw Error('Ungültiges J-Ereignis.');
              return _e;
            }
            var at = token.indexOf('{'),
              base = at < 0 ? token : token.slice(0, at),
              attrs = at < 0 ? {} : map(JSON.parse(token.slice(at)), EV, true);
            var e,
              m = base.match(/^\((\d+:\d+)(?::([whqestxzb]))?$/);
            if (m) {
              e = {
                type: 'tupletStart',
                ratio: m[1]
              };
              if (m[2]) e.duration = REV[m[2]];
            } else {
              m = base.match(/^(R|[A-G](?:bb|##|b|#)?-?\d+|\[[A-G](?:bb|##|b|#)?-?\d+(?:,[A-G](?:bb|##|b|#)?-?\d+)*\]):([whqestxzb])(\.{0,4})$/);
              if (!m) throw Error('Unbekanntes Ereignis: ' + base);
              e = {
                type: m[1] === 'R' ? 'rest' : m[1][0] === '[' ? 'chord' : 'note'
              };
              if (e.type === 'note') e.pitch = m[1];else if (e.type === 'chord') e.pitches = m[1].slice(1, -1).split(',');
              e.duration = REV[m[2]];
              if (m[3]) e.dots = m[3].length;
            }
            var _iterator3 = _createForOfIteratorHelper(csEntries(attrs)),
              _step3;
            try {
              for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
                var _step3$value = _slicedToArray(_step3.value, 2),
                  k = _step3$value[0],
                  v = _step3$value[1];
                if (own(e, k)) throw Error('Kernfeld doppelt: ' + k);
                assign(e, k, v);
              }
            } catch (err) {
              _iterator3.e(err);
            } finally {
              _iterator3.f();
            }
            return e;
          }
          function encode(score) {
            if (!object(score) || !Array.isArray(score.parts) || !object(score.score)) throw Error('Maxi/Mini mit score und parts wird erwartet.');
            var lines = ['CS1', 'S ' + json(meta(score.score, SC))];
            var rootExtra = omit(score, ['format', 'version', 'score', 'parts', 'globalMarkings']);
            if (score.format !== 'AI-Notation-Maxi' || score.version !== '0.1' || Object.keys(rootExtra).length) lines.push('X ' + json(_objectSpread({
              format: score.format,
              version: score.version
            }, rootExtra)));
            var _iterator4 = _createForOfIteratorHelper(score.parts),
              _step4;
            try {
              for (_iterator4.s(); !(_step4 = _iterator4.n()).done;) {
                var p = _step4.value;
                if (!Array.isArray(p.measures)) throw Error('Part ohne measures.');
                lines.push('P ' + json(map(omit(p, ['measures', 'markings']), PT)));
                var _iterator6 = _createForOfIteratorHelper(p.measures),
                  _step6;
                try {
                  for (_iterator6.s(); !(_step6 = _iterator6.n()).done;) {
                    var _m2 = _step6.value;
                    if (!Number.isInteger(_m2.number) || _m2.number < 1 || !Array.isArray(_m2.voices)) throw Error('Ungültiger Takt.');
                    var extra = omit(_m2, ['number', 'voices']);
                    if (Object.keys(extra).length || !_m2.voices.length) lines.push('B ' + _m2.number + ' ' + json(extra));
                    var _iterator8 = _createForOfIteratorHelper(_m2.voices),
                      _step8;
                    try {
                      for (_iterator8.s(); !(_step8 = _iterator8.n()).done;) {
                        var v = _step8.value;
                        if (!Number.isInteger(v.voice) || v.voice < 1 || !Array.isArray(v.events)) throw Error('Ungültige Stimme.');
                        lines.push(_m2.number + '/' + v.voice + (v.events.length ? ' ' + v.events.map(event).join(' ') : ''));
                        var vx = omit(v, ['voice', 'events']);
                        if (Object.keys(vx).length) lines.push('V ' + _m2.number + '/' + v.voice + ' ' + json(vx));
                      }
                    } catch (err) {
                      _iterator8.e(err);
                    } finally {
                      _iterator8.f();
                    }
                  }
                } catch (err) {
                  _iterator6.e(err);
                } finally {
                  _iterator6.f();
                }
                if (own(p, 'markings')) {
                  if (!Array.isArray(p.markings)) throw Error('markings muss eine Liste sein.');
                  if (!p.markings.length) lines.push('E []');
                  var _iterator7 = _createForOfIteratorHelper(p.markings),
                    _step7;
                  try {
                    for (_iterator7.s(); !(_step7 = _iterator7.n()).done;) {
                      var _m = _step7.value;
                      lines.push('E ' + json(marking(_m)));
                    }
                  } catch (err) {
                    _iterator7.e(err);
                  } finally {
                    _iterator7.f();
                  }
                }
              }
            } catch (err) {
              _iterator4.e(err);
            } finally {
              _iterator4.f();
            }
            if (own(score, 'globalMarkings')) {
              if (!Array.isArray(score.globalMarkings)) throw Error('globalMarkings muss eine Liste sein.');
              if (!score.globalMarkings.length) lines.push('G []');
              var _iterator5 = _createForOfIteratorHelper(score.globalMarkings),
                _step5;
              try {
                for (_iterator5.s(); !(_step5 = _iterator5.n()).done;) {
                  var m = _step5.value;
                  lines.push('G ' + json(marking(m)));
                }
              } catch (err) {
                _iterator5.e(err);
              } finally {
                _iterator5.f();
              }
            }
            return lines.join('\n') + '\n';
          }
          function decode(text) {
            var lines = text.replace(/^\uFEFF/, '').split(/\r?\n/);
            var header = false,
              s = false,
              p = null;
            var out = {
              format: 'AI-Notation-Maxi',
              version: '0.1',
              score: {},
              parts: []
            };
            function measure(n) {
              var m = p.measures.find(function (x) {
                return x.number === n;
              });
              if (!m) {
                m = {
                  number: n,
                  voices: []
                };
                p.measures.push(m);
              }
              return m;
            }
            var _loop = function _loop(_i2) {
                var l = lines[_i2].trim();
                if (!l || l.startsWith('//')) {
                  i = _i2;
                  return 0;
                }
                if (/^[SPEGX]$/.test(l) && _i2 + 1 < lines.length && /^\s*[\[{]/.test(lines[_i2 + 1])) l += ' ' + lines[++_i2].trim();
                try {
                  if (!header) {
                    if (l !== 'CS1') throw Error('CS1-Kopf fehlt.');
                    header = true;
                    i = _i2;
                    return 0;
                  }
                  var m;
                  if (l.startsWith('S ')) {
                    if (s || p) throw Error('S muss einmal vor P stehen.');
                    out.score = meta(JSON.parse(l.slice(2)), SC, true);
                    s = true;
                  } else if (l.startsWith('X ')) {
                    if (p) throw Error('X muss vor P stehen.');
                    var x = JSON.parse(l.slice(2));
                    if (!object(x)) throw Error('X muss Objekt sein.');
                    var _iterator9 = _createForOfIteratorHelper(csEntries(x)),
                      _step9;
                    try {
                      for (_iterator9.s(); !(_step9 = _iterator9.n()).done;) {
                        var _step9$value = _slicedToArray(_step9.value, 2),
                          k = _step9$value[0],
                          v = _step9$value[1];
                        if (['score', 'parts', 'globalMarkings'].includes(k)) throw Error('Reserviertes X-Feld ' + k);
                        assign(out, k, v);
                      }
                    } catch (err) {
                      _iterator9.e(err);
                    } finally {
                      _iterator9.f();
                    }
                  } else if (l.startsWith('P ')) {
                    if (!s) throw Error('S fehlt.');
                    var _x = map(JSON.parse(l.slice(2)), PT, true);
                    if (typeof _x.id !== 'string' || !_x.id || typeof _x.instrument !== 'string') throw Error('P benötigt i und n.');
                    if (out.parts.some(function (q) {
                      return q.id === _x.id;
                    })) throw Error('Doppelte Part-ID.');
                    if (own(_x, 'measures') || own(_x, 'markings')) throw Error('Reserviertes P-Feld.');
                    p = _objectSpread(_objectSpread({}, _x), {}, {
                      measures: []
                    });
                    out.parts.push(p);
                  } else if (m = l.match(/^(\d+)\/(\d+)(?:\s+(.*))?$/)) {
                    if (!p) throw Error('P fehlt.');
                    var n = +m[1],
                      vn = +m[2];
                    if (n < 1 || vn < 1) throw Error('Takt und Stimme beginnen bei 1.');
                    var bar = measure(n);
                    if (bar.voices.some(function (v) {
                      return v.voice === vn;
                    })) throw Error('Takt/Stimme doppelt.');
                    bar.voices.push({
                      voice: vn,
                      events: splitTokens(m[3] || '').map(decodeEvent)
                    });
                  } else if (m = l.match(/^B (\d+) (.*)$/)) {
                    if (!p || +m[1] < 1) throw Error('Ungültiges B.');
                    var _x2 = JSON.parse(m[2]);
                    if (!object(_x2) || own(_x2, 'number') || own(_x2, 'voices')) throw Error('Ungültige Taktattribute.');
                    var _bar = measure(+m[1]);
                    var _iterator0 = _createForOfIteratorHelper(csEntries(_x2)),
                      _step0;
                    try {
                      for (_iterator0.s(); !(_step0 = _iterator0.n()).done;) {
                        var _step0$value = _slicedToArray(_step0.value, 2),
                          _k2 = _step0$value[0],
                          _v = _step0$value[1];
                        assign(_bar, _k2, _v);
                      }
                    } catch (err) {
                      _iterator0.e(err);
                    } finally {
                      _iterator0.f();
                    }
                  } else if (m = l.match(/^V (\d+)\/(\d+) (.*)$/)) {
                    if (!p) throw Error('P fehlt.');
                    var _v2 = measure(+m[1]).voices.find(function (v) {
                      return v.voice === +m[2];
                    });
                    if (!_v2) throw Error('Stimme fehlt vor V.');
                    var _x3 = JSON.parse(m[3]);
                    if (!object(_x3) || own(_x3, 'voice') || own(_x3, 'events')) throw Error('Ungültige Stimmattribute.');
                    var _iterator1 = _createForOfIteratorHelper(csEntries(_x3)),
                      _step1;
                    try {
                      for (_iterator1.s(); !(_step1 = _iterator1.n()).done;) {
                        var _step1$value = _slicedToArray(_step1.value, 2),
                          _k3 = _step1$value[0],
                          value = _step1$value[1];
                        assign(_v2, _k3, value);
                      }
                    } catch (err) {
                      _iterator1.e(err);
                    } finally {
                      _iterator1.f();
                    }
                  } else if (l.startsWith('E ') || l.startsWith('G ')) {
                    var global = l[0] === 'G';
                    if (!global && !p) throw Error('P fehlt.');
                    var holder = global ? out : p,
                      key = global ? 'globalMarkings' : 'markings';
                    var _value = JSON.parse(l.slice(2));
                    if (!own(holder, key)) holder[key] = [];
                    if (Array.isArray(_value)) {
                      if (_value.length) throw Error('Nur [] ist als leere Markierung erlaubt.');
                    } else holder[key].push(marking(_value, true));
                  } else throw Error('Unbekannte Zeile.');
                } catch (e) {
                  throw Error('Zeile ' + (_i2 + 1) + ': ' + e.message);
                }
                i = _i2;
              },
              _ret;
            for (var i = 0; i < lines.length; i++) {
              _ret = _loop(i);
              if (_ret === 0) continue;
            }
            if (!header || !s || !out.parts.length) throw Error('CS1, S und mindestens ein P werden benötigt.');
            return out;
          }
          function inspect(score) {
            var issues = [],
              ids = new Set(),
              refs = [];
            var beats = {
              breve: 8,
              whole: 4,
              half: 2,
              quarter: 1,
              eighth: .5,
              '16th': .25,
              '32nd': .125,
              '64th': .0625,
              '128th': .03125
            };
            var meter = score.score.timeSignature;
            var _iterator10 = _createForOfIteratorHelper(score.parts),
              _step10;
            try {
              for (_iterator10.s(); !(_step10 = _iterator10.n()).done;) {
                var p = _step10.value;
                var currentMeter = meter;
                var _iterator12 = _createForOfIteratorHelper(p.measures),
                  _step12;
                try {
                  for (_iterator12.s(); !(_step12 = _iterator12.n()).done;) {
                    var m = _step12.value;
                    currentMeter = m.timeSignature || currentMeter;
                    var mm = /^(\d+)\/(\d+)$/.exec(currentMeter || '');
                    var length = mm ? +mm[1] * 4 / +mm[2] : null;
                    var _iterator14 = _createForOfIteratorHelper(m.voices),
                      _step14;
                    try {
                      for (_iterator14.s(); !(_step14 = _iterator14.n()).done;) {
                        var v = _step14.value;
                        var sum = 0,
                          stack = [];
                        var _iterator15 = _createForOfIteratorHelper(v.events),
                          _step15;
                        try {
                          for (_iterator15.s(); !(_step15 = _iterator15.n()).done;) {
                            var e = _step15.value;
                            if (e.id) {
                              if (ids.has(e.id)) issues.push('Doppelte Ereignis-ID: ' + e.id);
                              ids.add(e.id);
                            }
                            if (e.type === 'tupletStart') {
                              var _r = /^(\d+):(\d+)$/.exec(e.ratio || '');
                              if (!_r || +_r[1] === 0 || +_r[2] === 0) issues.push('Ungültiges Tuplet: ' + p.id + '/' + m.number + '/' + v.voice);else stack.push(+_r[2] / +_r[1]);
                            } else if (e.type === 'tupletEnd') {
                              if (!stack.length) issues.push('Tuplet-Ende ohne Anfang: ' + p.id + '/' + m.number + '/' + v.voice);else stack.pop();
                            } else if (['note', 'rest', 'chord'].includes(e.type)) {
                              var d = beats[e.duration];
                              if (d === undefined) {
                                issues.push('Unbekannte Dauer: ' + e.duration);
                                continue;
                              }
                              if (!e.grace) sum += d * (2 - Math.pow(.5, e.dots || 0)) * stack.reduce(function (a, b) {
                                return a * b;
                              }, 1);
                            }
                          }
                        } catch (err) {
                          _iterator15.e(err);
                        } finally {
                          _iterator15.f();
                        }
                        if (stack.length) issues.push('Offenes Tuplet: ' + p.id + '/' + m.number + '/' + v.voice);
                        if (length !== null && Math.abs(sum - length) > 1e-7) issues.push(p.id + ' Takt ' + m.number + ' Stimme ' + v.voice + ': ' + sum + ' statt ' + length + ' Viertel (Auftakt/verkürzten Takt prüfen).');
                      }
                    } catch (err) {
                      _iterator14.e(err);
                    } finally {
                      _iterator14.f();
                    }
                  }
                } catch (err) {
                  _iterator12.e(err);
                } finally {
                  _iterator12.f();
                }
                var _iterator13 = _createForOfIteratorHelper(p.markings || []),
                  _step13;
                try {
                  for (_iterator13.s(); !(_step13 = _iterator13.n()).done;) {
                    var mark = _step13.value;
                    for (var _i4 = 0, _arr2 = ['startRef', 'endRef']; _i4 < _arr2.length; _i4++) {
                      var k = _arr2[_i4];
                      if (mark[k]) refs.push(mark[k]);
                    }
                  }
                } catch (err) {
                  _iterator13.e(err);
                } finally {
                  _iterator13.f();
                }
              }
            } catch (err) {
              _iterator10.e(err);
            } finally {
              _iterator10.f();
            }
            var _iterator11 = _createForOfIteratorHelper(score.globalMarkings || []),
              _step11;
            try {
              for (_iterator11.s(); !(_step11 = _iterator11.n()).done;) {
                var _mark = _step11.value;
                for (var _i5 = 0, _arr3 = ['startRef', 'endRef']; _i5 < _arr3.length; _i5++) {
                  var _k4 = _arr3[_i5];
                  if (_mark[_k4]) refs.push(_mark[_k4]);
                }
              }
            } catch (err) {
              _iterator11.e(err);
            } finally {
              _iterator11.f();
            }
            for (var _i3 = 0, _refs = refs; _i3 < _refs.length; _i3++) {
              var r = _refs[_i3];
              if (!ids.has(r)) issues.push('Unbekannte Bogenreferenz: ' + r);
            }
            return issues;
          }
          var api = {
            VERSION: VERSION,
            encode: encode,
            decode: decode,
            inspect: inspect
          };
          if (typeof module !== 'undefined' && module.exports) module.exports = api;
          root.CompactScore = api;
        })(scope);
        (function (root) {
          'use strict';

          var DUR = {
            breve: 8,
            whole: 4,
            half: 2,
            quarter: 1,
            eighth: .5,
            '16th': .25,
            '32nd': .125,
            '64th': .0625,
            '128th': .03125
          };
          var PROGRAM = {
            piano: 1,
            violin: 41,
            viola: 42,
            cello: 43,
            contrabass: 44,
            flute: 74,
            oboe: 69,
            clarinet: 72,
            bassoon: 71,
            horn: 61,
            trumpet: 57,
            trombone: 58,
            tuba: 59,
            guitar: 25,
            harp: 47,
            organ: 20,
            vibraphone: 12
          };
          var NAMES = {
            piano: 'Klavier',
            violin: 'Violine',
            viola: 'Viola',
            cello: 'Cello',
            contrabass: 'Kontrabass',
            flute: 'Flöte',
            oboe: 'Oboe',
            clarinet: 'Klarinette',
            bassoon: 'Fagott',
            horn: 'Horn',
            trumpet: 'Trompete',
            trombone: 'Posaune',
            tuba: 'Tuba',
            guitar: 'Gitarre',
            harp: 'Harfe',
            organ: 'Orgel',
            vibraphone: 'Vibraphon'
          };
          var KEYS = {
            C: 0,
            G: 1,
            D: 2,
            A: 3,
            E: 4,
            B: 5,
            'F#': 6,
            'C#': 7,
            F: -1,
            Bb: -2,
            Eb: -3,
            Ab: -4,
            Db: -5,
            Gb: -6,
            Cb: -7,
            Am: 0,
            Em: 1,
            Bm: 2,
            'F#m': 3,
            'C#m': 4,
            'G#m': 5,
            'D#m': 6,
            'A#m': 7,
            Dm: -1,
            Gm: -2,
            Cm: -3,
            Fm: -4,
            Bbm: -5,
            Ebm: -6,
            Abm: -7
          };
          function esc(s) {
            return String(s === undefined ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
          }
          function gcd(a, b) {
            while (b) {
              var c = a % b;
              a = b;
              b = c;
            }
            return a;
          }
          function lcm(a, b) {
            return a / gcd(a, b) * b;
          }
          function pitch(p) {
            var m = /^([A-G])(bb|##|b|#)?(-?\d+)$/.exec(p || '');
            if (!m) throw Error('Ungültige Tonhöhe: ' + p);
            var alter = {
              '': 0,
              b: -1,
              bb: -2,
              '#': 1,
              '##': 2
            }[m[2] || ''];
            return {
              step: m[1],
              alter: alter,
              octave: Number(m[3]),
              midi: (Number(m[3]) + 1) * 12 + {
                C: 0,
                D: 2,
                E: 4,
                F: 5,
                G: 7,
                A: 9,
                B: 11
              }[m[1]] + alter
            };
          }
          function key(text) {
            var m = /^([A-Ga-g])([#b]?)(.*)$/.exec(String(text || 'C').replace(/♭/g, 'b').replace(/♯/g, '#').trim());
            if (!m) throw Error('Unbekannte Tonart: ' + text);
            var minor = /minor|moll|^m$/i.test(m[3].trim()),
              name = m[1].toUpperCase() + m[2] + (minor ? 'm' : '');
            if (KEYS[name] === undefined) throw Error('Unbekannte Tonart: ' + text);
            return {
              fifths: KEYS[name],
              minor: minor
            };
          }
          function meter(s) {
            var m = /^(\d+)\/(\d+)$/.exec(s || '4/4');
            if (!m || !Number(m[1]) || !Number(m[2])) throw Error('Ungültige Taktart: ' + s);
            return {
              num: Number(m[1]),
              den: Number(m[2]),
              quarters: Number(m[1]) * 4 / Number(m[2])
            };
          }
          function flatten(events) {
            var result = [],
              stack = [],
              pending = [];
            events.forEach(function (e) {
              if (e.type === 'tupletStart') {
                var r = /^(\d+):(\d+)$/.exec(e.ratio || '');
                if (!r || !Number(r[1]) || !Number(r[2])) throw Error('Ungültiges Tuplet.');
                var t = {
                  actual: Number(r[1]),
                  normal: Number(r[2]),
                  level: stack.length + 1,
                  start: result.length,
                  duration: e.duration || 'eighth'
                };
                if (t.level > 6) throw Error('Mehr als sechs verschachtelte Tuplets.');
                stack.push(t);
                pending.push(t);
                return;
              }
              if (e.type === 'tupletEnd') {
                var t = stack.pop();
                if (!t || result.length === t.start) throw Error('Tuplet ohne Noten.');
                result[result.length - 1].stops.push(t);
                return;
              }
              if (!['note', 'chord', 'rest'].includes(e.type)) throw Error('Ereignis kann noch nicht nach MusicXML umgesetzt werden: ' + e.type);
              if (DUR[e.duration] === undefined) throw Error('Unbekannte Notendauer: ' + e.duration);
              var q = DUR[e.duration] * (2 - Math.pow(.5, e.dots || 0)),
                den = 128 * Math.pow(2, e.dots || 0),
                factor = 1,
                actual = 1,
                normal = 1;
              stack.forEach(function (t) {
                factor *= t.normal / t.actual;
                actual *= t.actual;
                normal *= t.normal;
                den *= t.actual;
              });
              var row = {
                event: e,
                q: e.grace ? 0 : q * factor,
                denominator: den,
                actual: actual,
                normal: normal,
                starts: pending,
                stops: [],
                tuplets: stack.slice(0)
              };
              pending = [];
              result.push(row);
            });
            if (stack.length) throw Error('Nicht geschlossenes Tuplet.');
            return result;
          }
          function instrumentName(name) {
            var low = String(name || 'piano').toLowerCase().replace(/[\s_-]/g, '');
            var aliases = {
              klavier: 'piano',
              pianoforte: 'piano',
              violine: 'violin',
              bratsche: 'viola',
              violoncello: 'cello',
              kontrabass: 'contrabass',
              doublebass: 'contrabass',
              'flöte': 'flute',
              floete: 'flute',
              klarinette: 'clarinet',
              fagott: 'bassoon',
              trompete: 'trumpet',
              posaune: 'trombone',
              harfe: 'harp',
              orgel: 'organ'
            };
            if (aliases[low]) return aliases[low];
            var known = Object.keys(PROGRAM);
            for (var i = 0; i < known.length; i++) if (low === known[i] || low.indexOf('.' + known[i]) >= 0) return known[i];
            return low;
          }
          function layout(part) {
            var instrument = instrumentName(part.instrument),
              ids = [];
            part.measures.forEach(function (m) {
              m.voices.forEach(function (v) {
                if (!ids.includes(v.voice)) ids.push(v.voice);
              });
            });
            ids.sort(function (a, b) {
              return a - b;
            });
            var voices = ids.map(function (id) {
              var pitches = [];
              part.measures.forEach(function (m) {
                m.voices.filter(function (v) {
                  return v.voice === id;
                }).forEach(function (v) {
                  v.events.forEach(function (e) {
                    (e.pitch ? [e.pitch] : e.pitches || []).forEach(function (p) {
                      pitches.push(pitch(p).midi);
                    });
                  });
                });
              });
              pitches.sort(function (a, b) {
                return a - b;
              });
              var median = pitches.length ? pitches[Math.floor(pitches.length / 2)] : 60;
              return {
                id: id,
                staff: instrument === 'piano' && ids.length > 1 && median < 60 ? 2 : 1
              };
            });
            var staves = instrument === 'piano' ? 2 : 1;
            [1, 2].forEach(function (staff) {
              if (voices.filter(function (v) {
                return v.staff === staff;
              }).length > 4) throw Error('Mehr als vier Stimmen in einem System.');
            });
            var clef = instrument === 'viola' ? ['C', 3] : ['cello', 'contrabass', 'bassoon', 'trombone', 'tuba'].includes(instrument) ? ['F', 4] : ['G', 2];
            return {
              instrument: instrument,
              voices: voices,
              staves: staves,
              clef: clef
            };
          }
          function convert(score) {
            if (!score || !score.score || !Array.isArray(score.parts) || !score.parts.length) throw Error('Keine Partitur.');
            var warnings = [],
              division = 128,
              maximum = 0,
              plans = score.parts.map(function (p) {
                var plan = layout(p);
                plan.part = p;
                plan.rows = {};
                p.measures.forEach(function (m) {
                  maximum = Math.max(maximum, m.number);
                  m.voices.forEach(function (v) {
                    var rows = flatten(v.events);
                    plan.rows[m.number + '/' + v.voice] = rows;
                    rows.forEach(function (r) {
                      division = lcm(division, r.denominator);
                    });
                  });
                });
                return plan;
              });
            if (division > 10000000) throw Error('Rhythmische Auflösung ist zu groß.');
            var baseKey = key(score.score.key),
              baseMeter = meter(score.score.timeSignature),
              tempo = Number(score.score.tempo && score.score.tempo.bpm || 72);
            function ticks(q) {
              var t = q * division;
              if (Math.abs(t - Math.round(t)) > .00001) throw Error('Rhythmus ist nicht exakt darstellbar.');
              return Math.round(t);
            }
            function textDirection(text, staff, offset) {
              return '<direction><direction-type><words>' + esc(text) + '</words></direction-type><offset>' + ticks(offset || 0) + '</offset><staff>' + staff + '</staff></direction>';
            }
            function direction(body, staff, q, sound) {
              return '<direction><direction-type>' + body + '</direction-type><offset>' + ticks(q || 0) + '</offset><staff>' + staff + '</staff>' + (sound || '') + '</direction>';
            }
            var xml = '<?xml version="1.0" encoding="UTF-8"?>\n<score-partwise version="4.0"><work><work-title>' + esc(score.score.title || 'Komposition') + '</work-title></work><movement-title>' + esc(score.score.title || 'Komposition') + '</movement-title>';
            if (score.score.composer) xml += '<identification><creator type="composer">' + esc(score.score.composer) + '</creator></identification>';
            xml += '<part-list>';
            plans.forEach(function (plan, i) {
              var id = 'P' + (i + 1),
                name = NAMES[plan.instrument] || plan.part.instrument;
              if (!PROGRAM[plan.instrument]) warnings.push('Instrument „' + name + '“: MusicXML verwendet Klavier als Klangvorbelegung.');
              xml += '<score-part id="' + id + '"><part-name>' + esc(name) + '</part-name><score-instrument id="' + id + '-I"><instrument-name>' + esc(name) + '</instrument-name></score-instrument><midi-instrument id="' + id + '-I"><midi-channel>' + (i % 15 < 9 ? i % 15 + 1 : i % 15 + 2) + '</midi-channel><midi-program>' + (PROGRAM[plan.instrument] || 1) + '</midi-program></midi-instrument></score-part>';
            });
            xml += '</part-list>';
            plans.forEach(function (plan, pi) {
              var part = plan.part,
                spans = {},
                directions = {},
                notationPositions = {},
                eventPositions = {},
                currentMeter = baseMeter;
              function at(position) {
                if (!position) return null;
                var m = Number(position.measure),
                  q = Number(position.beat) - 1;
                if (m < 1 || !isFinite(q) || q < 0) return null;
                return {
                  measure: m,
                  q: q
                };
              }
              function mark(position, body, staff, sound) {
                var pos = at(position);
                if (!pos) {
                  warnings.push('Markierung ohne gültige Position.');
                  return;
                }
                if (!directions[pos.measure]) directions[pos.measure] = [];
                directions[pos.measure].push({
                  q: pos.q,
                  xml: direction(body, staff || 1, pos.q, sound)
                });
              }
              function spanRef(ref, token) {
                if (!spans[ref]) spans[ref] = [];
                spans[ref].push(token);
              }
              function noteMark(position, token, end) {
                var pos = at(position);
                if (!pos) return;
                if (!notationPositions[pos.measure]) notationPositions[pos.measure] = [];
                notationPositions[pos.measure].push({
                  q: pos.q,
                  token: token,
                  end: !!end
                });
              }
              part.measures.forEach(function (m) {
                plan.voices.forEach(function (v) {
                  var q = 0;
                  (plan.rows[m.number + '/' + v.id] || []).forEach(function (row) {
                    if (row.event.id) eventPositions[row.event.id] = {
                      measure: m.number,
                      q: q,
                      staff: v.staff
                    };
                    q += row.q;
                  });
                });
              });
              var slurNumber = 0;
              (part.markings || []).concat(score.globalMarkings || []).forEach(function (m) {
                if (m.type === 'dynamic' && m.position) {
                  var d = String(m.value || '');
                  mark(m.position, '<dynamics>' + (/^(p{1,6}|f{1,6}|mp|mf|sf|sfp|sfz|sffz|fp|rf|rfz|fz|n)$/.test(d) ? '<' + d + '/>' : '<other-dynamics>' + esc(d) + '</other-dynamics>') + '</dynamics>');
                } else if (['expression', 'staffText', 'technique', 'text'].includes(m.type) && m.position) mark(m.position, '<words>' + esc(m.text || m.value || '') + '</words>');else if (m.type === 'tempo' && m.position) {
                  var t = m.tempo || {},
                    body = t.text ? '<words>' + esc(t.text) + '</words>' : '';
                  if (t.bpm) body += '<metronome><beat-unit>quarter</beat-unit><per-minute>' + Number(t.bpm) + '</per-minute></metronome>';
                  if (body) mark(m.position, body.replace(/<\/words><metronome>/g, '</words></direction-type><direction-type><metronome>'), 1, t.bpm ? '<sound tempo="' + Number(t.bpm) + '"/>' : '');
                } else if (m.type === 'hairpin' && m.start && m.end) {
                  var number = 1,
                    kind = /diminuendo|decrescendo/.test(m.kind || '') ? 'diminuendo' : 'crescendo';
                  mark(m.start, '<wedge type="' + kind + '" number="' + number + '"/>');
                  mark(m.end, '<wedge type="stop" number="' + number + '"/>');
                } else if (m.type === 'pedal' && m.start && m.end) {
                  var pedalStaff = plan.staves;
                  mark(m.start, '<pedal type="start" line="yes" number="1"/>', pedalStaff, '<sound damper-pedal="yes"/>');
                  mark(m.end, '<pedal type="stop" line="yes" number="1"/>', pedalStaff, '<sound damper-pedal="no"/>');
                } else if (m.type === 'slur' && m.startRef && m.endRef) {
                  var a = eventPositions[m.startRef],
                    b = eventPositions[m.endRef];
                  if (!a || !b) {
                    warnings.push('Bogen mit unbekannter Notenreferenz.');
                    return;
                  }
                  var number = slurNumber++ % 6 + 1,
                    line = /^(solid|dashed|dotted)$/.test(m.style || '') ? m.style : 'solid';
                  spanRef(m.startRef, '<slur type="start" number="' + number + '" line-type="' + line + '"/>');
                  spanRef(m.endRef, '<slur type="stop" number="' + number + '"/>');
                } else if (m.type === 'breath' && m.position) noteMark(m.position, '<articulations><breath-mark/></articulations>', true);else if (m.type === 'trillLine' && m.start && m.end) {
                  noteMark(m.start, '<ornaments><trill-mark/><wavy-line type="start" number="1"/></ornaments>');
                  noteMark(m.end, '<ornaments><wavy-line type="stop" number="1"/></ornaments>', true);
                } else if (m.type === 'ottava' && m.start && m.end) {
                  var kind = String(m.kind || m.value || '8va'),
                    down = /bassa|vb|below/.test(kind),
                    size = /15/.test(kind) ? 15 : 8;
                  mark(m.start, '<octave-shift type="' + (down ? 'up' : 'down') + '" size="' + size + '" number="1"/>');
                  mark(m.end, '<octave-shift type="stop" size="' + size + '" number="1"/>');
                } else if (m.type === 'clef' && m.position) {
                  if (!directions[m.position.measure]) directions[m.position.measure] = [];
                  var c = /bass/.test(m.value) ? ['F', 4] : /alto/.test(m.value) ? ['C', 3] : /tenor/.test(m.value) ? ['C', 4] : ['G', 2];
                  directions[m.position.measure].push({
                    q: Number(m.position.beat) - 1,
                    clef: c
                  });
                } else {
                  warnings.push('Markierung „' + m.type + '“ bleibt im CS1-Original erhalten; MusicXML unterstützt sie in dieser Version noch nicht.');
                }
              });
              xml += '<part id="P' + (pi + 1) + '">';
              for (var mn = 1; mn <= maximum; mn++) {
                var measure = part.measures.filter(function (m) {
                    return m.number === mn;
                  })[0],
                  changed = measure && measure.timeSignature && measure.timeSignature !== currentMeter.num + '/' + currentMeter.den;
                if (changed) currentMeter = meter(measure.timeSignature);
                var length = measure && Number(measure.actualDurationQuarters) > 0 ? Number(measure.actualDurationQuarters) : currentMeter.quarters;
                plan.voices.forEach(function (v) {
                  var sum = (plan.rows[mn + '/' + v.id] || []).reduce(function (a, r) {
                    return a + r.q;
                  }, 0);
                  if (sum > length + .00001) {
                    warnings.push('Takt ' + mn + ' Stimme ' + v.id + ' ist länger als die Taktart.');
                    length = Math.max(length, sum);
                  }
                });
                xml += '<measure number="' + mn + '"' + (measure && (measure.implicit || measure.actualDurationQuarters) ? ' implicit="yes"' : '') + '>';
                if (mn === 1 || changed) {
                  xml += '<attributes>';
                  if (mn === 1) xml += '<divisions>' + division + '</divisions><key><fifths>' + baseKey.fifths + '</fifths><mode>' + (baseKey.minor ? 'minor' : 'major') + '</mode></key>';
                  xml += '<time><beats>' + currentMeter.num + '</beats><beat-type>' + currentMeter.den + '</beat-type></time>';
                  if (mn === 1) {
                    xml += '<staves>' + plan.staves + '</staves>';
                    for (var staff = 1; staff <= plan.staves; staff++) {
                      var clef = staff === 2 ? ['F', 4] : plan.clef;
                      xml += '<clef number="' + staff + '"><sign>' + clef[0] + '</sign><line>' + clef[1] + '</line></clef>';
                    }
                  }
                  xml += '</attributes>';
                }
                if (mn === 1) {
                  if (score.score.tempo && score.score.tempo.text) xml += textDirection(score.score.tempo.text, 1, 0);
                  xml += direction('<metronome><beat-unit>quarter</beat-unit><per-minute>' + tempo + '</per-minute></metronome>', 1, 0, '<sound tempo="' + tempo + '"/>');
                }
                (directions[mn] || []).sort(function (a, b) {
                  return a.q - b.q;
                }).forEach(function (d) {
                  if (!d.clef) xml += d.xml;
                });
                plan.voices.forEach(function (v, vi) {
                  if (vi) xml += '<backup><duration>' + ticks(length) + '</duration></backup>';
                  var onset = 0,
                    rows = plan.rows[mn + '/' + v.id] || [],
                    clefs = (directions[mn] || []).filter(function (d) {
                      return !!d.clef;
                    });
                  rows.forEach(function (row) {
                    var e = row.event;
                    while (clefs.length && clefs[0].q <= onset + .00001) {
                      var c = clefs.shift();
                      if (vi === 0) xml += '<attributes><clef number="' + v.staff + '"><sign>' + c.clef[0] + '</sign><line>' + c.clef[1] + '</line></clef></attributes>';
                    }
                    if (e.dynamic) xml += direction('<dynamics><' + (/^(p{1,6}|f{1,6}|mp|mf|sfz|fp)$/.test(e.dynamic) ? e.dynamic : 'other-dynamics') + '/></dynamics>', v.staff, 0);
                    if (e.expressionText) xml += textDirection(e.expressionText, v.staff, 0);
                    var pitches = e.type === 'chord' ? e.pitches : e.type === 'note' ? [e.pitch] : [null];
                    pitches.forEach(function (p, ni) {
                      var properties = '',
                        notations = '',
                        ties = [];
                      if (e.tie === 'stop' || e.tie === 'continue') ties.push('stop');
                      if (e.tie === 'start' || e.tie === 'continue') ties.push('start');
                      if (e.grace) properties += '<grace/>';
                      if (ni) properties += '<chord/>';
                      if (p) {
                        var note = pitch(p);
                        properties += '<pitch><step>' + note.step + '</step>' + (note.alter ? '<alter>' + note.alter + '</alter>' : '') + '<octave>' + note.octave + '</octave></pitch>';
                      } else properties += '<rest/>';
                      if (!e.grace) properties += '<duration>' + ticks(row.q) + '</duration>';
                      ties.forEach(function (t) {
                        properties += '<tie type="' + t + '"/>';
                        notations += '<tied type="' + t + '"/>';
                      });
                      properties += '<voice>' + v.id + '</voice><type>' + e.duration + '</type>';
                      for (var dot = 0; dot < (e.dots || 0); dot++) properties += '<dot/>';
                      if (row.actual !== 1) properties += '<time-modification><actual-notes>' + row.actual + '</actual-notes><normal-notes>' + row.normal + '</normal-notes></time-modification>';
                      properties += '<staff>' + v.staff + '</staff>';
                      if (ni === 0) {
                        notations += (spans[e.id] || []).join('');
                        if (e.slur === 'start' || e.slur === 'continue') notations += '<slur type="start" number="6"/>';
                        if (e.slur === 'stop' || e.slur === 'continue') notations += '<slur type="stop" number="6"/>';
                        var arts = e.articulations || e.articulation || [];
                        if (typeof arts === 'string') arts = [arts];
                        var a = arts.map(function (x) {
                          return ['staccato', 'staccatissimo', 'tenuto', 'accent', 'marcato', 'detached-legato', 'soft-accent'].includes(x) ? '<' + (x === 'marcato' ? 'strong-accent' : x) + '/>' : '<other-articulation>' + esc(x) + '</other-articulation>';
                        }).join('');
                        if (a) notations += '<articulations>' + a + '</articulations>';
                        if (e.ornament) {
                          var o = {
                            trill: 'trill-mark',
                            turn: 'turn',
                            mordent: 'mordent',
                            prall: 'inverted-mordent',
                            prallprall: 'inverted-mordent'
                          }[e.ornament];
                          notations += '<ornaments>' + (o ? '<' + o + '/>' : '<other-ornament>' + esc(e.ornament) + '</other-ornament>') + '</ornaments>';
                        }
                        if (e.fermata) notations += '<fermata>' + (e.fermata === 'short' ? 'angled' : e.fermata === 'long' ? 'square' : 'normal') + '</fermata>';
                        if (e.arpeggio) notations += '<arpeggiate' + (/down/.test(e.arpeggio) ? ' direction="down"' : /up/.test(e.arpeggio) ? ' direction="up"' : '') + '/>';
                        row.starts.forEach(function (t) {
                          notations += '<tuplet type="start" number="' + t.level + '" bracket="yes"/>';
                        });
                        row.stops.forEach(function (t) {
                          notations += '<tuplet type="stop" number="' + t.level + '"/>';
                        });
                        (notationPositions[mn] || []).forEach(function (m) {
                          if (!m.used && vi === 0 && m.q >= onset - .00001 && (m.end ? m.q <= onset + row.q + .00001 : m.q < onset + row.q - .00001)) {
                            notations += m.token;
                            m.used = true;
                          }
                        });
                      }
                      xml += '<note>' + properties + (notations ? '<notations>' + notations + '</notations>' : '') + '</note>';
                    });
                    onset += row.q;
                  });
                  if (onset < length - .00001) {
                    var missing = ticks(length - onset);
                    if (!rows.length) xml += '<note><rest measure="yes"/><duration>' + missing + '</duration><voice>' + v.id + '</voice><staff>' + v.staff + '</staff></note>';else {
                      xml += '<forward><duration>' + missing + '</duration><voice>' + v.id + '</voice><staff>' + v.staff + '</staff></forward>';
                      warnings.push('Takt ' + mn + ' Stimme ' + v.id + ' ist kürzer als die Taktart; Vorschau ergänzt die fehlende Zeit.');
                    }
                  }
                });
                if (mn === maximum) xml += '<barline location="right"><bar-style>light-heavy</bar-style></barline>';
                xml += '</measure>';
              }
              Object.keys(notationPositions).forEach(function (n) {
                notationPositions[n].forEach(function (m) {
                  if (!m.used) warnings.push('Notenmarkierung in Takt ' + n + ' bei Viertelposition ' + (m.q + 1) + ' konnte keinem Ereignis zugeordnet werden.');
                });
              });
              xml += '</part>';
            });
            xml += '</score-partwise>';
            return {
              xml: xml,
              warnings: warnings.filter(function (x, i, a) {
                return a.indexOf(x) === i;
              }),
              measures: maximum,
              parts: plans.length
            };
          }
          var api = {
            convert: convert
          };
          if (typeof module !== 'undefined' && module.exports) module.exports = api;
          root.CompactMusicXML = api;
        })(scope);
        (function (root) {
          'use strict';

          var SOURCES = {
            openai: 'https://developers.openai.com/api/docs/models/',
            anthropic: 'https://platform.claude.com/docs/en/about-claude/pricing',
            google: 'https://ai.google.dev/gemini-api/docs/pricing'
          };
          var CATALOG = {
            openai: [{
              id: 'gpt-6.1-sol',
              name: 'GPT-6.1 Sol',
              input: 2,
              output: 10,
              read: .1,
              write: 2.5
            }, {
              id: 'gpt-6-luna',
              name: 'GPT-6 Luna',
              input: .1,
              output: .5,
              read: .01,
              write: .125
            }, {
              id: 'gpt-6-astra',
              name: 'GPT-6 Astra',
              input: 10,
              output: 50,
              read: 1,
              write: 12.5
            }],
            anthropic: [{
              id: 'claude-sonnet-5-5',
              name: 'Claude Sonnet 5.5',
              input: 2,
              output: 10,
              read: .2,
              write: 2.5,
              writeHour: 4
            }, {
              id: 'claude-opus-5-5',
              name: 'Claude Opus 5.5',
              input: 4,
              output: 20,
              read: .2,
              write: 5,
              writeHour: 8
            }, {
              id: 'claude-haiku-4-5',
              name: 'Claude Haiku 4.5',
              input: 1,
              output: 5,
              read: .1,
              write: 1.25,
              writeHour: 2
            }, {
              id: 'claude-sonnet-5',
              name: 'Claude Sonnet 5',
              input: 2,
              output: 10,
              read: .2,
              write: 2.5,
              writeHour: 4
            }, {
              id: 'claude-sonnet-4-6',
              name: 'Claude Sonnet 4.6',
              input: 3,
              output: 15,
              read: .3,
              write: 3.75,
              writeHour: 6
            }, {
              id: 'claude-opus-5',
              name: 'Claude Opus 5',
              input: 5,
              output: 25,
              read: .5,
              write: 6.25,
              writeHour: 10
            }],
            google: [{
              id: 'gemini-3.8-flash',
              name: 'Gemini 3.8 Flash',
              input: .75,
              output: 3.75,
              read: .075,
              write: 0,
              validUntil: '2026-12-31',
              future: {
                input: 1.5,
                output: 7.5,
                read: .15
              }
            }, {
              id: 'gemini-3.1-flash-lite',
              name: 'Gemini 3.1 Flash-Lite',
              input: .25,
              output: 1.5,
              read: .025,
              write: 0
            }]
          };
          var validCount = function validCount(x) {
            return typeof x === 'number' && Number.isFinite(x) && x >= 0;
          };
          var zero = function zero(x) {
            return validCount(x) ? x : 0;
          };
          function prices(provider, model) {
            var now = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : new Date();
            var m = (CATALOG[provider] || []).find(function (m) {
              return m.id === model || model.startsWith(m.id + '-20');
            });
            if (!m) return null;
            var p = _objectSpread(_objectSpread({}, m), {}, {
              source: SOURCES[provider],
              verified: '2026-10-06'
            });
            if (m.future && now.toISOString().slice(0, 10) > m.validUntil) Object.assign(p, m.future);
            return p;
          }
          function usage(provider, response) {
            var u = provider === 'google' ? response.usageMetadata : response.usage;
            if (!u) return null;
            var input,
              output,
              thinking = null,
              read = 0,
              write = 0,
              writeHour = 0,
              regular;
            if (provider === 'openai') {
              var _u$input_tokens_detai, _u$input_tokens_detai2, _u$output_tokens_deta;
              input = u.input_tokens;
              output = u.output_tokens;
              read = zero((_u$input_tokens_detai = u.input_tokens_details) === null || _u$input_tokens_detai === void 0 ? void 0 : _u$input_tokens_detai.cached_tokens);
              write = zero((_u$input_tokens_detai2 = u.input_tokens_details) === null || _u$input_tokens_detai2 === void 0 ? void 0 : _u$input_tokens_detai2.cache_write_tokens);
              thinking = validCount((_u$output_tokens_deta = u.output_tokens_details) === null || _u$output_tokens_deta === void 0 ? void 0 : _u$output_tokens_deta.reasoning_tokens) ? u.output_tokens_details.reasoning_tokens : null;
              regular = validCount(input) ? Math.max(0, input - read - write) : null;
            } else if (provider === 'anthropic') {
              var _u$cache_creation, _u$output_tokens_deta2;
              regular = u.input_tokens;
              read = zero(u.cache_read_input_tokens);
              write = zero(u.cache_creation_input_tokens);
              writeHour = zero((_u$cache_creation = u.cache_creation) === null || _u$cache_creation === void 0 ? void 0 : _u$cache_creation.ephemeral_1h_input_tokens);
              write = Math.max(0, write - writeHour);
              input = validCount(regular) ? regular + read + write + writeHour : null;
              output = u.output_tokens;
              if (validCount((_u$output_tokens_deta2 = u.output_tokens_details) === null || _u$output_tokens_deta2 === void 0 ? void 0 : _u$output_tokens_deta2.thinking_tokens)) thinking = u.output_tokens_details.thinking_tokens;else if (validCount(u.thinking_tokens)) thinking = u.thinking_tokens;
            } else if (provider === 'google') {
              input = u.promptTokenCount;
              read = zero(u.cachedContentTokenCount);
              thinking = zero(u.thoughtsTokenCount);
              if (validCount(u.candidatesTokenCount)) output = u.candidatesTokenCount + thinking;else if (validCount(u.totalTokenCount) && validCount(input)) output = Math.max(0, u.totalTokenCount - input - zero(u.toolUsePromptTokenCount));else output = null;
              regular = validCount(input) ? Math.max(0, input - read) : null;
            }
            if (!validCount(input) || !validCount(output)) return null;
            return {
              input: input,
              output: output,
              thinking: thinking,
              cacheRead: read,
              cacheWrite: write + writeHour,
              write5m: write,
              writeHour: writeHour,
              regularInput: regular,
              total: input + output,
              raw: u
            };
          }
          function cost(tokens, p) {
            if (!tokens || !p) return null;
            var needed = ['input', 'output'];
            if (tokens.cacheRead) needed.push('read');
            if (tokens.write5m) needed.push('write');
            if (tokens.writeHour) needed.push('writeHour');
            if (!needed.every(function (k) {
              return validCount(p[k]);
            })) return null;
            var input = tokens.regularInput * p.input / 1e6,
              output = tokens.output * p.output / 1e6,
              cacheRead = tokens.cacheRead * (p.read || 0) / 1e6,
              cacheWrite = (tokens.write5m * (p.write || 0) + tokens.writeHour * (p.writeHour || 0)) / 1e6;
            return {
              usd: input + output + cacheRead + cacheWrite,
              input: input,
              output: output,
              cacheRead: cacheRead,
              cacheWrite: cacheWrite
            };
          }
          function response(provider, data) {
            var text = '',
              truncated = false,
              finish = '';
            if (provider === 'openai') {
              var _data$incomplete_deta;
              text = typeof data.output_text === 'string' ? data.output_text : (data.output || []).filter(function (x) {
                return x.type === 'message';
              }).reduce(function (a, x) {
                return a.concat(x.content || []);
              }, []).filter(function (x) {
                return x.type === 'output_text';
              }).map(function (x) {
                return x.text || '';
              }).join('\n');
              truncated = data.status === 'incomplete';
              finish = ((_data$incomplete_deta = data.incomplete_details) === null || _data$incomplete_deta === void 0 ? void 0 : _data$incomplete_deta.reason) || data.status || '';
            } else if (provider === 'anthropic') {
              text = (data.content || []).filter(function (x) {
                return x.type === 'text';
              }).map(function (x) {
                return x.text || '';
              }).join('\n');
              truncated = data.stop_reason === 'max_tokens';
              finish = data.stop_reason || '';
            } else if (provider === 'google') {
              var _data$candidates, _c$content, _data$promptFeedback;
              var c = (_data$candidates = data.candidates) === null || _data$candidates === void 0 ? void 0 : _data$candidates[0];
              text = ((c === null || c === void 0 || (_c$content = c.content) === null || _c$content === void 0 ? void 0 : _c$content.parts) || []).filter(function (x) {
                return !x.thought && typeof x.text === 'string';
              }).map(function (x) {
                return x.text;
              }).join('\n');
              truncated = (c === null || c === void 0 ? void 0 : c.finishReason) === 'MAX_TOKENS';
              finish = (c === null || c === void 0 ? void 0 : c.finishReason) || ((_data$promptFeedback = data.promptFeedback) === null || _data$promptFeedback === void 0 ? void 0 : _data$promptFeedback.blockReason) || '';
            }
            return {
              text: text,
              truncated: truncated,
              finish: finish,
              tokens: usage(provider, data),
              model: data.model || data.modelVersion || null
            };
          }
          function sanitize(text) {
            var secrets = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
            var s = String(text || '');
            var _iterator16 = _createForOfIteratorHelper(secrets),
              _step16;
            try {
              for (_iterator16.s(); !(_step16 = _iterator16.n()).done;) {
                var secret = _step16.value;
                if (secret && secret.length > 3) s = s.split(secret).join('[Schlüssel entfernt]');
              }
            } catch (err) {
              _iterator16.e(err);
            } finally {
              _iterator16.f();
            }
            return s;
          }
          var api = {
            prices: prices,
            usage: usage,
            cost: cost,
            response: response,
            sanitize: sanitize
          };
          if (typeof module !== 'undefined' && module.exports) module.exports = api;
          root.CompactAI = api;
        })(scope);
        (function (root) {
          'use strict';

          function parse(xml) {
            var tokens = String(xml).match(/<!--[\s\S]*?-->|<\?[\s\S]*?\?>|<!DOCTYPE[\s\S]*?(?:\]>|>)|<!\[CDATA\[[\s\S]*?\]\]>|<(?:"[^"]*"|'[^']*'|[^'">])*?>|[^<]+/g) || [],
              stack = [],
              top = null;
            if (tokens.join('') !== xml) throw Error('MusicXML konnte nicht gelesen werden.');
            tokens.forEach(function (t) {
              if (/^<\?|^<!DOCTYPE/.test(t)) return;
              if (/^<\//.test(t)) {
                var node = stack.pop();
                if (!node || node.name !== t.slice(2, -1).trim()) throw Error('MusicXML-Klammern passen nicht.');
                node.close = t;
                return;
              }
              if (/^<[A-Za-z]/.test(t)) {
                var name = /^<([^\s/>]+)/.exec(t)[1],
                  n = {
                    name: name,
                    open: t,
                    close: '',
                    children: []
                  };
                if (stack.length) stack[stack.length - 1].children.push(n);else if (!top) top = n;else throw Error('Mehrere XML-Wurzeln.');
                if (!/\/>$/.test(t)) stack.push(n);
              } else if (stack.length) stack[stack.length - 1].children.push(t);
            });
            if (stack.length || !top || top.name !== 'score-partwise') throw Error('MusicXML score-partwise wird benötigt.');
            return top;
          }
          function serialize(n) {
            return typeof n === 'string' ? n : n.open + n.children.map(serialize).join('') + n.close;
          }
          function children(n, name) {
            return n.children.filter(function (x) {
              return typeof x !== 'string' && x.name === name;
            });
          }
          function first(n, name) {
            return children(n, name)[0];
          }
          function text(n, name, def) {
            var x = first(n, name);
            return x ? x.children.filter(function (x) {
              return typeof x === 'string';
            }).join('').trim() : def;
          }
          function clone(n) {
            return JSON.parse(JSON.stringify(n));
          }
          function attrs(n) {
            return first(n, 'attributes');
          }
          function value(s) {
            var v = 0;
            String(s).split('+').forEach(function (x) {
              v += Number(x);
            });
            return v;
          }
          function timeline(part) {
            var division = 1,
              meter = 4,
              time = '<time><beats>4</beats><beat-type>4</beat-type></time>',
              key = '<key><fifths>0</fifths></key>',
              staves = 1,
              transpose = null,
              start = 0,
              rows = [];
            children(part, 'measure').forEach(function (m) {
              var cursor = 0,
                maximum = 0;
              m.children.forEach(function (n) {
                if (typeof n === 'string') return;
                if (n.name === 'attributes') {
                  division = Number(text(n, 'divisions', division));
                  if (!division || !isFinite(division)) throw Error('Ungültige MusicXML-divisions.');
                  staves = Number(text(n, 'staves', staves));
                  var t = first(n, 'time');
                  if (t) {
                    var bs = children(t, 'beats'),
                      bt = children(t, 'beat-type');
                    if (!bs.length || bs.length !== bt.length) throw Error('Taktart ohne feste Taktlänge ist noch nicht unterstützt.');
                    meter = 0;
                    bs.forEach(function (b, i) {
                      meter += value(text({
                        children: [b]
                      }, 'beats', 4)) * 4 / Number(text({
                        children: [bt[i]]
                      }, 'beat-type', 4));
                    });
                    time = serialize(t);
                  }
                  var k = first(n, 'key');
                  if (k) key = serialize(k);
                  var tr = first(n, 'transpose');
                  if (tr) transpose = clone(tr);
                }
                if (n.name === 'note' && !first(n, 'chord') && !first(n, 'grace')) cursor += Number(text(n, 'duration', 0)) / division;
                if (n.name === 'backup') cursor -= Number(text(n, 'duration', 0)) / division;
                if (n.name === 'forward') cursor += Number(text(n, 'duration', 0)) / division;
                maximum = Math.max(maximum, cursor);
              });
              var length = /\bimplicit=["']yes["']/.test(m.open) && maximum > 0 ? maximum : Math.max(meter, maximum);
              rows.push({
                node: m,
                start: start,
                length: length,
                division: division,
                time: time,
                key: key,
                staves: staves,
                transpose: transpose
              });
              start += length;
            });
            return {
              rows: rows,
              end: start
            };
          }
          function inspect(xml, startQuarter) {
            var doc = parse(xml),
              parts = children(doc, 'part');
            if (!parts.length) throw Error('Ausgangspartitur enthält keine Parts.');
            var t = timeline(parts[0]),
              index = t.rows.length,
              prefix = 0;
            for (var i = 0; i < t.rows.length; i++) if (startQuarter < t.rows[i].start + t.rows[i].length - 1e-7) {
              index = i;
              prefix = Math.max(0, startQuarter - t.rows[i].start);
              break;
            }
            if (startQuarter > t.end + 1e-7) throw Error('Einfügeposition liegt hinter dem Partiturende.');
            var row = t.rows[Math.min(index, t.rows.length - 1)];
            function signature(r) {
              var t = first(parse('<score-partwise><part-list/><part id="x"><measure number="1"><attributes>' + r.time + '</attributes></measure></part></score-partwise>'), 'part');
              var a = attrs(children(t, 'measure')[0]),
                time = first(a, 'time');
              return text(time, 'beats', 4) + '/' + text(time, 'beat-type', 4);
            }
            return {
              startMeasure: index + 1,
              prefixQuarter: prefix,
              end: t.end,
              time: row ? row.time : '<time><beats>4</beats><beat-type>4</beat-type></time>',
              timeSignature: row ? signature(row) : '4/4',
              meters: t.rows.map(function (r, i) {
                return {
                  measure: i + 1,
                  timeSignature: signature(r),
                  quarters: r.length
                };
              }),
              key: row ? row.key : '',
              parts: parts.length
            };
          }
          function gcd(a, b) {
            while (b) {
              var c = a % b;
              a = b;
              b = c;
            }
            return a;
          }
          function lcm(a, b) {
            return a / gcd(a, b) * b;
          }
          function blank(row, number, initial, division, staves) {
            var content = '<attributes><divisions>' + division + '</divisions>' + row.key + row.time + (initial ? '<staves>' + staves + '</staves>' : '') + '</attributes>',
              duration = row.length * division;
            if (Math.abs(duration - Math.round(duration)) > 1e-5) throw Error('Leertakt kann rhythmisch nicht exakt abgebildet werden.');
            duration = Math.round(duration);
            for (var s = 1; s <= staves; s++) {
              if (s > 1) content += '<backup><duration>' + duration + '</duration></backup>';
              content += '<note><rest measure="yes"/><duration>' + duration + '</duration><voice>' + s + '</voice><staff>' + s + '</staff></note>';
            }
            return first(parse('<score-partwise><part-list/><part id="x"><measure number="' + number + '">' + content + '</measure></part></score-partwise>'), 'part').children.filter(function (n) {
              return n.name === 'measure';
            })[0];
          }
          function renumber(m, n) {
            m.open = m.open.replace(/\bnumber\s*=\s*("[^"]*"|'[^']*')/, 'number="' + n + '"');
          }
          function regularEnd(part) {
            var measures = children(part, 'measure'),
              last = measures[measures.length - 1];
            if (!last) return;
            children(last, 'barline').forEach(function (b) {
              var style = first(b, 'bar-style');
              if (style && text(b, 'bar-style', '') === 'light-heavy') style.children = ['regular'];
            });
          }
          function transposePart(part, tr) {
            if (!tr) return;
            var oct = Number(text(tr, 'octave-change', 0)),
              chromatic = Number(text(tr, 'chromatic', 0)),
              diatonic = Number(text(tr, 'diatonic', NaN));
            if (!isFinite(diatonic)) {
              var sign = chromatic < 0 ? -1 : 1;
              diatonic = sign * [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6][Math.abs(chromatic) % 12] + Math.trunc(chromatic / 12) * 7;
            }
            var delta = -chromatic - oct * 12,
              dia = -diatonic - oct * 7,
              steps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
              semitones = [0, 2, 4, 5, 7, 9, 11];
            function mod(x, n) {
              return (x % n + n) % n;
            }
            function leaf(name, v) {
              return {
                name: name,
                open: '<' + name + '>',
                close: '</' + name + '>',
                children: [String(v)]
              };
            }
            children(part, 'measure').forEach(function (m, mi) {
              var a = attrs(m);
              if (a) {
                var k = first(a, 'key');
                if (k && first(k, 'fifths')) {
                  var old = Number(text(k, 'fifths', 0)),
                    needed = mod(4 * old + dia, 7),
                    choices = [];
                  for (var f = -14; f <= 14; f++) if (mod(f * 7 - old * 7, 12) === mod(delta, 12) && mod(4 * f, 7) === needed) choices.push(f);
                  choices.sort(function (x, y) {
                    return Math.abs(x) - Math.abs(y);
                  });
                  if (!choices.length) throw Error('Transponierte Tonart nicht darstellbar.');
                  first(k, 'fifths').children = [String(choices[0])];
                }
                if (mi === 0) a.children.push(clone(tr));
              }
              children(m, 'note').forEach(function (n) {
                var p = first(n, 'pitch');
                if (!p) return;
                var i = steps.indexOf(text(p, 'step', 'C')),
                  o = Number(text(p, 'octave', 4)),
                  alter = Number(text(p, 'alter', 0)),
                  midi = (o + 1) * 12 + semitones[i] + alter + delta,
                  di = o * 7 + i + dia,
                  no = Math.floor(di / 7),
                  ni = mod(di, 7),
                  na = midi - (no + 1) * 12 - semitones[ni];
                p.children = [leaf('step', steps[ni])];
                if (na) p.children.push(leaf('alter', na));
                p.children.push(leaf('octave', no));
              });
            });
          }
          function checkPrefix(part, quarter) {
            if (quarter <= 1e-7) return;
            var m = children(part, 'measure')[0],
              division = 1,
              cursor = 0;
            m.children.forEach(function (n) {
              if (typeof n === 'string') return;
              if (n.name === 'attributes') division = Number(text(n, 'divisions', division));
              if (n.name === 'backup') cursor -= Number(text(n, 'duration', 0)) / division;
              if (n.name === 'forward') cursor += Number(text(n, 'duration', 0)) / division;
              if (n.name === 'note') {
                if (first(n, 'pitch') && !first(n, 'chord') && cursor < quarter - 1e-7) throw Error('CS1 beginnt vor dem Auswahlbeginn. Im ersten Takt fehlen die vorgegebenen Anfangspausen.');
                if (!first(n, 'chord') && !first(n, 'grace')) cursor += Number(text(n, 'duration', 0)) / division;
              }
            });
          }
          function combine(baseXML, addedXML, options) {
            var base = parse(baseXML),
              added = parse(addedXML),
              baseParts = children(base, 'part'),
              newParts = children(added, 'part'),
              baseList = first(base, 'part-list'),
              newList = first(added, 'part-list');
            if (!baseList || !newList || !baseParts.length || !newParts.length) throw Error('MusicXML-Partstruktur fehlt.');
            var start = Number(options.startQuarter || 0),
              info = inspect(baseXML, start),
              index = info.startMeasure - 1,
              baseTime = timeline(baseParts[0]),
              addTime = timeline(newParts[0]),
              rows = baseTime.rows.slice(0),
              warnings = [];
            if (options.kind === 'append' && Math.abs(start - baseTime.end) > 1e-7) throw Error('Fortsetzen muss am Partiturende beginnen.');
            if (options.kind === 'append' && baseParts.length !== newParts.length) throw Error('Fortsetzung muss dieselbe Anzahl Instrumente enthalten.');
            while (rows.length < index + addTime.rows.length) {
              var a = addTime.rows[rows.length - index];
              rows.push({
                start: rows.length ? rows[rows.length - 1].start + rows[rows.length - 1].length : 0,
                length: a.length,
                time: a.time,
                key: a.key,
                division: a.division
              });
            }
            addTime.rows.forEach(function (r, i) {
              if (Math.abs(r.length - rows[index + i].length) > 1e-7) throw Error('CS1-Takt ' + (i + 1) + ' passt zeitlich nicht zu Takt ' + (index + i + 1) + ' der Ausgangspartitur. Bitte Taktart und Taktlänge prüfen.');
            });
            newParts.forEach(function (p) {
              checkPrefix(p, info.prefixQuarter);
            });
            if (options.kind === 'append') {
              baseParts.forEach(function (p, i) {
                regularEnd(p);
                var old = timeline(p),
                  extra = children(newParts[i], 'measure');
                if (old.rows.length !== index) throw Error('Ausgangsparts haben unterschiedliche Taktzahlen.');
                transposePart(newParts[i], old.rows[old.rows.length - 1].transpose);
                extra = children(newParts[i], 'measure');
                var sourceStaves = old.rows.length ? old.rows[old.rows.length - 1].staves : 1,
                  newStaves = timeline(newParts[i]).rows[0].staves;
                if (sourceStaves !== newStaves) throw Error('Fortsetzung hat eine andere Anzahl Notensysteme.');
                extra.forEach(function (m, k) {
                  var c = clone(m);
                  renumber(c, index + k + 1);
                  p.children.push(c);
                });
              });
            } else {
              baseParts.forEach(function (p) {
                var t = timeline(p),
                  last = t.rows[t.rows.length - 1];
                if (t.rows.length !== baseTime.rows.length) throw Error('Ausgangsparts haben unterschiedliche Taktzahlen.');
                if (rows.length > t.rows.length) regularEnd(p);
                for (var i = t.rows.length; i < rows.length; i++) p.children.push(blank(rows[i], i + 1, false, lcm(last.division, rows[i].division), last.staves));
              });
              newParts.forEach(function (p, i) {
                var id = 'CS' + (i + 1),
                  suffix = 1,
                  existing = serialize(baseList);
                while (existing.indexOf('id="' + id + '"') >= 0) id = 'CS' + (i + 1) + '_' + ++suffix;
                var definition = clone(children(newList, 'score-part')[i]);
                if (!definition) throw Error('Neue Instrumentdefinition fehlt.');
                var oldID = /\bid=["']([^"']+)["']/.exec(p.open)[1];
                function changeIDs(n) {
                  if (typeof n === 'string') return;
                  n.open = n.open.replace(/\b(id|idref)=("([^"]*)"|'([^']*)')/g, function (all, name, quoted, a, b) {
                    var v = a || b;
                    return name + '="' + (v === oldID ? id : id + '-' + v) + '"';
                  });
                  n.children.forEach(changeIDs);
                }
                changeIDs(definition);
                var used = serialize(baseList),
                  channel = 1;
                while (channel <= 16 && (channel === 10 || new RegExp('<midi-channel>\\s*' + channel + '\\s*</midi-channel>').test(used))) channel++;
                children(definition, 'midi-instrument').forEach(function (ins) {
                  var c = first(ins, 'midi-channel');
                  if (c && channel <= 16) c.children = [String(channel)];
                });
                baseList.children.push(definition);
                var np = clone(p);
                changeIDs(np);
                var original = children(np, 'measure'),
                  t = timeline(p),
                  division = t.rows[0].division,
                  staves = t.rows[0].staves;
                if (index + original.length < rows.length) regularEnd(np);
                rows.forEach(function (r) {
                  division = lcm(division, r.division);
                });
                if (division > 10000000) throw Error('Kontext-Auflösung ist zu groß.');
                np.children = [];
                for (var k = 0; k < rows.length; k++) {
                  if (k >= index && k < index + original.length) {
                    var m = original[k - index];
                    renumber(m, k + 1);
                    np.children.push(m);
                  } else np.children.push(blank(rows[k], k + 1, k === 0, division, staves));
                }
                if (index > 0) {
                  var init = attrs(original[0]),
                    target = attrs(children(np, 'measure')[0]);
                  children(init, 'clef').forEach(function (c) {
                    target.children.push(clone(c));
                  });
                }
                base.children.push(np);
              });
            }
            warnings.push('Die kombinierte Fassung wird als neue Partitur geöffnet. Das Original bleibt erhalten; MuseScore-spezifisches Layout kann sich durch MusicXML ändern.');
            return {
              xml: '<?xml version="1.0" encoding="UTF-8"?>\n' + serialize(base),
              warnings: warnings
            };
          }
          var api = {
            parse: parse,
            inspect: inspect,
            combine: combine
          };
          if (typeof module !== 'undefined' && module.exports) module.exports = api;
          root.CompactContext = api;
        })(scope);
        return {
          score: scope.CompactScore,
          xml: scope.CompactMusicXML,
          ai: scope.CompactAI,
          context: scope.CompactContext
        };
    }
    // END COMPACTSCORE RUNTIME

    function currentVersionString() {
        if (hotAppActive && hotAppVersion !== "")
            return hotAppVersion
        return root.version
    }

    function versionParts(v) {
        var raw = String(v || "").replace(/^v/i, "").split(".")
        var out = []
        for (var i = 0; i < 3; i++) {
            var n = i < raw.length ? parseInt(raw[i], 10) : 0
            out.push(isNaN(n) ? 0 : n)
        }
        return out
    }

    function compareVersions(a, b) {
        var av = versionParts(a)
        var bv = versionParts(b)
        for (var i = 0; i < 3; i++) {
            if (av[i] < bv[i]) return -1
            if (av[i] > bv[i]) return 1
        }
        return 0
    }

    function updateRawUrl() {
        return "https://raw.githubusercontent.com/wibem1/AI-Notation-Studio/main/AI-Notation-Studio.qml?ts=" +
               new Date().getTime()
    }

    function updateHotAppUrl() {
        return "https://raw.githubusercontent.com/wibem1/AI-Notation-Studio/main/AI-Notation-Studio-App.qml?ts=" +
               new Date().getTime()
    }

    function extractPluginVersion(text) {
        var m = String(text || "").match(/version\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"/)
        return m && m.length > 1 ? m[1] : ""
    }

    function validateUpdateSource(text) {
        if (!text || text.length < 1000) return false
        if (text.indexOf("import MuseScore 3.0") < 0) return false
        if (text.indexOf("MuseScore {") < 0) return false
        if (text.indexOf("AI Notation Studio") < 0) return false
        return extractPluginVersion(text) !== ""
    }

    function acceptFetchedUpdate(source, isHotApp) {
        if (!validateUpdateSource(source)) {
            updateStatus = "Update abgebrochen: GitHub-Datei ist keine gültige AI-Notation-Studio-Version."
            return
        }

        var remote = extractPluginVersion(source)
        updateRemoteVersion = remote
        updateIsHotApp = isHotApp

        var cmp = compareVersions(currentVersionString(), remote)
        if (cmp < 0) {
            updateSourceText = source
            updateStatus = "Neue Version verfügbar: lokal v" + currentVersionString() +
                           " → GitHub v" + remote + (isHotApp ? " · Live-Update" : "")
        } else if (cmp === 0) {
            updateStatus = "Aktuell: lokal v" + currentVersionString() + " · GitHub v" + remote
        } else {
            updateStatus = "Installiert v" + currentVersionString() + " ist neuer als GitHub v" + remote + "."
        }
    }

    function requestLegacyUpdateFallback() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", updateRawUrl())
        try {
            xhr.setRequestHeader("Cache-Control", "no-cache")
            xhr.setRequestHeader("Pragma", "no-cache")
        } catch (ignoreHeaders) {}

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            updateBusy = false

            if (xhr.status < 200 || xhr.status >= 300) {
                updateStatus = "Update-Prüfung fehlgeschlagen: HTTP " + xhr.status
                return
            }
            acceptFetchedUpdate(xhr.responseText, false)
        }

        try {
            xhr.send()
        } catch (e) {
            updateBusy = false
            updateStatus = "Update-Prüfung fehlgeschlagen: " + e
        }
    }

    function checkForUpdate() {
        if (updateBusy) return
        updateBusy = true
        updateRemoteVersion = ""
        updateSourceText = ""
        updateIsHotApp = false
        updateStatus = "Prüfe auf Update …"

        // Ab v0.8.0 liegt die eigentliche App in einer getrennten, live ladbaren Datei.
        // Solange diese Datei noch nicht veröffentlicht ist, fällt der Updater auf
        // die bisherige monolithische Plugin-Datei zurück.
        var xhr = new XMLHttpRequest()
        xhr.open("GET", updateHotAppUrl())
        try {
            xhr.setRequestHeader("Cache-Control", "no-cache")
            xhr.setRequestHeader("Pragma", "no-cache")
        } catch (ignoreHeaders) {}

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || finished) return
            finished = true

            if (xhr.status >= 200 && xhr.status < 300 && validateUpdateSource(xhr.responseText)) {
                updateBusy = false
                acceptFetchedUpdate(xhr.responseText, true)
                return
            }

            requestLegacyUpdateFallback()
        }

        try {
            xhr.send()
        } catch (e) {
            requestLegacyUpdateFallback()
        }
    }

    function resolvedCurrentPluginSource() {
        try {
            var u = String(Qt.resolvedUrl("AI-Notation-Studio.qml"))
            return u || ""
        } catch (e) {
            return ""
        }
    }

    function fileUrlToLocalPath(urlText) {
        var s = String(urlText || "")
        if (!/^file:/i.test(s)) return s.replace(/\\/g, "/")
        s = s.substring(5).replace(/\\/g, "/")
        if (/^\/\/localhost\//i.test(s)) s = s.substring(11)
        else if (s.indexOf("///") === 0) s = s.substring(2)
        else if (/^\/\/[A-Za-z]:\//.test(s)) s = s.substring(2)
        if (/^\/[A-Za-z]:\//.test(s)) s = s.substring(1)
        try { s = decodeURIComponent(s) } catch (ignoreDecode) {}
        return s
    }

    function localPathToFileUrl(pathText) {
        var s = String(pathText || "").replace(/\\/g, "/")
        var escaped = encodeURI(s).replace(/#/g, "%23").replace(/\?/g, "%3F")
        if (/^[A-Za-z]:\//.test(s)) return "file:///" + escaped
        if (s.indexOf("//") === 0) return "file:" + escaped
        if (s.indexOf("/") === 0) return "file://" + escaped
        return String(Qt.resolvedUrl(s))
    }

    function normalizedAppUrl(sourceUrl) {
        var s = String(sourceUrl || "")
        if (/^file:/i.test(s)) return localPathToFileUrl(fileUrlToLocalPath(s))
        if (/^[A-Za-z]:[\\/]/.test(s) || /^[\\/]/.test(s)) return localPathToFileUrl(s)
        return s
    }

    function resolvePluginTargetPath() {
        // Primär: QML-eigene Auflösung relativ zur aktuell laufenden Plugin-Datei.
        // Das funktioniert auch in MuseScore 4.4–4.6, wo die neueren FileIO-
        // Pfadmethoden noch nicht existieren.
        var currentSource = resolvedCurrentPluginSource()
        if (currentSource !== "")
            return currentSource

        var dir = ""

        // Neuere MuseScore/FileIO-Versionen.
        if (typeof updaterFile.pluginDirectoryPath === "function") {
            try { dir = updaterFile.pluginDirectoryPath() } catch (e1) { dir = "" }
        }

        if ((!dir || dir === "") && typeof updaterFile.pluginsUserPath === "function") {
            try { dir = updaterFile.pluginsUserPath() } catch (e2) { dir = "" }
        }

        if ((!dir || dir === "") && typeof updaterFile.userDataPath === "function") {
            try {
                var dataDir = updaterFile.userDataPath()
                if (dataDir && dataDir !== "")
                    dir = dataDir + "/Plugins"
            } catch (e3) { dir = "" }
        }

        if (!dir || dir === "")
            return ""

        return dir + "/AI-Notation-Studio.qml"
    }

    function installUpdate() {
        if (updateSourceText === "" || updateRemoteVersion === "") {
            updateStatus = "Kein neues Update zum Installieren."
            return
        }

        updateStatus = "Installiere v" + updateRemoteVersion + " …"

        try {
            if (updateIsHotApp) {
                var fileName = "AI-Notation-Studio-App-" + updateRemoteVersion + ".qml"
                var hotTarget = siblingPluginUrl(fileName)
                if (!hotTarget || hotTarget === "") {
                    updateStatus = "Live-Update fehlgeschlagen: Zielpfad konnte nicht bestimmt werden."
                    return
                }

                updaterFile.source = fileUrlToLocalPath(hotTarget)
                var hotOk = updaterFile.write(updateSourceText)
                if (!hotOk) {
                    updateStatus = "Live-Update fehlgeschlagen: App-Datei konnte nicht geschrieben werden."
                    return
                }

                var hotVerify = updaterFile.read()
                var hotVersion = extractPluginVersion(hotVerify)
                if (hotVersion !== updateRemoteVersion) {
                    updateStatus = "Live-Update fehlgeschlagen: Nachkontrolle meldet v" + hotVersion +
                                   " statt v" + updateRemoteVersion + "."
                    return
                }

                if (!activateHotApp(hotTarget, updateRemoteVersion))
                    return

                updateSourceText = ""
                updateStatus = "v" + updateRemoteVersion +
                               " installiert, geprüft und live aktiviert. Kein MuseScore-Neustart erforderlich."
                return
            }

            var target = resolvePluginTargetPath()
            if (!target || target === "") {
                updateStatus = "Update fehlgeschlagen: laufende Plugin-Datei konnte nicht aufgelöst werden."
                return
            }

            updaterTargetPath = target

            if (typeof updaterFile.isPathWriteable === "function") {
                var writablePath = fileUrlToLocalPath(target)
                var writable = updaterFile.isPathWriteable(writablePath)
                if (!writable) {
                    updateStatus = "Update fehlgeschlagen: MuseScore darf diese Datei nicht schreiben. Pfad: " + target
                    return
                }
            }

            updaterFile.source = target

            var ok = updaterFile.write(updateSourceText)
            if (!ok) {
                updateStatus = "Update fehlgeschlagen: Datei konnte nicht geschrieben werden. Pfad: " + target
                return
            }

            var verifyText = updaterFile.read()
            var verifyVersion = extractPluginVersion(verifyText)
            if (verifyVersion !== updateRemoteVersion) {
                updateStatus = "Update fehlgeschlagen: Nachkontrolle meldet v" + verifyVersion +
                               " statt v" + updateRemoteVersion + ". Pfad: " + target
                return
            }

            updateStatus = "v" + updateRemoteVersion +
                           " installiert und geprüft. Für diese Übergangsversion MuseScore einmal neu starten."
            updateSourceText = ""
        } catch (e) {
            updateStatus = "Update-Fehler: " + e
        }
    }



    function siblingPluginUrl(fileName) {
        var current = resolvedCurrentPluginSource()
        if (!current || current === "") return ""
        var slash = current.lastIndexOf("/")
        if (slash < 0) return ""
        return current.substring(0, slash + 1) + fileName
    }

    function activateHotApp(sourceUrl, versionText) {
        if (!sourceUrl || sourceUrl === "") {
            updateStatus = "Live-Aktivierung fehlgeschlagen: App-Datei fehlt."
            return false
        }

        sourceUrl = normalizedAppUrl(sourceUrl)
        settings.activeHotAppSource = sourceUrl
        settings.activeHotAppVersion = versionText || ""
        hotAppVersion = versionText || ""
        hotAppActive = false
        hotAppRequested = false
        updateStatus = "Live-App wird geladen …"

        // Andere URL => neue QML-Komponente statt MuseScores gecachter Plugin-Komponente.
        hotAppLoader.source = ""
        hotAppLoader.source = sourceUrl
        hotAppRequested = true
        return true
    }

    function restoreAfterAppFailure(message) {
        hotAppActive = false
        updateStatus = message
        var failedSource = String(hotAppLoader.source)
        // Defer deactivation: Loader can report an error while its active binding is evaluated.
        Qt.callLater(function() {
            if (String(hotAppLoader.source) !== failedSource) return
            hotAppRequested = false
            settings.activeHotAppSource = ""
            settings.activeHotAppVersion = ""
        })
    }

    function clearHotAppActivation() {
        settings.activeHotAppSource = ""
        settings.activeHotAppVersion = ""
        hotAppVersion = ""
        hotAppActive = false
        hotAppRequested = false
        hotAppLoader.source = ""
    }

    function scoreMemoryTagName() {
        return "AI-Notation-Studio-Memory-v1"
    }

    function saveGeneralDefaults() {
        if (restoringMemory) return
        settings.defaultModeIndex = modeBox.currentIndex
        settings.defaultInstruction = instructionBox.text
        settings.defaultFreeInstrumentation = freeInstrumentation
        settings.defaultFreeMeasures = freeMeasures
        settings.defaultInstrumentIndex = instrumentBox.currentIndex
        settings.defaultChatModeIndex = chatModeIndex
        settings.defaultChatExpanded = chatExpanded
        settings.defaultTechnicalExpanded = technicalExpanded
    }

    function restoreGeneralDefaults() {
        restoringMemory = true
        modeBox.currentIndex = Math.max(0, Math.min(modeBox.count - 1, settings.defaultModeIndex))
        instructionBox.text = settings.defaultInstruction || ""
        freeInstrumentation = settings.defaultFreeInstrumentation || "Violine, Cello"
        freeMeasures = Number(settings.defaultFreeMeasures || 16)
        instrumentBox.currentIndex = Math.max(0, Math.min(instrumentBox.count - 1, settings.defaultInstrumentIndex))
        chatModeIndex = Number(settings.defaultChatModeIndex || 0)
        chatExpanded = settings.defaultChatExpanded ? true : false
        technicalExpanded = settings.defaultTechnicalExpanded ? true : false
        restoringMemory = false
    }

    function currentScoreMemoryObject() {
        return {
            schema: 1,
            pluginVersion: root.version,
            savedAt: new Date().toISOString(),
            notes: scoreMemoryNotes,
            instruction: instructionBox.text,
            modeIndex: modeBox.currentIndex,
            freeInstrumentation: freeInstrumentation,
            freeMeasures: freeMeasures,
            instrumentIndex: instrumentBox.currentIndex,
            chatModeIndex: chatModeIndex,
            chatMessages: chatMessages,
            musicalDraft: musicalDraft,
            compositionJson: compositionJson,
            compactSourceText: compactSourceText,
            compositionJob: compositionJob, compositionIdea: compositionIdea,
            ideaReady: ideaReady, compositionCosts: compositionCosts
        }
    }

    function saveScoreMemory(silent) {
        if (!curScore) {
            if (!silent) statusText = "Kein Score geöffnet."
            return false
        }

        try {
            curScore.setMetaTag(scoreMemoryTagName(), JSON.stringify(currentScoreMemoryObject()))
            if (!silent)
                statusText = "Score-Gedächtnis aktualisiert. Bitte den Score speichern, damit es dauerhaft in der Datei bleibt."
            return true
        } catch (e) {
            if (!silent) statusText = "Score-Gedächtnis konnte nicht gespeichert werden: " + e
            return false
        }
    }

    function loadScoreMemory(silent) {
        if (!curScore) return false

        var raw = ""
        try { raw = String(curScore.metaTag(scoreMemoryTagName()) || "") } catch (e1) { raw = "" }

        if (raw === "") {
            chatMessages = []
            scoreMemoryNotes = ""
            musicalDraft = ""
            compositionJson = ""
            compactSourceText = ""; compactWarnings = []; compositionJob = null; compositionIdea = ""; ideaReady = false; compositionCosts = []
            if (!silent) statusText = "Für diesen Score ist noch kein Score-Gedächtnis vorhanden."
            return false
        }

        try {
            var m = JSON.parse(raw)
            restoringMemory = true
            scoreMemoryNotes = String(m.notes || "")
            chatMessages = m.chatMessages && m.chatMessages.length !== undefined ? m.chatMessages : []
            musicalDraft = String(m.musicalDraft || "")
            compositionJson = String(m.compositionJson || "")
            compactSourceText = String(m.compactSourceText || "")
            compositionJob = m.compositionJob || null
            compositionIdea = String(m.compositionIdea || "")
            ideaReady = Boolean(m.ideaReady && compositionJob)
            compositionCosts = m.compositionCosts || []

            if (m.instruction !== undefined) instructionBox.text = String(m.instruction)
            if (m.modeIndex !== undefined) modeBox.currentIndex = Math.max(0, Math.min(modeBox.count - 1, Number(m.modeIndex)))
            if (m.freeInstrumentation !== undefined) freeInstrumentation = String(m.freeInstrumentation)
            if (m.freeMeasures !== undefined) freeMeasures = Number(m.freeMeasures)
            if (m.instrumentIndex !== undefined) instrumentBox.currentIndex = Math.max(0, Math.min(instrumentBox.count - 1, Number(m.instrumentIndex)))
            if (m.chatModeIndex !== undefined) chatModeIndex = Number(m.chatModeIndex)
            restoringMemory = false

            if (!silent) statusText = "Score-Gedächtnis geladen."
            return true
        } catch (e2) {
            restoringMemory = false
            if (!silent) statusText = "Score-Gedächtnis ist beschädigt oder unlesbar."
            return false
        }
    }

    function clearScoreMemory() {
        if (!curScore) {
            statusText = "Kein Score geöffnet."
            return
        }
        try {
            curScore.setMetaTag(scoreMemoryTagName(), "")
            scoreMemoryNotes = ""
            chatMessages = []
            musicalDraft = ""
            compositionJson = ""
            compactSourceText = ""; compactWarnings = []; compositionJob = null; compositionIdea = ""; ideaReady = false; compositionCosts = []
            statusText = "Score-Gedächtnis geleert. Bitte den Score speichern."
        } catch (e) {
            statusText = "Score-Gedächtnis konnte nicht geleert werden: " + e
        }
    }

    function generalMemorySummary() {
        return "Standardmodus: " + modeBox.currentText +
               "\nStandardbesetzung: " + settings.defaultFreeInstrumentation +
               "\nStandardtaktzahl: " + settings.defaultFreeMeasures +
               "\nStandardinstrument: " + instrumentBox.currentText +
               "\nChatmodus: " + (settings.defaultChatModeIndex === 0 ? "Nur besprechen" : "Änderung vorbereiten")
    }

    function providerName() {
        if (providerBox.currentIndex === 1) return "Anthropic"
        if (providerBox.currentIndex === 2) return "Google"
        return "OpenAI"
    }

    function savedKey() {
        var p = providerName()
        if (p === "Anthropic") return settings.keyAnthropic
        if (p === "Google") return settings.keyGoogle
        return settings.keyOpenAI
    }

    function saveCurrentKey() {
        var key = apiKeyBox.text.trim()
        var p = providerName()
        if (p === "Anthropic") settings.keyAnthropic = key
        else if (p === "Google") settings.keyGoogle = key
        else settings.keyOpenAI = key
    }

    function savedModel() {
        var p = providerName()
        if (p === "Anthropic") return settings.modelAnthropic
        if (p === "Google") return settings.modelGoogle
        return settings.modelOpenAI
    }

    function saveCurrentModel() {
        var m = modelBox.text.trim()
        var p = providerName()
        if (p === "Anthropic") settings.modelAnthropic = m
        else if (p === "Google") settings.modelGoogle = m
        else settings.modelOpenAI = m
    }

    function loadProviderFields() {
        apiKeyBox.text = savedKey()
        modelBox.text = savedModel()
        settings.provider = providerName()
    }

    function tpcName(tpc) {
        var names = [
            "Cbb","Gbb","Dbb","Abb","Ebb","Bbb","Fb",
            "Cb","Gb","Db","Ab","Eb","Bb","F",
            "C","G","D","A","E","B","F#",
            "C#","G#","D#","A#","E#","B#","F##",
            "C##","G##","D##","A##","E##","B##","F###"
        ]
        if (tpc >= 0 && tpc < names.length) return names[tpc]
        return "?"
    }

    function processElement(el, voice, tick) {
        if (!el) return null
        if (el.name !== "Chord" && el.name !== "Rest") return null

        var obj = {
            type: el.name,
            voice: voice,
            startTick: tick,
            durationTicks: el.actualDuration ? el.actualDuration.ticks : 0,
            tuplet: el.tuplet ? true : false
        }

        if (el.name === "Chord") {
            obj.notes = []
            var notes = el.notes || []
            for (var i = 0; i < notes.length; i++) {
                var n = notes[i]
                obj.notes.push({
                    pitchMidi: n.pitch,
                    tpc: n.tpc,
                    pitchName: tpcName(n.tpc),
                    tieForward: n.tieForward ? true : false
                })
            }
        }
        return obj
    }

    function elementTypeName(el) {
        if (!el) return "Unknown"
        if (el.name) return el.name
        return String(el.type)
    }

    function elementTick(el) {
        if (!el) return -1
        if (el.tick !== undefined) return el.tick
        if (el.parent && el.parent.tick !== undefined) return el.parent.tick
        if (el.segment && el.segment.tick !== undefined) return el.segment.tick
        return -1
    }

    function elementTrack(el) {
        if (!el) return -1
        if (el.track !== undefined) return el.track
        if (el.parent && el.parent.track !== undefined) return el.parent.track
        return -1
    }

    function serializeSelectedElement(el) {
        if (!el) return null

        var obj = {
            type: elementTypeName(el),
            tick: elementTick(el),
            track: elementTrack(el)
        }

        if (obj.track >= 0) {
            obj.staff = Math.floor(obj.track / 4)
            obj.voice = obj.track % 4
        }

        if (el.name === "Note" || obj.type === "Note") {
            obj.pitchMidi = el.pitch
            obj.tpc = el.tpc
            obj.pitchName = tpcName(el.tpc)
            obj.tieForward = el.tieForward ? true : false

            if (el.parent) {
                obj.chordTick = elementTick(el.parent)
                if (el.parent.actualDuration) {
                    obj.durationTicks = el.parent.actualDuration.ticks
                    obj.durationNumerator = el.parent.actualDuration.numerator
                    obj.durationDenominator = el.parent.actualDuration.denominator
                }
            }
        } else if (el.name === "Chord" || obj.type === "Chord") {
            obj.durationTicks = el.actualDuration ? el.actualDuration.ticks : 0
            obj.durationNumerator = el.actualDuration ? el.actualDuration.numerator : 1
            obj.durationDenominator = el.actualDuration ? el.actualDuration.denominator : 4
            obj.notes = []
            var notes = el.notes || []
            for (var i = 0; i < notes.length; i++) {
                obj.notes.push({
                    pitchMidi: notes[i].pitch,
                    tpc: notes[i].tpc,
                    pitchName: tpcName(notes[i].tpc),
                    tieForward: notes[i].tieForward ? true : false
                })
            }
        } else if (el.name === "Rest" || obj.type === "Rest") {
            obj.durationTicks = el.actualDuration ? el.actualDuration.ticks : 0
            obj.durationNumerator = el.actualDuration ? el.actualDuration.numerator : 1
            obj.durationDenominator = el.actualDuration ? el.actualDuration.denominator : 4
        }

        return obj
    }

    function readSelection() {
        if (!curScore) {
            statusText = "Keine Partitur geöffnet."
            selectionJson = ""
            return false
        }

        try {
            var selection = curScore.selection
            if (!selection) {
                statusText = "MuseScore liefert kein Auswahlobjekt."
                selectionJson = ""
                return false
            }

            var raw = selection.elements
            var count = raw ? raw.length : 0

            if (!raw || count === 0) {
                statusText = "MuseScore meldet 0 ausgewählte Elemente."
                selectionJson = ""
                return false
            }

            var data = {
                format: "AI-Notation-Studio-Selection",
                version: "0.10.1",
                scoreTitle: curScore.title || "",
                isRange: selection.isRange ? true : false,
                elementCount: count,
                elements: []
            }

            for (var i = 0; i < count; i++) {
                var el = raw[i]
                var s = serializeSelectedElement(el)
                if (s) data.elements.push(s)
            }

            selectionJson = JSON.stringify(data, null, 2)
            statusText = "Auswahl gelesen: " + data.elements.length +
                         " konkrete MuseScore-Elemente" +
                         (data.isRange ? " (Bereichsauswahl)." : " (Listenauswahl).")
            return data.elements.length > 0
        } catch (e) {
            statusText = "Fehler beim Lesen der Auswahl: " + e
            selectionJson = ""
            return false
        }
    }

    function selectionBounds() {
        var info = { startTick: 0, endTick: 0, lengthTicks: 0 }
        if (selectionJson === "") return info

        try {
            var d = JSON.parse(selectionJson)
            var els = d.elements || []
            var minTick = -1
            var maxEnd = -1

            for (var i = 0; i < els.length; i++) {
                var e = els[i]
                var t = Number(e.tick)
                if (isNaN(t) || t < 0) continue
                var dur = Number(e.durationTicks || 0)
                var end = t + Math.max(0, dur)

                if (minTick < 0 || t < minTick) minTick = t
                if (maxEnd < 0 || end > maxEnd) maxEnd = end
            }

            if (minTick >= 0) info.startTick = minTick
            if (maxEnd >= 0) info.endTick = maxEnd
            info.lengthTicks = Math.max(0, info.endTick - info.startTick)
        } catch (e) {}

        return info
    }

    function makeAnalysisPrompt() {
        return "Du bist ein musikalischer Assistent in MuseScore Studio.\n" +
               "Beziehe dich ausschließlich auf die übergebene Auswahl.\n" +
               "Antworte auf Deutsch, musikalisch konkret und präzise.\n\n" +
               "AUFTRAG:\n" + instructionBox.text.trim() + "\n\n" +
               "MARKIERTE PASSAGE (JSON):\n" + selectionJson
    }

    function instrumentRangeText() {
        if (instrumentBox.currentIndex === 1) return "Viola: sinnvoll etwa C3 bis A5"
        if (instrumentBox.currentIndex === 2) return "Cello: sinnvoll etwa C2 bis G5"
        if (instrumentBox.currentIndex === 3) return "Kontrabass: klingend etwa E1 bis C4"
        if (instrumentBox.currentIndex === 4) return "Klavier: frei, aber spielbar und musikalisch sinnvoll"
        return "Violine: sinnvoll etwa G3 bis E6"
    }

    function normalizedInstrumentation() {
        var raw = freeInstrumentation.trim()
        if (raw === "") return []
        var parts = raw.split(",")
        var out = []
        for (var i = 0; i < parts.length; i++) {
            var n = parts[i].trim()
            if (n !== "") out.push(n)
        }
        return out
    }

    function canonicalInstrumentId(name) {
        var low = String(name || "").toLowerCase()
        if (low.indexOf("viola") >= 0 || low.indexOf("bratsche") >= 0) return "strings.viola"
        if (low.indexOf("cello") >= 0 || low.indexOf("violoncello") >= 0) return "strings.cello"
        if (low.indexOf("kontrabass") >= 0 || low.indexOf("double bass") >= 0) return "strings.contrabass"
        if (low.indexOf("klavier") >= 0 || low.indexOf("piano") >= 0) return "keyboard.piano"
        return "strings.violin"
    }

    function newScorePartId(name) {
        var low = String(name || "").toLowerCase()
        if (low.indexOf("viola") >= 0 || low.indexOf("bratsche") >= 0) return "viola"
        if (low.indexOf("cello") >= 0 || low.indexOf("violoncello") >= 0) return "violoncello"
        if (low.indexOf("kontrabass") >= 0 || low.indexOf("double bass") >= 0) return "contrabass"
        if (low.indexOf("klavier") >= 0 || low.indexOf("piano") >= 0) return "piano"
        if (low.indexOf("flöte") >= 0 || low.indexOf("floete") >= 0 || low.indexOf("flute") >= 0) return "flute"
        if (low.indexOf("oboe") >= 0) return "oboe"
        if (low.indexOf("klarinette") >= 0 || low.indexOf("clarinet") >= 0) return "bb-clarinet"
        if (low.indexOf("fagott") >= 0 || low.indexOf("bassoon") >= 0) return "bassoon"
        if (low.indexOf("horn") >= 0) return "horn"
        if (low.indexOf("trompete") >= 0 || low.indexOf("trumpet") >= 0) return "bb-trumpet"
        if (low.indexOf("posaune") >= 0 || low.indexOf("trombone") >= 0) return "trombone"
        if (low.indexOf("tuba") >= 0) return "tuba"
        return "violin"
    }

    function isPianoInstrument(name) {
        var low = String(name || "").toLowerCase()
        return low.indexOf("klavier") >= 0 || low.indexOf("piano") >= 0
    }

    function expectedInstrumentId(name) {
        return newScorePartId(name)
    }

    function partStaffCount(part) {
        if (!part) return 0
        return Math.max(0, (part.endTrack - part.startTrack) / 4)
    }

    function partFirstStaff(part) {
        if (!part) return -1
        return part.startTrack / 4
    }

    function verifyPart(part, requestedName) {
        if (!part) return "Part fehlt."
        var expected = expectedInstrumentId(requestedName)
        var actual = String(part.instrumentId || "")
        if (actual !== expected)
            return "Erwartet " + requestedName + " (" + expected + "), MuseScore meldet aber " + actual + "."
        if (isPianoInstrument(requestedName) && partStaffCount(part) !== 2)
            return "Klavier-Part hat nicht 2 Systeme, sondern " + partStaffCount(part) + "."
        if (!isPianoInstrument(requestedName) && partStaffCount(part) < 1)
            return "Instrument-Part hat kein Notensystem."
        return ""
    }

    function userSpecifiesKey(text) {
        var s = String(text || "")
        return /(?:^|[\s,;:()])(?:[A-Ha-h](?:is|es|#|b)?|As|Es|Des|Ges|Fis|Cis|B)[-\s]?(?:Dur|Moll)(?:$|[\s,;:.()])/i.test(s) ||
               /\b(?:major|minor)\b/i.test(s)
    }

    function userSpecifiesTempo(text) {
        var s = String(text || "")
        return /\b\d{2,3}\s*(?:bpm|BPM)\b/.test(s) ||
               /[♩♪]\s*=\s*\d{2,3}/.test(s) ||
               /\b(?:tempo|metronom)[^\n]{0,20}\d{2,3}\b/i.test(s)
    }

    function applyKeySignature(score, fifths) {
        fifths = Number(fifths)
        if (!score || isNaN(fifths))
            return false

        fifths = Math.round(fifths)
        if (fifths < -7 || fifths > 7)
            return false

        // MuseScore KEY/KEY_CONCERT use the standard number-of-fifths value:
        // flats negative, sharps positive.
        for (var staff = 0; staff < score.nstaves; staff++) {
            var cursor = score.newCursor()
            cursor.staffIdx = staff
            cursor.voice = 0
            cursor.rewind(0)
            cursor.staffIdx = staff

            var ks = newElement(Element.KEYSIG)
            ks.actualKey = fifths
            ks.concertKey = fifths
            cursor.add(ks)
        }

        return true
    }

    function applyTempo(score, bpm) {
        bpm = Number(bpm)
        if (!score || isNaN(bpm) || bpm <= 0) return false

        var cursor = score.newCursor()
        cursor.staffIdx = 0
        cursor.voice = 0
        cursor.rewind(0)

        var tempoText = newElement(Element.TEMPO_TEXT)
        tempoText.tempo = bpm / 60.0
        tempoText.text = "♩ = " + Math.round(bpm)
        cursor.add(tempoText)

        return true
    }

    function selectedRangeContainsMusic(score) {
        if (!score || !score.selection)
            return true

        var raw = score.selection.elements
        if (!raw)
            return false

        for (var i = 0; i < raw.length; i++) {
            var t = elementTypeName(raw[i])
            if (t === "Note" || t === "Chord")
                return true
        }

        return false
    }

    function prepareEmptyScoreLength(score, wantedMeasures) {
        wantedMeasures = Number(wantedMeasures)
        if (!score || isNaN(wantedMeasures) || wantedMeasures < 1)
            return false

        // Nicht mehr versuchen, eine frische MuseScore-Partitur vorab
        // per Bereichslöschung zu verkürzen. Das ist für leere Takte unnötig
        // und erwies sich in der Praxis als unzuverlässig.
        // Wir stellen nur sicher, dass mindestens genügend Takte vorhanden sind.
        if (score.nmeasures < wantedMeasures)
            score.appendMeasures(wantedMeasures - score.nmeasures)

        return score.nmeasures >= wantedMeasures
    }


    function trimScoreToMeasureCount(score, wantedMeasures) {
        wantedMeasures = Number(wantedMeasures)
        if (!score || isNaN(wantedMeasures) || wantedMeasures < 1)
            return false

        if (score.nmeasures <= wantedMeasures)
            return true

        // MuseScore 4.7 stellt dafür ausdrücklich die Aktion
        // "Remove empty trailing measures" bereit. Sie arbeitet am Partiturende
        // und braucht keine manuell erzeugte Bereichsauswahl.
        cmd("del-empty-measures")
        score.selection.clear()

        return score.nmeasures <= wantedMeasures
    }


    function insertFreeComposition() {
        var cmdStarted = false

        if (!curScore) {
            statusText = "Bitte zuerst eine MuseScore-Partitur mit dem ersten Instrument der Besetzung öffnen."
            return
        }

        if (compositionJson === "") {
            statusText = "Keine gültigen Kompositionsdaten vorhanden."
            return
        }

        try {
            var data = JSON.parse(compositionJson)
            var instruments = normalizedInstrumentation()

            if (!data.parts || data.parts.length !== instruments.length) {
                statusText = "Abbruch: technische Umsetzung enthält nicht die erwartete Anzahl Parts."
                return
            }

            // Saubere Ausgangslage erzwingen. So schreiben wir nie in alte Test-Parts.
            var existingParts = curScore.parts
            if (!existingParts || existingParts.length !== 1) {
                statusText = "Abbruch: Für freie Komposition muss die Ausgangspartitur genau 1 Part enthalten. Aktuell: " +
                             (existingParts ? existingParts.length : 0) + "."
                return
            }

            var firstCheck = verifyPart(existingParts[0], instruments[0])
            if (firstCheck !== "") {
                statusText = "Abbruch: Erster Part passt nicht zur Besetzung. " + firstCheck
                return
            }

            // Phase 1: MuseScore-Befehl außerhalb unserer startCmd-Transaktion.
            var prepOk = prepareEmptyScoreLength(curScore, freeMeasures)
            if (!prepOk) {
                if (statusText.indexOf("Ausgangspartitur enthält bereits Noten") < 0) {
                    statusText = "Abbruch: Ausgangspartitur konnte nicht auf den leeren Grundzustand gebracht werden. Aktuell: " +
                                 curScore.nmeasures + " Takte."
                }
                return
            }

            // Phase 2: eigene Transaktion für Taktaufbau, Parts und Noten.
            curScore.startCmd()
            cmdStarted = true

            if (curScore.nmeasures < freeMeasures)
                curScore.appendMeasures(freeMeasures - curScore.nmeasures)

            // Weitere Parts anlegen.
            for (var p = 1; p < instruments.length; p++) {
                curScore.appendPart(expectedInstrumentId(instruments[p]))

                var partsNow = curScore.parts
                var created = partsNow[partsNow.length - 1]
                var err = verifyPart(created, instruments[p])
                if (err !== "") {
                    curScore.endCmd(true)
                    cmdStarted = false
                    statusText = "Abbruch beim Erzeugen von Part " + (p + 1) + ": " + err
                    return
                }
            }

            // Nach dem Aufbau alle Parts noch einmal kontrollieren.
            var finalParts = curScore.parts
            if (finalParts.length !== instruments.length) {
                curScore.endCmd(true)
                    cmdStarted = false
                statusText = "Abbruch: MuseScore hat " + finalParts.length +
                             " Parts, erwartet sind " + instruments.length + "."
                return
            }

            for (var v = 0; v < instruments.length; v++) {
                var check = verifyPart(finalParts[v], instruments[v])
                if (check !== "") {
                    curScore.endCmd(true)
                    cmdStarted = false
                    statusText = "Abbruch: Part " + (v + 1) + " ist falsch. " + check
                    return
                }
            }

            var totalInserted = 0

            // Noten anhand der realen MuseScore-Partstruktur schreiben.
            for (var pi = 0; pi < data.parts.length; pi++) {
                var partData = data.parts[pi]
                if (!partData.notes) continue

                var scorePart = finalParts[pi]
                var baseStaff = partFirstStaff(scorePart)
                var staffCount = partStaffCount(scorePart)
                var piano = isPianoInstrument(instruments[pi])

                for (var i = 0; i < partData.notes.length; i++) {
                    var n = partData.notes[i]
                    if (n.pitchMidi === undefined) continue

                    var tick = Number(n.offsetTicks || 0)
                    var num = Number(n.durationNumerator || 1)
                    var den = Number(n.durationDenominator || 4)
                    var localStaff = Number(n.staff || 0)

                    if (!piano) localStaff = 0
                    if (localStaff < 0) localStaff = 0
                    if (localStaff >= staffCount) localStaff = staffCount - 1
                    if (num <= 0 || den <= 0) continue

                    var cursor = curScore.newCursor()
                    cursor.staffIdx = baseStaff + localStaff
                    cursor.voice = 0
                    cursor.rewindToTick(tick)
                    cursor.staffIdx = baseStaff + localStaff
                    cursor.voice = 0
                    cursor.setDuration(num, den)
                    cursor.addNote(Number(n.pitchMidi))
                    totalInserted++
                }
            }

            // Titel, Tonart und Tempo aus der musikalischen Komposition übernehmen.
            var titleText = String(data.title || "").trim()
            if (titleText !== "")
                curScore.setMetaTag("workTitle", titleText)

            var keyName = String(data.keyName || "").trim()
            var keyFifths = Number(data.keyFifths)
            var keySet = applyKeySignature(curScore, keyFifths)

            var tempoBpm = Number(data.tempoBpm || 0)
            var tempoSet = applyTempo(curScore, tempoBpm)

            // Erst die musikalischen Daten vollständig einfügen und die
            // MuseScore-Transaktion sauber abschließen. Danach können wirklich
            // nur noch die leeren Endtakte entfernt werden.
            curScore.endCmd()
            cmdStarted = false

            var beforeTrim = curScore.nmeasures
            var trimOk = trimScoreToMeasureCount(curScore, freeMeasures)
            var afterTrim = curScore.nmeasures
            logEvent("MUSESCORE", "Leere Endtakte bereinigt", {
                before: beforeTrim,
                requested: freeMeasures,
                after: afterTrim,
                success: trimOk
            })

            var details = []
            for (var d = 0; d < finalParts.length; d++) {
                details.push(finalParts[d].instrumentId + " (" + partStaffCount(finalParts[d]) + " System" +
                             (partStaffCount(finalParts[d]) === 1 ? "" : "e") + ")")
            }

            statusText = "Eingefügt: " + details.join(", ") +
                         " · " + freeMeasures + " Takte · " +
                         totalInserted + " Noten" +
                         (titleText !== "" ? " · Titel: " + titleText : "") +
                         (keySet ? " · Tonart: " + (keyName !== "" ? keyName : keyFifths + " Vorzeichen") : "") +
                         (tempoSet ? " · Tempo: ♩ = " + Math.round(tempoBpm) : "") +
                         (trimOk ? " · Partitur: " + curScore.nmeasures + " Takte" :
                                   " · WARNUNG: leere Endtakte blieben stehen (" + curScore.nmeasures + " Takte)") + "."
        } catch (e) {
            if (cmdStarted) {
                try { curScore.endCmd(true) } catch (ignore) {}
                cmdStarted = false
            }
            statusText = "Fehler beim Einfügen: " + e
        }
    }

    function extractOpenAIText(r) {
        var out = ""
        if (r.output_text) return r.output_text
        if (!r.output) return out
        for (var i = 0; i < r.output.length; i++) {
            var item = r.output[i]
            if (!item.content) continue
            for (var j = 0; j < item.content.length; j++) {
                if (item.content[j].text) out += item.content[j].text
            }
        }
        return out
    }

    function selectedStartTick() {
        if (selectionJson === "") return 0
        try {
            var d = JSON.parse(selectionJson)
            var minTick = -1
            var els = d.elements || []
            for (var i = 0; i < els.length; i++) {
                var t = els[i].tick
                if (t !== undefined && t >= 0 && (minTick < 0 || t < minTick))
                    minTick = t
            }
            return minTick < 0 ? 0 : minTick
        } catch (e) {
            return 0
        }
    }

    function extractJsonBlock(text) {
        if (!text) return ""
        var fenced = text.match(/```json\s*([\s\S]*?)```/i)
        if (fenced && fenced.length > 1) return fenced[1].trim()

        var first = text.indexOf("{")
        var last = text.lastIndexOf("}")
        if (first >= 0 && last > first)
            return text.substring(first, last + 1).trim()
        return ""
    }


    function instrumentMusicXmlId() {
        if (instrumentBox.currentIndex === 1) return "strings.viola"
        if (instrumentBox.currentIndex === 2) return "strings.cello"
        if (instrumentBox.currentIndex === 3) return "strings.contrabass"
        if (instrumentBox.currentIndex === 4) return "keyboard.piano"
        return "strings.violin"
    }

    function insertCompositionAsNewPart() {
        var cmdStarted = false

        if (!curScore) {
            statusText = "Keine Partitur geöffnet."
            return
        }
        if (compositionJson === "") {
            statusText = "Keine gültige Kompositions-JSON in der KI-Antwort gefunden."
            return
        }

        try {
            var data = JSON.parse(compositionJson)
            if (!data.notes || data.notes.length === 0) {
                statusText = "Die KI-Komposition enthält keine Noten."
                return
            }

            var oldStaves = curScore.nstaves
            curScore.startCmd()
            cmdStarted = true

            curScore.appendPartByMusicXmlId(instrumentMusicXmlId())

            var newStaff = oldStaves
            var cursor = curScore.newCursor()
            cursor.staffIdx = newStaff
            cursor.voice = 0

            var baseTick = selectedStartTick()
            var inserted = 0

            for (var i = 0; i < data.notes.length; i++) {
                var n = data.notes[i]
                if (n.pitchMidi === undefined) continue

                var offset = Number(n.offsetTicks || 0)
                var tick = baseTick + offset
                var num = Number(n.durationNumerator || 1)
                var den = Number(n.durationDenominator || 4)

                if (num <= 0 || den <= 0) continue

                cursor.rewindToTick(tick)
                cursor.staffIdx = newStaff
                cursor.voice = 0
                cursor.setDuration(num, den)
                cursor.addNote(Number(n.pitchMidi))
                inserted++
            }

            curScore.endCmd()
            cmdStarted = false

            statusText = inserted > 0
                ? "Neue Spur eingefügt: " + inserted + " Noten."
                : "Keine gültigen Noten eingefügt."
        } catch (e) {
            if (cmdStarted) {
                try { curScore.endCmd(true) } catch (ignore) {}
                cmdStarted = false
            }
            statusText = "Fehler beim Einfügen der neuen Spur: " + e
        }
    }


    function scoreEndTick(score) {
        if (!score || !score.lastMeasure) return 0
        return score.lastMeasure.tick.ticks + score.lastMeasure.ticks.ticks
    }

    function measureTicks(score) {
        if (!score || !score.lastMeasure || !score.lastMeasure.ticks) return 1920
        var t = Number(score.lastMeasure.ticks.ticks)
        return (!isNaN(t) && t > 0) ? t : 1920
    }

    function selectionMeasureCount() {
        var b = selectionBounds()
        var mt = measureTicks(curScore)
        if (b.lengthTicks <= 0) return 1
        return Math.max(1, Math.ceil(b.lengthTicks / mt))
    }

    function partSummary(score) {
        if (!score || !score.parts) return []
        var out = []
        for (var i = 0; i < score.parts.length; i++) {
            var p = score.parts[i]
            out.push({ index: i, instrumentId: String(p.instrumentId || ""), firstStaff: partFirstStaff(p), staves: partStaffCount(p) })
        }
        return out
    }

    function scoreSnapshot() {
        if (!curScore) return { open: false }
        return { open: true, title: String(curScore.title || ""), measures: Number(curScore.nmeasures || 0), staves: Number(curScore.nstaves || 0), parts: partSummary(curScore) }
    }

    function logEvent(kind, message, data) {
        var arr = communicationLog.slice(0)
        arr.push({ time: new Date().toISOString(), kind: kind, message: message, data: JSON.parse(redact(JSON.stringify(data || {}))) })
        if (arr.length > 200) arr = arr.slice(arr.length - 200)
        communicationLog = arr
    }

    function registerUsage(provider, r, requestModel, stage, options, elapsed) {
        var name = provider.toLowerCase()
        lastUsage = compact.ai.usage(name, r)
        lastPrices = compact.ai.prices(name, r.model || r.modelVersion || requestModel || modelBox.text.trim())
        lastCost = compact.ai.cost(lastUsage, lastPrices)
        if (lastUsage) {
            totalInputTokens += lastUsage.input
            totalOutputTokens += lastUsage.output
        }
        if (lastCost) totalCostUsd += lastCost.usd
        else unknownCosts = true
        costText = "Letzter Aufruf: " + (lastCost ? "$" + lastCost.usd.toFixed(5) : "nicht berechenbar") +
                   " · Sitzung: $" + totalCostUsd.toFixed(5) + (unknownCosts ? " + unbekannte Kosten" : "") +
                   " (geschätzt, USD)"
        if (options && compositionJob && options.jobId === compositionJob.id) {
            var ledger = compositionCosts.slice(0)
            ledger.push({ stage: stage, provider: provider, model: requestModel, returnedModel: r.model || r.modelVersion || null,
                tokens: lastUsage, prices: lastPrices, cost: lastCost, elapsed: elapsed, time: new Date().toISOString() })
            compositionCosts = ledger
        }
        logEvent("KOSTEN", costText, { tokens: lastUsage, prices: lastPrices, cost: lastCost })
    }

    function redact(text) {
        return compact.ai.sanitize(text, [apiKeyBox.text.trim(), settings.keyOpenAI, settings.keyAnthropic, settings.keyGoogle])
    }

    function communicationLogText() {
        var out = "KOMMUNIKATIONSPROTOKOLL\n\n"
        for (var i = 0; i < communicationLog.length; i++) {
            var e = communicationLog[i]
            out += "[" + e.time + "] " + e.kind + " · " + e.message + "\n"
            if (e.data && Object.keys(e.data).length) out += JSON.stringify(e.data, null, 2) + "\n"
            out += "\n"
        }
        out += "Tokens gesamt: Eingabe " + totalInputTokens + ", Ausgabe " + totalOutputTokens + "\n"
        out += costText
        return out
    }

    function diagnosticText() {
        var sel = null
        try { sel = selectionJson === "" ? null : JSON.parse(selectionJson) } catch (e) {}
        return redact(JSON.stringify({
            pluginVersion: root.version,
            provider: providerName(),
            model: modelBox.text.trim(),
            mode: modeBox.currentText,
            instruction: instructionBox.text.trim(),
            score: scoreSnapshot(),
            selection: sel,
            musicalDraft: musicalDraft,
            technicalJson: compositionJson,
            workflow: { job: compositionJob, idea: compositionIdea, ready: ideaReady, stages: compositionCosts },
            compactScore: compactSourceText, warnings: compactWarnings,
            lastUsage: lastUsage, prices: lastPrices, cost: lastCost, sessionCostUsd: totalCostUsd,
            tokens: { input: totalInputTokens, output: totalOutputTokens },
            pendingContext: { mode: pendingContextMode, baseTick: pendingContextBaseTick, measures: pendingContextMeasures, useExistingParts: pendingContextUseExistingParts, instruments: pendingContextInstruments },
            chat: { mode: chatModeIndex === 0 ? "Besprechen" : "Ändern", messages: chatMessages, proposedInstruction: chatProposedInstruction }
        }, null, 2))
    }

    function showCommunicationLog() {
        aiAnswer = communicationLogText()
        statusText = "Kommunikationsprotokoll angezeigt."
    }

    function showDiagnostic() {
        aiAnswer = diagnosticText()
        statusText = "Diagnose angezeigt."
    }

    function undoMuseScore() {
        if (!curScore) { statusText = "Keine Partitur geöffnet."; return }
        cmd("action://notation/undo")
        logEvent("MUSESCORE", "Rückgängig ausgeführt", scoreSnapshot())
        statusText = "Rückgängig."
    }

    function redoMuseScore() {
        if (!curScore) { statusText = "Keine Partitur geöffnet."; return }
        cmd("action://notation/redo")
        logEvent("MUSESCORE", "Wiederholen ausgeführt", scoreSnapshot())
        statusText = "Wiederholt."
    }

    function contextTargetInstruments(mode) {
        if (mode === 3) {
            var out = []
            if (curScore && curScore.parts) {
                for (var i = 0; i < curScore.parts.length; i++) out.push(String(curScore.parts[i].instrumentId || ("Part " + (i + 1))))
            }
            return out
        }
        return normalizedInstrumentation()
    }

    function contextMeasures(mode) {
        if (mode === 3 || mode === 4) return freeMeasures
        return selectionMeasureCount()
    }

    function ensureContextCapacity(score, baseTick, measures) {
        if (!score) return
        var mt = measureTicks(score)
        var requiredEnd = baseTick + Math.max(1, measures) * mt
        var currentEnd = scoreEndTick(score)
        if (requiredEnd > currentEnd) {
            var add = Math.ceil((requiredEnd - currentEnd) / mt)
            if (add > 0) score.appendMeasures(add)
        }
    }

    function insertContextComposition() {
        if (!curScore || compositionJson === "") { statusText = "Keine Kontextkomposition zum Einfügen vorhanden."; return }
        var cmdStarted = false
        try {
            var data = JSON.parse(compositionJson)
            if (!data.parts || data.parts.length !== pendingContextInstruments.length) { statusText = "Part-Daten passen nicht zur vorbereiteten Komposition."; return }

            curScore.startCmd("AI Notation Studio: " + pendingContextMode)
            cmdStarted = true
            ensureContextCapacity(curScore, pendingContextBaseTick, pendingContextMeasures)

            var targetParts = []
            if (pendingContextUseExistingParts) {
                if (!curScore.parts || curScore.parts.length !== data.parts.length) throw "Partiturstruktur hat sich seit der Komposition verändert."
                for (var e = 0; e < curScore.parts.length; e++) targetParts.push(curScore.parts[e])
            } else {
                var oldPartCount = curScore.parts ? curScore.parts.length : 0
                for (var p = 0; p < pendingContextInstruments.length; p++) curScore.appendPart(expectedInstrumentId(pendingContextInstruments[p]))
                if (!curScore.parts || curScore.parts.length < oldPartCount + pendingContextInstruments.length) throw "MuseScore hat nicht alle Zielparts erzeugt."
                for (var q = 0; q < pendingContextInstruments.length; q++) {
                    var created = curScore.parts[oldPartCount + q]
                    var check = verifyPart(created, pendingContextInstruments[q])
                    if (check !== "") throw check
                    targetParts.push(created)
                }
            }

            var inserted = 0
            for (var pi = 0; pi < data.parts.length; pi++) {
                var notes = data.parts[pi].notes || []
                var part = targetParts[pi]
                var baseStaff = partFirstStaff(part)
                var staffCount = partStaffCount(part)
                var piano = staffCount > 1
                for (var ni = 0; ni < notes.length; ni++) {
                    var n = notes[ni]
                    if (n.pitchMidi === undefined) continue
                    var localStaff = Number(n.staff || 0)
                    if (!piano) localStaff = 0
                    if (localStaff < 0) localStaff = 0
                    if (localStaff >= staffCount) localStaff = staffCount - 1
                    var num = Number(n.durationNumerator || 1)
                    var den = Number(n.durationDenominator || 4)
                    if (num <= 0 || den <= 0) continue
                    var cursor = curScore.newCursor()
                    cursor.staffIdx = baseStaff + localStaff
                    cursor.voice = 0
                    cursor.rewindToTick(pendingContextBaseTick + Number(n.offsetTicks || 0))
                    cursor.staffIdx = baseStaff + localStaff
                    cursor.voice = 0
                    cursor.setDuration(num, den)
                    cursor.addNote(Number(n.pitchMidi))
                    inserted++
                }
            }

            curScore.endCmd()
            cmdStarted = false
            logEvent("MUSESCORE", pendingContextMode + " eingefügt", { insertedNotes: inserted, baseTick: pendingContextBaseTick, measures: pendingContextMeasures, useExistingParts: pendingContextUseExistingParts })
            statusText = pendingContextMode + " eingefügt: " + inserted + " Noten."
        } catch (e) {
            if (cmdStarted) { try { curScore.endCmd(true) } catch (ignore) {} }
            statusText = "Einfügen fehlgeschlagen: " + e
        }
    }

    function loadChatHistory() {
        loadScoreMemory(true)
    }

    function saveChatHistory() {
        saveScoreMemory(true)
    }

    function clearChatHistory() {
        chatMessages = []
        chatProposedInstruction = ""
        saveChatHistory()
    }

    function appendChatMessage(role, text) {
        var a = chatMessages.slice(0)
        a.push({ role: role, text: String(text || "") })
        if (a.length > 50) a = a.slice(a.length - 50)
        chatMessages = a
        saveChatHistory()
    }

    function chatTranscript() {
        var out = ""
        for (var i = 0; i < chatMessages.length; i++) out += (chatMessages[i].role === "user" ? "Ich: " : "KI: ") + chatMessages[i].text + "\n\n"
        return out
    }

    function readSelectionForChat() {
        if (!curScore || !curScore.selection || !curScore.selection.elements) return ""
        var raw = curScore.selection.elements
        if (!raw || raw.length === 0) return ""
        var data = { elements: [] }
        for (var i = 0; i < raw.length; i++) {
            var e = serializeSelectedElement(raw[i])
            if (e) data.elements.push(e)
        }
        return JSON.stringify(data)
    }

    function recentChatContext() {
        var start = Math.max(0, chatMessages.length - chatContextTurns)
        var out = []
        for (var i = start; i < chatMessages.length; i++) out.push(chatMessages[i])
        return out
    }

    function buildChatPrompt(userMessage, changeMode) {
        var sel = readSelectionForChat()
        var rule = changeMode
            ? "Berate musikalisch konkret. Wenn eine Änderung sinnvoll ist, beende deine Antwort mit genau einer Zeile: BEARBEITUNGSAUFTRAG: <konkreter Auftrag>. Schreibe selbst noch nichts in die Partitur."
            : "Besprich die Partitur musikalisch. Verändere nichts und gib keine technischen MuseScore-Daten aus."
        return "Du bist der partiturbezogene Chat in AI Notation Studio.\n" +
               rule + "\n\n" +
               "PARTITURSTRUKTUR:\n" + JSON.stringify(scoreSnapshot()) + "\n\n" +
               (sel !== "" ? "AKTUELLE AUSWAHL:\n" + sel + "\n\n" : "") +
               "LETZTER CHATKONTEXT:\n" + JSON.stringify(recentChatContext()) + "\n\n" +
               "NEUE NACHRICHT:\n" + userMessage
    }

    function extractChatInstruction(text) {
        var m = String(text || "").match(/BEARBEITUNGSAUFTRAG:\s*([^\n]+)/i)
        return m && m.length > 1 ? m[1].trim() : ""
    }

    function sendChatMessage() {
        if (busy) return
        var msg = chatInput.text.trim()
        if (msg === "") return
        if (apiKeyBox.text.trim() === "") { statusText = "Bitte zuerst einen API-Key eingeben."; return }
        saveCurrentKey()
        saveCurrentModel()
        appendChatMessage("user", msg)
        chatInput.text = ""
        busy = true
        statusText = "Chat-KI arbeitet …"
        callAI(buildChatPrompt(msg, chatModeIndex === 1), function(ok, text) {
            busy = false
            if (!ok) { statusText = "Chat-Aufruf fehlgeschlagen."; return }
            appendChatMessage("assistant", text)
            chatProposedInstruction = chatModeIndex === 1 ? extractChatInstruction(text) : ""
            statusText = "Chat-Antwort erhalten."
        }, "KI CHAT")
    }

    function adoptChatInstruction() {
        if (chatProposedInstruction === "") { statusText = "Kein Bearbeitungsauftrag in der letzten Chat-Antwort gefunden."; return }
        instructionBox.text = chatProposedInstruction
        statusText = "Bearbeitungsauftrag in das Auftragsfeld übernommen."
    }

    function callAI(prompt, callback, stage, formatInstructions, options) {
        var provider = options ? options.provider : providerName()
        var model = options ? options.model : modelBox.text.trim()
        var key = options ? providerKey(provider) : apiKeyBox.text.trim()
        if (!key || !model) { callback(false, "Modell oder API-Key für " + provider + " fehlt."); return }
        var started = new Date().getTime()
        var finished = false
        var xhr = new XMLHttpRequest()
        var body = null
        var stageName = stage || "KI"
        logEvent("APP", stageName + " Anfrage", { provider: provider, model: model, prompt: prompt })

        if (provider === "OpenAI") {
            xhr.open("POST", "https://api.openai.com/v1/responses")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("Authorization", "Bearer " + key)
            body = { model: model, input: prompt }
            if (options) { body.max_output_tokens = options.maxTokens; body.store = false; body.service_tier = "default" }
            if (formatInstructions) { body.instructions = formatInstructions; body.max_output_tokens = 32768; body.store = false; body.service_tier = "default" }
        } else if (provider === "Anthropic") {
            xhr.open("POST", "https://api.anthropic.com/v1/messages")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("x-api-key", key)
            xhr.setRequestHeader("anthropic-version", "2023-06-01")
            body = {
                model: model,
                max_tokens: options ? options.maxTokens : formatInstructions ? 32768 : 5000,
                messages: [{ role: "user", content: prompt }]
            }
            if (formatInstructions) body.system = formatInstructions
        } else {
            var url = "https://generativelanguage.googleapis.com/v1beta/models/" +
                      encodeURIComponent(model) +
                      ":generateContent"
            xhr.open("POST", url)
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("x-goog-api-key", key)
            body = { contents: [{ parts: [{ text: prompt }] }] }
            if (options) body.generationConfig = { maxOutputTokens: options.maxTokens }
            if (formatInstructions) {
                body.systemInstruction = { parts: [{ text: formatInstructions }] }
                body.generationConfig = { maxOutputTokens: 32768 }
            }
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || finished) return
            finished = true

            if (xhr.status < 200 || xhr.status >= 300) {
                logEvent("SYSTEM/API", stageName + " Fehler", { provider: provider, model: model, httpStatus: xhr.status, response: xhr.responseText })
                callback(false, "HTTP " + xhr.status + "\n" + redact(xhr.responseText))
                return
            }

            try {
                var r = JSON.parse(xhr.responseText)
                var result = compact.ai.response(provider.toLowerCase(), r)
                registerUsage(provider, r, model, stageName, options, (new Date().getTime() - started) / 1000)
                logEvent("KI", stageName + " Antwort", { provider: provider, model: model, text: result.text, finish: result.finish })
                if (result.truncated) callback(false, "Antwort abgeschnitten (Tokenlimit).\n" + result.text)
                else if (!result.text) callback(false, "Keine Textantwort erhalten.\n" + redact(xhr.responseText))
                else callback(true, result.text)
            } catch (e) {
                callback(false, "Antwort konnte nicht ausgewertet werden.\n" + redact(xhr.responseText))
            }
        }

        try {
            xhr.send(JSON.stringify(body))
        } catch (e) {
            callback(false, "Netzwerkfehler: " + e)
        }
    }

    function sendToAI() {
        if (busy) return
        if (instructionBox.text.trim() === "") { statusText = "Bitte einen Auftrag eingeben."; return }
        saveCurrentKey(); saveCurrentModel()
        var mode = modeBox.currentIndex
        if (mode !== 2 && !readSelection()) return
        if (mode === 2) selectionJson = ""
        if (mode === 0) {
            busy = true
            callAI(makeAnalysisPrompt(), function(ok, text) { busy = false; aiAnswer = text; statusText = ok ? "Analyse erhalten." : "Analyse fehlgeschlagen." }, "Analyse")
            return
        }
        try {
            var job = prepareCompositionJob(mode)
            compositionJob = job; compositionCosts = []; compositionIdea = ""; ideaReady = false
            aiAnswer = ""; musicalDraft = ""; compositionJson = ""; compactSourceText = ""; compactWarnings = []
            logEvent("NUTZER", "Kompositionsauftrag", { job: job })
            runCompositionJob(job)
        } catch (e) { busy = false; statusText = String(e) }
    }

    function bootstrapRun() {
        if (settings.activeHotAppSource && settings.activeHotAppSource !== "") {
            if (compareVersions(settings.activeHotAppVersion, root.version) > 0 &&
                activateHotApp(settings.activeHotAppSource, settings.activeHotAppVersion))
                return
        }

        if (settings.provider === "Anthropic") providerBox.currentIndex = 1
        else if (settings.provider === "Google") providerBox.currentIndex = 2
        else providerBox.currentIndex = 0

        loadProviderFields()
        restoreGeneralDefaults()
        loadChatHistory()
        statusText = "Bereit. Live-App v" + root.version + " geladen."
    }

    onRun: bootstrapRun()

    Dialog {
        id: memoryDialog
        title: "Gedächtnis"
        modal: true
        standardButtons: Dialog.Close
        width: 680

        contentItem: ScrollView {
            implicitWidth: 650
            implicitHeight: 620

            ColumnLayout {
                width: 620
                spacing: 10

                Label {
                    text: "GENERELLES GEDÄCHTNIS"
                    font.pixelSize: 18
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Gilt für alle Scores. Hier stehen allgemeine Arbeitsvorlieben und die Vorbelegungen der Eingabe- und Auswahlfelder."
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: generalMemorySummary()
                    color: "#666666"
                }

                TextArea {
                    id: generalMemoryBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    wrapMode: TextEdit.Wrap
                    placeholderText: "Allgemeine Regeln und Vorlieben, die für alle Scores gelten …"
                }

                RowLayout {
                    Button {
                        text: "Generelles Gedächtnis speichern"
                        onClicked: {
                            settings.generalMemoryText = generalMemoryBox.text
                            saveGeneralDefaults()
                            statusText = "Generelles Gedächtnis gespeichert."
                        }
                    }

                    Button {
                        text: "Generelles Gedächtnis leeren"
                        onClicked: {
                            settings.generalMemoryText = ""
                            generalMemoryBox.text = ""
                            statusText = "Generelles Gedächtnis geleert."
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#888888"
                }

                Label {
                    text: "GEDÄCHTNIS DIESES SCORES"
                    font.pixelSize: 18
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Gilt nur für den geöffneten Score. Chat, letzter Auftrag und musikalische Arbeitsstände werden getrennt von anderen Scores gespeichert."
                }

                TextArea {
                    id: scoreMemoryBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    wrapMode: TextEdit.Wrap
                    placeholderText: "Notizen und Entscheidungen zu diesem Score …"
                }

                RowLayout {
                    Button {
                        text: "Score-Gedächtnis speichern"
                        onClicked: {
                            scoreMemoryNotes = scoreMemoryBox.text
                            saveScoreMemory(false)
                        }
                    }

                    Button {
                        text: "Score-Gedächtnis neu laden"
                        onClicked: {
                            loadScoreMemory(false)
                            scoreMemoryBox.text = scoreMemoryNotes
                        }
                    }

                    Button {
                        text: "Score-Gedächtnis leeren"
                        onClicked: {
                            clearScoreMemory()
                            scoreMemoryBox.text = ""
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#666666"
                    text: "Wichtig: Das Score-Gedächtnis liegt als MuseScore-Metadatum im Score. Den Score danach speichern, damit es dauerhaft in der Datei bleibt."
                }
            }
        }
    }

    Dialog {
        id: infoDialog
        title: "AI Notation Studio – Info"
        modal: true
        standardButtons: Dialog.Ok
        width: 620

        contentItem: ScrollView {
            implicitWidth: 590
            implicitHeight: 520

            TextArea {
                readOnly: true
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.pixelSize: 15
                text:
                    "AI Notation Studio v0.10.1\n\n" +
                    "KOMPOSITION / ANALYSE\n" +
                    "Dieser Bereich führt den eigentlichen musikalischen Auftrag aus. Der gewählte Modus bestimmt, ob analysiert, eine neue Stimme komponiert, frei komponiert, fortgesetzt, ein Motiv entwickelt, eine Variante erzeugt oder neu instrumentiert wird.\n\n" +
                    "PARTITUR-CHAT\n" +
                    "Der Chat ist davon getrennt. „Nur besprechen“ verändert nichts. „Änderung vorbereiten“ formuliert lediglich einen Vorschlag für einen Bearbeitungsauftrag. Erst mit „Vorschlag als Kompositionsauftrag übernehmen“ wird dieser Text in das Auftragsfeld übernommen.\n\n" +
                    "DREI ARBEITSWEISEN\n" +
                    "Alle sechs Kompositionsmodi verwenden CS1. Direkt komponieren: ein Aufruf. Idee entwickeln: kurze Idee bearbeiten, dann Jetzt komponieren. Musik zuerst: vollständige Musik, anschließend unveränderte CS1-Übertragung. Für beide Stufen können unterschiedliche Modelle gewählt werden. Analyse und Chat bleiben unabhängig.\n\n" +
                    "RÜCKGÄNGIG / WIEDERHOLEN\n" +
                    "Verwendet MuseScores eigene Undo-Historie.\n\n" +
                    "TECHNISCHES\n" +
                    "Provider, Modell und API-Key stehen gesammelt im unteren Bereich „Technisches“, damit der musikalische Arbeitsbereich übersichtlich bleibt.\n\n" +
                    "PROTOKOLL / DIAGNOSE\n" +
                    "Zeigt Kommunikation, technische Daten, Modelle, Tokenwerte und Kosten je Stufe. API-Keys werden nicht in die Diagnose übernommen.\n\n" +
                    "GEDÄCHTNIS\n" +
                    "Es gibt zwei getrennte Ebenen. Das generelle Gedächtnis enthält allgemeine Arbeitsvorlieben und Vorbelegungen der Felder. Das Score-Gedächtnis gehört ausschließlich zum geöffneten Score und enthält Chat, letzten Auftrag und Arbeitsstände.\n\n" +
                    "UPDATE\n" +
                    "Seit v0.8.0 ist die App live ladbar. Künftige Versionen werden als eigene QML-Dateien mit neuer URL geladen, damit MuseScores QML-Cache keinen Neustart mehr erzwingt."
            }
        }
    }

    Rectangle {
        id: legacyUi
        anchors.fill: parent
        visible: !hotAppActive
        color: "#202124"

        ScrollView {
            id: appScroll
            anchors.fill: parent
            anchors.margins: 18
            clip: true
            contentWidth: availableWidth
            contentHeight: appColumn.implicitHeight

        ColumnLayout {
            id: appColumn
            width: appScroll.availableWidth
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "AI Notation Studio · v0.10.1"
                    color: "white"
                    font.pixelSize: 28
                    font.bold: true
                    Layout.fillWidth: true
                }

                Button {
                    text: "Gedächtnis"
                    font.pixelSize: 14
                    onClicked: {
                        generalMemoryBox.text = settings.generalMemoryText
                        scoreMemoryBox.text = scoreMemoryNotes
                        memoryDialog.open()
                    }
                }

                Button {
                    text: "Info"
                    font.pixelSize: 14
                    onClicked: infoDialog.open()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: updateBusy ? "Prüfe …" : "Update prüfen"
                    enabled: !updateBusy
                    font.pixelSize: 14
                    onClicked: checkForUpdate()
                }

                Button {
                    text: "Update installieren"
                    visible: updateSourceText !== ""
                    enabled: updateSourceText !== "" && !updateBusy
                    font.pixelSize: 14
                    onClicked: installUpdate()
                }

                Label {
                    Layout.fillWidth: true
                    text: updateStatus
                    color: "#d7d7d7"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button { text: "Rückgängig"; font.pixelSize: 14; onClicked: undoMuseScore() }
                Button { text: "Wiederholen"; font.pixelSize: 14; onClicked: redoMuseScore() }
                Button { text: "Protokoll"; font.pixelSize: 14; onClicked: showCommunicationLog() }
                Button { text: "Diagnose"; font.pixelSize: 14; onClicked: showDiagnostic() }

                Label {
                    Layout.fillWidth: true
                    text: "Tokens: " + totalInputTokens + " ein · " + totalOutputTokens + " aus"
                    color: "#aaaaaa"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                color: "#2b2d31"
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    Label {
                        text: "KOMPOSITION / ANALYSE"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Label {
                        text: "Hier steht der eigentliche musikalische Auftrag. Auswahl, Modus, Besetzung und Auftrag gelten nur für diesen Arbeitsbereich."
                        color: "#c9c9c9"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }


            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12

                Label {
                    text: "Modus"
                    color: "white"
                    font.pixelSize: uiSize
                    font.bold: true
                }

                ComboBox {
                    id: modeBox
                    Layout.fillWidth: true
                    model: ["Auswahl analysieren", "Neue Stimme zu Auswahl", "Freie Komposition ohne Vorlage", "Fortsetzen", "Aus Motiv entwickeln", "Variante erzeugen", "Für andere Besetzung bearbeiten"]
                    currentIndex: 0
                    font.pixelSize: uiSize
                    onCurrentIndexChanged: saveGeneralDefaults()
                }

                Label { text: "Arbeitsweise"; color: "white"; font.pixelSize: uiSize; visible: modeBox.currentIndex !== 0 }
                ComboBox {
                    id: workflowBox
                    Layout.fillWidth: true
                    visible: modeBox.currentIndex !== 0
                    enabled: !busy
                    model: ["Direkt komponieren", "Idee entwickeln → komponieren", "Musik zuerst → nach CS1 übertragen"]
                    currentIndex: settings.compositionStrategy
                    onActivated: settings.compositionStrategy = currentIndex
                    font.pixelSize: uiSize
                }

                Label {
                    text: "Besetzung"
                    color: "white"
                    font.pixelSize: uiSize
                    visible: modeBox.currentIndex === 2 || modeBox.currentIndex >= 4
                }

                TextField {
                    visible: modeBox.currentIndex === 2 || modeBox.currentIndex >= 4
                    Layout.fillWidth: true
                    text: freeInstrumentation
                    font.pixelSize: uiSize
                    placeholderText: "z. B. Violine, Cello, Flöte, Oboe, Klarinette, Fagott, Horn, Trompete, Posaune, Tuba"
                    onTextChanged: {
                        freeInstrumentation = text
                        saveGeneralDefaults()
                    }
                }

                Label {
                    text: "Takte"
                    color: "white"
                    font.pixelSize: uiSize
                    visible: modeBox.currentIndex === 2 || modeBox.currentIndex === 3 || modeBox.currentIndex === 4
                }

                SpinBox {
                    visible: modeBox.currentIndex === 2 || modeBox.currentIndex === 3 || modeBox.currentIndex === 4
                    from: 1
                    to: 128
                    value: freeMeasures
                    editable: true
                    font.pixelSize: uiSize
                    onValueChanged: {
                        freeMeasures = value
                        saveGeneralDefaults()
                    }
                }

                Label {
                    text: "Instrument"
                    color: "white"
                    font.pixelSize: uiSize
                    visible: modeBox.currentIndex === 1
                }

                ComboBox {
                    id: instrumentBox
                    visible: modeBox.currentIndex === 1
                    Layout.fillWidth: true
                    model: ["Violine", "Viola", "Cello", "Kontrabass", "Klavier"]
                    font.pixelSize: uiSize
                    onCurrentIndexChanged: saveGeneralDefaults()
                }
            }

            Label {
                text: "Kompositions-/Analyseauftrag"
                color: "white"
                font.pixelSize: uiSize
                font.bold: true
            }

            TextArea {
                id: instructionBox
                    color: "#ededed"
                    placeholderTextColor: "#aaaaaa"
                    background: Rectangle { color: "#2b2d31"; radius: 4 }
                Layout.fillWidth: true
                Layout.preferredHeight: 105
                wrapMode: TextEdit.Wrap
                font.pixelSize: uiSize
                placeholderText: "Hier den eigentlichen musikalischen Auftrag eingeben …"
                onTextChanged: saveGeneralDefaults()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Auswahl neu lesen"
                    visible: modeBox.currentIndex !== 2
                    font.pixelSize: uiSize
                    onClicked: readSelection()
                }

                Button {
                    text: busy ? "KI arbeitet …" : "Auftrag ausführen"
                    enabled: !busy
                    font.pixelSize: uiSize
                    onClicked: sendToAI()
                }

                Label {
                    Layout.fillWidth: true
                    text: statusText
                    color: "#d7d7d7"
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: compositionIdea !== "" || ideaReady
                Label { text: "Kompositionsidee · editierbar"; color: "white"; font.bold: true; font.pixelSize: uiSize }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    clip: true
                    TextArea {
                        id: ideaBox
                    color: "#ededed"
                    placeholderTextColor: "#aaaaaa"
                    background: Rectangle { color: "#2b2d31"; radius: 4 }
                        width: parent.width
                        text: compositionIdea
                        readOnly: busy || !ideaReady
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        onTextChanged: if (ideaReady && !busy && compositionIdea !== text) compositionIdea = text
                        onEditingFinished: if (ideaReady) saveScoreMemory(true)
                        font.pixelSize: uiSize
                    }
                }
                RowLayout {
                    Button { text: "Jetzt komponieren"; enabled: ideaReady && !busy; onClicked: composeFromIdea() }
                    Label { Layout.fillWidth: true; color: "#d7d7d7"; wrapMode: Text.WordWrap;
                        text: compositionJob ? "Stufe 2: " + compositionJob.second.provider + " / " + compositionJob.second.model : "" }
                }
            }
            Button {
                text: "CS1-Übertragung erneut versuchen"
                visible: compositionJob && compositionJob.strategy === 2 && compositionJob.draft !== "" && compositionJson === ""
                enabled: !busy
                onClicked: realizeComposition(compositionJob)
            }
            Label {
                Layout.fillWidth: true
                visible: compositionCosts.length > 0
                text: compositionCostText()
                color: "#d7d7d7"
                wrapMode: Text.WordWrap
                font.pixelSize: 14
            }

            Label {
                text: "Ergebnis des Kompositions-/Analyseauftrags"
                color: "white"
                font.pixelSize: uiSize
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                Layout.minimumHeight: 160
                clip: true

                TextArea {
                    id: answerBox
                    color: "#ededed"
                    placeholderTextColor: "#aaaaaa"
                    background: Rectangle { color: "#2b2d31"; radius: 4 }
                    width: parent.width
                    readOnly: true
                    text: aiAnswer
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    font.pixelSize: uiSize
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button { text: "CS1 / JSON importieren"; enabled: !busy; onClicked: compactImportDialog.open() }
                Label { text: costText; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: "white" }
            }

            Button {
                text: isCompactResult() ? "Fertige Fassung in MuseScore öffnen" : modeBox.currentIndex === 2
                      ? "Freie Komposition in Partitur einfügen"
                      : (modeBox.currentIndex >= 3
                         ? pendingContextMode + " in Partitur einfügen"
                         : "KI-Komposition als neue Spur einfügen")
                visible: compositionJson !== ""
                enabled: compositionJson !== "" && !busy
                font.pixelSize: uiSize
                onClicked: {
                    if (isCompactResult()) openCompactScore()
                    else if (modeBox.currentIndex === 2) insertFreeComposition()
                    else if (modeBox.currentIndex >= 3) insertContextComposition()
                    else insertCompositionAsNewPart()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                color: "#34363b"
                radius: 5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "PARTITUR-CHAT"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Label {
                            text: "Zum Besprechen der Partitur. Der Chat ist getrennt vom Kompositionsauftrag und schreibt nicht automatisch in die Partitur."
                            color: "#c9c9c9"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        text: chatExpanded ? "Chat schließen" : "Chat öffnen"
                        font.pixelSize: 14
                        onClicked: {
                            chatExpanded = !chatExpanded
                            saveGeneralDefaults()
                        }
                    }
                }
            }

            Rectangle {
                visible: chatExpanded
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                color: "#292a2d"
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Label {
                        Layout.fillWidth: true
                        text: chatModeIndex === 0
                              ? "Nur besprechen: Fragen, analysieren und diskutieren – ohne Änderung."
                              : "Änderung vorbereiten: Der Chat formuliert einen Bearbeitungsauftrag, den du bewusst in das Kompositionsfeld übernehmen kannst."
                        color: "#d7d7d7"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ComboBox {
                            id: chatModeBox
                            model: ["Nur besprechen", "Änderung vorbereiten"]
                            currentIndex: chatModeIndex
                            onCurrentIndexChanged: {
                                chatModeIndex = currentIndex
                                saveGeneralDefaults()
                            }
                            font.pixelSize: 14
                        }

                        Button { text: "Neuer Chat"; font.pixelSize: 14; onClicked: clearChatHistory() }

                        Button {
                            text: "Vorschlag als Kompositionsauftrag übernehmen"
                            visible: chatProposedInstruction !== ""
                            font.pixelSize: 14
                            onClicked: adoptChatInstruction()
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: chatHistoryBox
                    color: "#ededed"
                    placeholderTextColor: "#aaaaaa"
                    background: Rectangle { color: "#2b2d31"; radius: 4 }
                            width: parent.width
                            readOnly: true
                            text: chatTranscript()
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            font.pixelSize: 14
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        TextField {
                            id: chatInput
                            Layout.fillWidth: true
                            placeholderText: "Hier mit der KI über die Partitur sprechen …"
                            font.pixelSize: 14
                            onAccepted: sendChatMessage()
                        }

                        Button { text: busy ? "…" : "Senden"; enabled: !busy; font.pixelSize: 14; onClicked: sendChatMessage() }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "#2b2d31"
                radius: 5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Label {
                        text: "TECHNISCHES"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Provider, Modell und API-Key"
                        color: "#c9c9c9"
                        font.pixelSize: 13
                    }

                    Button {
                        text: technicalExpanded ? "Einklappen" : "Aufklappen"
                        font.pixelSize: 13
                        onClicked: {
                            technicalExpanded = !technicalExpanded
                            saveGeneralDefaults()
                        }
                    }
                }
            }

            GridLayout {
                visible: technicalExpanded
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                Label {
                    text: "Anbieter · Direkt / Stufe 1"
                    color: "white"
                    font.pixelSize: uiSize
                }

                ComboBox {
                    id: providerBox
                    Layout.fillWidth: true
                    model: ["OpenAI", "Anthropic", "Google"]
                    font.pixelSize: uiSize
                    onCurrentIndexChanged: {
                        loadProviderFields()
                    }
                }

                Label {
                    text: "Modell"
                    color: "white"
                    font.pixelSize: uiSize
                }

                TextField {
                    id: modelBox
                    Layout.fillWidth: true
                    font.pixelSize: uiSize
                    onEditingFinished: saveCurrentModel()
                }

                Label {
                    text: "API-Key"
                    color: "white"
                    font.pixelSize: uiSize
                }

                TextField {
                    id: apiKeyBox
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    font.pixelSize: uiSize
                    placeholderText: "wird lokal gespeichert"
                    onEditingFinished: saveCurrentKey()
                }
            }

            GridLayout {
                visible: technicalExpanded && modeBox.currentIndex !== 0 && settings.compositionStrategy !== 0
                Layout.fillWidth: true
                columns: 2
                Label { text: "Modell für Stufe 2"; color: "white"; font.pixelSize: uiSize }
                CheckBox { text: "Dasselbe wie Stufe 1"; checked: settings.sameStageModel; enabled: !busy; onToggled: settings.sameStageModel = checked }
                Label { text: "Anbieter · Stufe 2"; color: "white"; visible: !settings.sameStageModel }
                ComboBox {
                    id: stageTwoProviderBox
                    visible: !settings.sameStageModel
                    Layout.fillWidth: true
                    enabled: !busy
                    model: ["OpenAI", "Anthropic", "Google"]
                    currentIndex: settings.secondProvider === "Anthropic" ? 1 : settings.secondProvider === "Google" ? 2 : 0
                    onActivated: { settings.secondProvider = currentText; settings.secondModel = providerModel(currentText) }
                }
                Label { text: "Modell · Stufe 2"; color: "white"; visible: !settings.sameStageModel }
                TextField {
                    id: stageTwoModelBox
                    visible: !settings.sameStageModel
                    Layout.fillWidth: true
                    enabled: !busy
                    text: settings.secondModel
                    placeholderText: providerModel(settings.secondProvider)
                    onTextEdited: settings.secondModel = text.trim()
                }
                Label { text: "Gespeicherter Key"; color: "white"; visible: !settings.sameStageModel }
                Label { text: providerKey(settings.secondProvider) ? "vorhanden" : "fehlt – Anbieter oben wählen und Key speichern"; color: "#d7d7d7"; visible: !settings.sameStageModel; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }

            Label {
                Layout.fillWidth: true
                color: "#aaaaaa"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "v0.10.1 · 08.10.2026: Windows-Start, Dateipfade und Loader-Wiederherstellung korrigiert."
            }
        }
        }
    }

    Loader {
        id: hotAppLoader
        anchors.fill: parent
        visible: hotAppActive
        active: hotAppRequested

        onLoaded: {
            try {
                if (!item || typeof item.bootstrapRun !== "function")
                    throw Error("App-Einstieg bootstrapRun fehlt.")
                item.bootstrapRun()
                hotAppActive = true
                updateStatus = "Live-App v" + hotAppVersion + " geladen."
            } catch (e) {
                restoreAfterAppFailure("App-Start fehlgeschlagen: " + String(e) + ". Die bisherige Oberfläche bleibt verfügbar.")
            }
        }

        onStatusChanged: {
            if (status === Loader.Error) {
                restoreAfterAppFailure("Live-App konnte nicht geladen werden: " + String(source) + ". Über Update prüfen erneut installieren.")
            }
        }
    }
}
