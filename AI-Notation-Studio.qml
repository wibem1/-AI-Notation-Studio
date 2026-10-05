import QtQuick 2.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    id: root
    menuPath: "Plugins.AI Notation Studio"
    description: "KI-Kompositionswerkstatt für markierte Passagen in MuseScore Studio"
    version: "0.7.0"
    requiresScore: true
    pluginType: "dialog"
    title: "AI Notation Studio"
    width: 820
    height: 900

    property string selectionJson: ""
    property string statusText: "Bereit."
    property string aiAnswer: ""
    property string musicalDraft: ""
    property string compositionJson: ""
    property bool busy: false
    property string freeInstrumentation: "Violine, Cello"
    property int freeMeasures: 16
    property int uiSize: 18
    property string updateStatus: "Noch nicht geprüft."
    property string updateRemoteVersion: ""
    property string updateSourceText: ""
    property bool updateBusy: false
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
    }

    FileIO {
        id: updaterFile
        onError: function(msg) {
            updateStatus = "Update-Datei konnte nicht geschrieben werden: " + msg
        }
    }

    function currentVersionString() {
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
        return "https://raw.githubusercontent.com/wibem1/AI-Notation-Studio/main/AI-Notation-Studio.qml"
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

    function checkForUpdate() {
        if (updateBusy) return
        updateBusy = true
        updateRemoteVersion = ""
        updateSourceText = ""
        updateStatus = "Prüfe auf Update …"

        var xhr = new XMLHttpRequest()
        xhr.open("GET", updateRawUrl())
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            updateBusy = false

            if (xhr.status < 200 || xhr.status >= 300) {
                updateStatus = "Update-Prüfung fehlgeschlagen: HTTP " + xhr.status
                return
            }

            var source = xhr.responseText
            if (!validateUpdateSource(source)) {
                updateStatus = "Update abgebrochen: GitHub-Datei ist keine gültige AI-Notation-Studio-Version."
                return
            }

            var remote = extractPluginVersion(source)
            updateRemoteVersion = remote

            var cmp = compareVersions(currentVersionString(), remote)
            if (cmp < 0) {
                updateSourceText = source
                updateStatus = "Neue Version verfügbar: v" + remote
            } else if (cmp === 0) {
                updateStatus = "Aktuell: v" + currentVersionString()
            } else {
                updateStatus = "Installiert v" + currentVersionString() + " ist neuer als GitHub v" + remote + "."
            }
        }

        try {
            xhr.send()
        } catch (e) {
            updateBusy = false
            updateStatus = "Update-Prüfung fehlgeschlagen: " + e
        }
    }

    function installUpdate() {
        if (updateSourceText === "" || updateRemoteVersion === "") {
            updateStatus = "Kein neues Update zum Installieren."
            return
        }

        var dir = updaterFile.pluginDirectoryPath()
        if (!dir || dir === "") {
            updateStatus = "Plugin-Ordner konnte nicht ermittelt werden."
            return
        }

        var target = dir + "/AI-Notation-Studio.qml"
        if (!updaterFile.isPathWriteable(target)) {
            updateStatus = "Plugin-Datei ist für MuseScore nicht schreibbar: " + target
            return
        }

        updaterFile.source = target
        var ok = updaterFile.write(updateSourceText)
        if (!ok) {
            updateStatus = "Update konnte nicht geschrieben werden."
            return
        }

        updateStatus = "v" + updateRemoteVersion +
                       " installiert. MuseScore neu starten, damit die neue Version aktiv wird."
        updateSourceText = ""
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
                version: "0.7.0",
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

    function makeCompositionPrompt() {
        var b = selectionBounds()

        return "Du komponierst eine NEUE eigenständige Stimme zu einer vorhandenen MuseScore-Passage.\n" +
               "Jetzt geht es ausschließlich um MUSIKALISCHE KOMPOSITION, noch NICHT um MIDI, JSON, Ticks oder API-Formate.\n\n" +
               "AUFTRAG DES NUTZERS:\n" + instructionBox.text.trim() + "\n\n" +
               "ZIELINSTRUMENT:\n" + instrumentBox.currentText + "\n" +
               instrumentRangeText() + "\n\n" +
               "ANFORDERUNGEN:\n" +
               "- Schreibe eine durchgehende, eigenständige und musikalisch sinnvolle Stimme.\n" +
               "- Beziehe Melodik, Harmonik, Rhythmus und Motive der ausgewählten Passage hörbar ein.\n" +
               "- Vermeide bloße lange Liegetöne, schematische Füllstimmen und zufällige Einzelnoten.\n" +
               "- Gestalte erkennbare Phrasen, Richtung, Spannung und Entspannung.\n" +
               "- Verwende ein für das Instrument plausibles Register und spielbare Sprünge.\n" +
               "- Pausen nur, wenn sie musikalisch sinnvoll sind.\n" +
               "- Die neue Stimme soll genau den musikalischen Zeitraum der Auswahl abdecken.\n" +
               "- Wenn es eine Oberstimme sein soll, führe sie überwiegend oberhalb des vorhandenen Materials, aber nicht künstlich extrem hoch.\n\n" +
               "Gib die fertige Stimme in einer klaren, taktweise gegliederten musikalischen Notation aus: " +
               "Tonhöhen als C4, D#4, Bb4 usw. und Notenwerte als ganze, halbe, Viertel, Achtel, punktierte Werte, Triolen falls nötig. " +
               "Dazu nur notwendige Phrasierungs-/Dynamikangaben. Keine Erläuterung deiner Arbeitsweise.\n\n" +
               "REFERENZPASSAGE:\n" + selectionJson
    }

    function makeRealizationPrompt(draft) {
        var b = selectionBounds()

        return "Du bist jetzt ausschließlich für die TECHNISCHE UMSETZUNG einer bereits fertig komponierten Stimme zuständig.\n" +
               "Verändere die musikalische Idee nicht. Erfinde keine neue Musik.\n\n" +
               "ZIELINSTRUMENT: " + instrumentBox.currentText + "\n" +
               "AUSWAHL-STARTTICK: " + b.startTick + "\n" +
               "AUSWAHL-LÄNGE-TICKS: " + b.lengthTicks + "\n\n" +
               "FERTIGE MUSIKALISCHE STIMME:\n" + draft + "\n\n" +
               "Übersetze diese Stimme in exakt dieses JSON-Schema:\n" +
               "{\n" +
               '  "title": "kurzer Name",\n' +
               '  "notes": [\n' +
               '    {"offsetTicks": 0, "durationNumerator": 1, "durationDenominator": 4, "pitchMidi": 60}\n' +
               "  ]\n" +
               "}\n\n" +
               "REGELN:\n" +
               "- offsetTicks relativ zum Auswahlbeginn.\n" +
               "- pitchMidi ist die reale MIDI-Tonhöhe der notierten Note.\n" +
               "- durationNumerator/durationDenominator geben den musikalischen Notenwert an.\n" +
               "- Pausen werden als Lücken in offsetTicks dargestellt, nicht als Notenobjekte.\n" +
               "- Erhalte Rhythmus und Tonhöhen der fertigen Stimme exakt.\n" +
               "- Gib ausschließlich einen ```json-Block aus, keinerlei weitere Erklärung."
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

    function nextCompositionProfile() {
        var forms = [
            "durchkomponiert mit deutlich wechselnden Abschnitten statt einfacher ABA-Form",
            "bogenförmig mit einem einzigen großen Spannungsverlauf und asymmetrischen Phrasen",
            "motivisch konzentriert: ein kleines Motiv wird hörbar verwandelt, verkürzt, erweitert und zwischen den Stimmen weitergegeben",
            "episodisch mit kontrastierenden Charakteren, die dennoch motivisch zusammenhängen",
            "kontrapunktisch gedacht: die Stimmen reagieren, imitieren und widersprechen einander",
            "frei-rhapsodisch, aber mit klarer innerer Dramaturgie und ohne schematische Wiederholungen"
        ]

        var textures = [
            "transparente Textur mit viel Raum und wechselnder Stimmendichte",
            "enge dialogische Verzahnung der Instrumente; keine dauerhafte Melodie-plus-Begleitung-Hierarchie",
            "wechselnde Rollen: führende Stimme, Gegenstimme und Begleitfunktion sollen mehrfach tauschen",
            "polyphone Textur mit eigenständigen Linien statt Akkordteppich",
            "punktuell akkordische Verdichtung, dazwischen lineare und kammermusikalisch leichte Passagen",
            "rhythmisch verzahnte Textur mit Gegenbewegung und unabhängigen Impulsen"
        ]

        var rhythms = [
            "rhythmisch flexibel mit Synkopen und unregelmäßigen Phrasenenden; keine durchlaufenden Achtelketten",
            "ruhiger Grundpuls, aber mit unterschiedlich langen Notenwerten und bewusst gesetzten Pausen",
            "prägnantes rhythmisches Motiv, das im Verlauf verändert wird",
            "fließend und legato, jedoch ohne mechanisches Dauerpattern",
            "wechselnde Bewegungsdichte: ruhige Flächen, kurze Impulse und verdichtete Höhepunkte",
            "subtile metrische Reibung durch Vorhalte, Verschiebungen und Gegenakzente"
        ]

        var openings = [
            "Beginne nicht mit einem vollständigen Thema, sondern mit einem fragmentarischen Impuls, der sich erst entwickelt.",
            "Beginne mit einer ungewöhnlichen Registerkonstellation oder einem offenen Intervall, nicht mit einer Kadenz.",
            "Beginne mit einer kurzen Frage-Antwort-Geste zwischen den Instrumenten.",
            "Beginne sehr reduziert; die musikalische Identität soll sich erst in den ersten Takten schärfen.",
            "Beginne mit einer charakteristischen rhythmischen Figur statt einer langen gesanglichen Melodie.",
            "Beginne mit harmonischer Mehrdeutigkeit und kläre das tonale Zentrum erst nach einigen Takten."
        ]

        var harmonies = [
            "harmonisch farbig mit Zwischendominanten, Vorhalten und einzelnen überraschenden Seitenschritten",
            "tonal klar, aber mit eigenständiger Stimmführung statt Standard-Kadenzketten",
            "mit modalen Färbungen und wechselnden Klangzentren innerhalb der vorgegebenen Tonart",
            "mit chromatischen Durchgangs- und Wechselklängen, ohne spätromantische Dauerüberladung",
            "mit größeren harmonischen Spannungsbögen statt Akkordwechsel auf jedem Schlag",
            "mit bewussten Ruhepunkten und wenigen, dafür charakteristischen harmonischen Wendungen"
        ]

        // Bewusst breit gestreut: Dur/Moll, Kreuz-/B-Tonarten und verschiedene Lagen.
        var keys = [
            "G-Dur", "e-Moll", "Es-Dur", "cis-Moll", "A-Dur", "g-Moll",
            "F-Dur", "h-Moll", "As-Dur", "fis-Moll", "D-Dur", "c-Moll"
        ]

        // Ebenfalls bewusst nicht um 70 BPM gebündelt.
        var tempos = [96, 54, 126, 82, 138, 64, 112, 76, 148, 88, 120, 60]

        var n = settings.freeCompositionCounter
        settings.freeCompositionCounter = n + 1

        var text = "KOMPOSITORISCHES PROFIL FÜR DIESEN LAUF:\n" +
                   "- Form: " + forms[n % forms.length] + ".\n" +
                   "- Textur: " + textures[(n * 3 + 1) % textures.length] + ".\n" +
                   "- Rhythmik: " + rhythms[(n * 5 + 2) % rhythms.length] + ".\n" +
                   "- Anfang: " + openings[(n * 2 + 3) % openings.length] + "\n" +
                   "- Harmonik: " + harmonies[(n * 4 + 4) % harmonies.length] + ".\n" +
                   "Dieses Profil ist verbindlich, sofern der Nutzerauftrag ihm nicht ausdrücklich widerspricht.\n" +
                   "Vermeide insbesondere eine immer gleiche Standardlösung aus 4+4-taktiger Melodie, gleichförmiger Begleitung und schematischer ABA-Form.\n"

        return {
            text: text,
            keyName: keys[n % keys.length],
            tempoBpm: tempos[(n * 5 + 3) % tempos.length]
        }
    }

    function makeFreeCompositionPrompt() {
        var instruments = normalizedInstrumentation()
        var profile = nextCompositionProfile()
        var userText = instructionBox.text.trim()
        var keyRule = ""
        var tempoRule = ""

        if (userSpecifiesKey(userText))
            keyRule = "TONART: Der Nutzer hat selbst eine Tonart angegeben. Diese hat absolute Priorität; verwende keine Profil-Tonart.\n"
        else
            keyRule = "VERBINDLICHE TONART FÜR DIESEN LAUF: " + profile.keyName + ". Verwende genau diese Tonart und NICHT d-Moll als Standardersatz.\n"

        if (userSpecifiesTempo(userText))
            tempoRule = "TEMPO: Der Nutzer hat selbst ein Tempo angegeben. Dieses hat absolute Priorität.\n"
        else
            tempoRule = "VERBINDLICHES GRUNDTEMPO FÜR DIESEN LAUF: ♩ = " + profile.tempoBpm + " BPM. Verwende genau dieses Grundtempo und NICHT automatisch etwa 70 BPM.\n"

        return "Du komponierst ein vollständiges eigenständiges Musikstück OHNE musikalische Vorlage.\n" +
               "Jetzt geht es ausschließlich um MUSIKALISCHE KOMPOSITION, noch NICHT um MIDI, JSON, Ticks oder API-Formate.\n\n" +
               "AUFTRAG DES NUTZERS:\n" + instructionBox.text.trim() + "\n\n" +
               "VERBINDLICHE BESETZUNG:\n" + instruments.join(", ") + "\n" +
               "VERBINDLICHE TAKTZAHL:\n" + freeMeasures + " Takte\n\n" +
               keyRule + tempoRule + "\n" +
               profile.text + "\n" +
               "ANFORDERUNGEN:\n" +
               "- Komponiere musikalisch frei und eigenständig.\n" +
               "- Verwende genau die angegebene Besetzung; keine zusätzlichen Instrumente.\n" +
               "- Schreibe genau " + freeMeasures + " Takte.\n" +
               "- Beachte Tonart, Taktart, Tempo und Charakter aus dem Auftrag, soweit angegeben.\n" +
               "- Jede Stimme soll musikalisch sinnvoll, eigenständig und auf die anderen Stimmen bezogen sein.\n" +
               "- Wenn Klavier beteiligt ist, komponiere ausdrücklich eine echte rechte UND linke Hand; die linke Hand darf nicht nur fehlen oder die rechte Hand verdoppeln.\n" +
               "- Vermeide schematische Begleitmuster, bloße Liegetöne und mechanische Wiederholungen, sofern sie nicht musikalisch begründet sind.\n" +
               "- Gestalte Form, Phrasen, motivische Beziehungen, Harmonik, Rhythmus, Spannung und Entspannung.\n" +
               "- Schreibe für die Instrumente spielbar und in plausiblen Registern.\n\n" +
               "Gib der Komposition einen prägnanten Titel und schreibe ihn in der ersten Zeile als: TITEL: <Titel>. " +
               "Schreibe in der zweiten Zeile: TONART: <Tonart>. Verwende dabei exakt die oben verbindlich festgelegte Tonart bzw. die ausdrücklich vom Nutzer genannte Tonart. " +
               "Schreibe in der dritten Zeile: TEMPO: <BPM> BPM. Verwende dabei exakt das oben verbindlich festgelegte Grundtempo bzw. das ausdrücklich vom Nutzer genannte Tempo. " +
               "Gib danach die vollständige Komposition taktweise gegliedert aus. " +
               "Kennzeichne jede Instrumentalstimme eindeutig und in exakt derselben Reihenfolge wie die Besetzung. " +
               "Tonhöhen als C4, D#4, Bb4 usw.; Notenwerte als ganze, halbe, Viertel, Achtel, punktierte Werte und Triolen falls nötig. " +
               "Keine technischen JSON-, MIDI- oder Tick-Angaben und keine Erläuterung deiner Arbeitsweise."
    }

    function makeFreeRealizationPrompt(draft) {
        var instruments = normalizedInstrumentation()
        var numbered = []
        for (var i = 0; i < instruments.length; i++)
            numbered.push((i + 1) + ": " + instruments[i])

        return "Du bist ausschließlich für die TECHNISCHE UMSETZUNG einer bereits fertig komponierten mehrstimmigen Komposition zuständig.\n" +
               "Verändere die musikalische Idee nicht und komponiere nichts neu.\n\n" +
               "VERBINDLICHE PART-REIHENFOLGE:\n" + numbered.join("\n") + "\n\n" +
               "FERTIGE KOMPOSITION:\n" + draft + "\n\n" +
               "MuseScore verwendet 480 Ticks pro Viertelnote.\n\n" +
               "Übersetze die Komposition in exakt dieses JSON-Schema:\n" +
               "{\n" +
               '  "title": "Titel der Komposition",\n' +
               '  "keyName": "d-Moll",\n' +
               '  "keyFifths": -1,\n' +
               '  "tempoBpm": 78,\n' +
               '  "parts": [\n' +
               "    {\n" +
               '      "partIndex": 1,\n' +
               '      "notes": [\n' +
               '        {"offsetTicks": 0, "durationNumerator": 1, "durationDenominator": 4, "pitchMidi": 60, "staff": 0}\n' +
               "      ]\n" +
               "    }\n" +
               "  ]\n" +
               "}\n\n" +
               "REGELN:\n" +
               "- title MUSS den Titel der fertigen musikalischen Komposition enthalten.\n" +
               "- keyName MUSS die in der fertigen Komposition genannte Tonart enthalten.\n" +
               "- keyFifths MUSS die Zahl der Vorzeichen dieser Tonart enthalten: b-Vorzeichen negativ, #-Vorzeichen positiv, C-Dur/a-Moll = 0.\n" +
               "- Beispiele: d-Moll = -1, g-Moll = -2, D-Dur = 2, E-Dur = 4, e-Moll = 1.\n" +
               "- tempoBpm MUSS das in der fertigen Komposition genannte Grundtempo als Zahl enthalten.\n" +
               "- Gib exakt " + instruments.length + " Parts aus.\n" +
               "- Part 1 entspricht dem ersten Instrument der Besetzung, Part 2 dem zweiten usw.\n" +
               "- Verwende KEINE Instrumentnamen und KEINE musicXmlId im JSON.\n" +
               "- staff ist bei einstimmigen Instrumenten immer 0.\n" +
               "- Bei Klavier: staff 0 = rechte Hand / oberes System, staff 1 = linke Hand / unteres System.\n" +
               "- Bei Klavier MÜSSEN beide Systeme musikalisch sinnvoll benutzt werden, sofern die fertige Komposition beide Hände enthält.\n" +
               "- offsetTicks relativ zum Beginn des Stücks.\n" +
               "- Viertelnote = 480, Achtelnote = 240, halbe Note = 960, ganze Note = 1920 Ticks.\n" +
               "- Pausen werden als Lücken dargestellt.\n" +
               "- Erhalte Tonhöhen, Rhythmus, Stimmen und Form exakt.\n" +
               "- Gib ausschließlich einen ```json-Block aus."
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

        // MuseScore-Befehle außerhalb von startCmd() ausführen.
        // Die frische Ausgangspartitur ist leer, daher löschen wir ihren
        // gesamten Taktbereich als Zeitbereich. MuseScore behält mindestens
        // einen Takt; anschließend baut der Aufrufer exakt auf wantedMeasures auf.
        if (!score.firstMeasure || !score.lastMeasure)
            return false

        var startTick = score.firstMeasure.tick.ticks
        var endTick = score.lastMeasure.tick.ticks + score.lastMeasure.ticks.ticks

        score.selection.clear()

        var ok = score.selection.selectRange(
                    startTick,
                    endTick,
                    0,
                    score.nstaves)

        if (!ok)
            return false

        if (selectedRangeContainsMusic(score)) {
            score.selection.clear()
            statusText = "Abbruch: Die Ausgangspartitur enthält bereits Noten. Freie Komposition löscht vorhandenes musikalisches Material nicht."
            return false
        }

        cmd("time-delete")
        score.selection.clear()

        // Zusätzliche Bereinigung, falls MuseScore noch leere Endtakte behält.
        cmd("del-empty-measures")
        score.selection.clear()

        // Erwartung: 0 oder 1 Resttakt, jedenfalls nicht mehr als wantedMeasures.
        return score.nmeasures <= wantedMeasures
    }


    function trimScoreToMeasureCount(score, wantedMeasures) {
        wantedMeasures = Number(wantedMeasures)
        if (!score || isNaN(wantedMeasures) || wantedMeasures < 1)
            return false

        if (score.nmeasures <= wantedMeasures)
            return true

        // First measure that must be removed: wantedMeasures + 1
        var m = score.firstMeasure
        var count = 1
        while (m && count < wantedMeasures + 1) {
            m = m.nextMeasure
            count++
        }

        if (!m)
            return false

        var startTick = m.tick.ticks
        var last = score.lastMeasure
        var endTick = last.tick.ticks + last.ticks.ticks

        score.selection.clear()
        var ok = score.selection.selectRange(startTick, endTick, 0, score.nstaves)
        if (!ok)
            return false

        // "time-delete" is MuseScore's command for deleting a selected measure range.
        cmd("time-delete")
        score.selection.clear()

        // Optional cleanup of any remaining empty tail.
        cmd("del-empty-measures")

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

            // Falls MuseScore bei der Bereinigung mehr Takte als gewünscht
            // stehen ließ, brechen wir ab statt in eine falsche Struktur zu schreiben.
            if (curScore.nmeasures > freeMeasures) {
                curScore.endCmd(true)
                cmdStarted = false
                statusText = "Abbruch: MuseScore ließ nach der Leer-Takt-Bereinigung " +
                             curScore.nmeasures + " Takte stehen; erwartet: " + freeMeasures + "."
                return
            }

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

            // Keine UI-Löschbefehle innerhalb startCmd. Nur noch prüfen.
            var trimOk = (curScore.nmeasures === freeMeasures)

            curScore.endCmd()
            cmdStarted = false

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
                                   " · WARNUNG: Taktkürzung nicht vollständig") + "."
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
        arr.push({ time: new Date().toISOString(), kind: kind, message: message, data: data || {} })
        if (arr.length > 200) arr = arr.slice(arr.length - 200)
        communicationLog = arr
    }

    function usageFromResponse(provider, r) {
        var input = 0
        var output = 0
        if (provider === "OpenAI" && r && r.usage) {
            input = Number(r.usage.input_tokens || r.usage.prompt_tokens || 0)
            output = Number(r.usage.output_tokens || r.usage.completion_tokens || 0)
        } else if (provider === "Anthropic" && r && r.usage) {
            input = Number(r.usage.input_tokens || 0)
            output = Number(r.usage.output_tokens || 0)
        } else if (provider === "Google" && r && r.usageMetadata) {
            input = Number(r.usageMetadata.promptTokenCount || 0)
            output = Number(r.usageMetadata.candidatesTokenCount || 0)
        }
        if (isNaN(input)) input = 0
        if (isNaN(output)) output = 0
        return { input: input, output: output }
    }

    function registerUsage(provider, r) {
        var u = usageFromResponse(provider, r)
        totalInputTokens += u.input
        totalOutputTokens += u.output
        logEvent("KOSTEN", "Tokenverbrauch", { provider: provider, inputTokens: u.input, outputTokens: u.output, totalInputTokens: totalInputTokens, totalOutputTokens: totalOutputTokens, cost: "nicht berechenbar ohne verifizierten Modellpreis" })
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
        out += "Kosten: nicht berechenbar ohne verifizierten Modellpreis."
        return out
    }

    function diagnosticText() {
        var sel = null
        try { sel = selectionJson === "" ? null : JSON.parse(selectionJson) } catch (e) {}
        return JSON.stringify({
            pluginVersion: root.version,
            provider: providerName(),
            model: modelBox.text.trim(),
            mode: modeBox.currentText,
            instruction: instructionBox.text.trim(),
            score: scoreSnapshot(),
            selection: sel,
            musicalDraft: musicalDraft,
            technicalJson: compositionJson,
            tokens: { input: totalInputTokens, output: totalOutputTokens },
            pendingContext: { mode: pendingContextMode, baseTick: pendingContextBaseTick, measures: pendingContextMeasures, useExistingParts: pendingContextUseExistingParts, instruments: pendingContextInstruments },
            chat: { mode: chatModeIndex === 0 ? "Besprechen" : "Ändern", messages: chatMessages, proposedInstruction: chatProposedInstruction }
        }, null, 2)
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

    function makeContextCompositionPrompt(mode) {
        var names = { 3: "FORTSETZEN", 4: "AUS MOTIV ENTWICKELN", 5: "VARIANTE ERZEUGEN", 6: "FÜR ANDERE BESETZUNG BEARBEITEN" }
        var instruments = contextTargetInstruments(mode)
        var measures = contextMeasures(mode)
        var specific = ""
        if (mode === 3) {
            specific = "Setze die Musik organisch nach dem Ende der Auswahl fort. Entwickle Motive, Harmonik und Rhythmik weiter, statt die Auswahl bloß zu wiederholen. Die vorhandenen Parts bleiben erhalten und müssen in gleicher Reihenfolge verwendet werden."
        } else if (mode === 4) {
            specific = "Behandle die Auswahl als motivischen Keim. Entwickle daraus ein vollständiges Stück. Sequenz, rhythmische Veränderung, Umkehrung, Gegenstimmen und harmonische Neuinterpretation sind erlaubt, das Motiv soll aber erkennbar bleiben."
        } else if (mode === 5) {
            specific = "Erzeuge genau EINE musikalisch eigenständige Variante der Auswahl. Bewahre Identität, ungefähre Form und Funktion, ändere aber Melodik, Rhythmik, Stimmführung oder Harmonik sinnvoll. Keine Liste mehrerer Varianten."
        } else {
            specific = "Bearbeite die Auswahl idiomatisch für die Zielbesetzung. Bewahre musikalische Identität, Form und wesentliche Stimmen, verteile Register, Rollen und Klangfarben aber instrumentengerecht neu."
        }

        return "Du komponierst jetzt die endgültige musikalische Fassung für den Modus " + names[mode] + ".\n" +
               "Dies ist KEIN Vorentwurf und KEIN technischer JSON-Schritt. Komponiere vollständig und konkret ausnotierbar.\n\n" +
               "AUFTRAG DES NUTZERS:\n" + instructionBox.text.trim() + "\n\n" +
               "ZIELPARTS/Besetzung: " + instruments.join(", ") + "\n" +
               "ZIELLÄNGE: " + measures + " Takte.\n\n" +
               specific + "\n\n" +
               "Achte auf musikalische Gestalt, Verlauf, Stimmen, Rhythmus, Harmonik, Artikulation, Dynamik und Spielbarkeit. Keine Erläuterung deiner Arbeitsweise.\n\n" +
               "REFERENZAUSWAHL (MuseScore-JSON):\n" + selectionJson
    }

    function makeContextRealizationPrompt(draft, mode) {
        var instruments = contextTargetInstruments(mode)
        return "Du bist ausschließlich für die TECHNISCHE UMSETZUNG einer bereits fertig komponierten musikalischen Fassung zuständig.\n" +
               "Nicht neu komponieren, nichts vereinfachen, keine musikalischen Entscheidungen ändern.\n\n" +
               "ZIELPARTS in dieser Reihenfolge: " + instruments.join(", ") + "\n" +
               "MuseScore verwendet 480 Ticks pro Viertelnote.\n\n" +
               "FERTIGE MUSIKALISCHE FASSUNG:\n" + draft + "\n\n" +
               "Gib exakt dieses JSON-Schema aus:\n" +
               "{\n" +
               '  "title": "kurzer Name",\n' +
               '  "parts": [\n' +
               '    {"partIndex":1,"notes":[{"offsetTicks":0,"durationNumerator":1,"durationDenominator":4,"pitchMidi":60,"staff":0}]}\n' +
               "  ]\n" +
               "}\n\n" +
               "REGELN:\n" +
               "- Genau " + instruments.length + " Part-Objekte in der angegebenen Reihenfolge.\n" +
               "- offsetTicks relativ zum Einfügebeginn.\n" +
               "- staff ist innerhalb eines Parts 0-basiert; bei Klavier 0 rechte, 1 linke Hand.\n" +
               "- Pausen als Lücken.\n" +
               "- Rhythmus und Tonhöhen der fertigen Fassung exakt erhalten.\n" +
               "- Nur einen JSON-Block ausgeben."
    }

    function runContextMode(mode) {
        if (mode === 3) {
            var b = selectionBounds()
            if (b.endTick < scoreEndTick(curScore)) {
                busy = false
                statusText = "Fortsetzen ist nur sicher, wenn die Auswahl am Partiturende endet."
                return
            }
        }

        var instruments = contextTargetInstruments(mode)
        if (!instruments || instruments.length === 0) {
            busy = false
            statusText = "Keine Zielbesetzung angegeben."
            return
        }

        var labels = {3:"Fortsetzen",4:"Motiv entwickeln",5:"Variante",6:"Bearbeitung"}
        statusText = "1/2: KI komponiert · " + labels[mode] + " …"

        callAI(makeContextCompositionPrompt(mode), function(ok1, draft) {
            if (!ok1) { busy = false; aiAnswer = draft; statusText = labels[mode] + " fehlgeschlagen."; return }
            musicalDraft = draft
            aiAnswer = "MUSIKALISCHE FASSUNG:\n\n" + draft + "\n\n---\n\n2/2: Technische Umsetzung läuft …"
            statusText = "2/2: Umsetzung für MuseScore …"

            callAI(makeContextRealizationPrompt(draft, mode), function(ok2, technical) {
                busy = false
                if (!ok2) {
                    aiAnswer = "MUSIKALISCHE FASSUNG:\n\n" + draft + "\n\n---\n\nTECHNISCHE UMSETZUNG FEHLGESCHLAGEN:\n" + technical
                    statusText = "Musik fertig, technische Umsetzung fehlgeschlagen."
                    return
                }
                var candidate = extractJsonBlock(technical)
                try {
                    var obj = JSON.parse(candidate)
                    if (!obj.parts || obj.parts.length !== instruments.length) {
                        compositionJson = ""
                        statusText = "Technische Umsetzung hat eine falsche Part-Anzahl."
                        aiAnswer = technical
                        return
                    }
                    var b2 = selectionBounds()
                    pendingContextMode = labels[mode]
                    pendingContextBaseTick = mode === 3 ? b2.endTick : b2.startTick
                    pendingContextMeasures = contextMeasures(mode)
                    pendingContextUseExistingParts = mode === 3
                    pendingContextInstruments = instruments.slice(0)
                    compositionJson = candidate
                    aiAnswer = "MUSIKALISCHE FASSUNG:\n\n" + draft + "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                    statusText = labels[mode] + " fertig und zum Einfügen bereit."
                } catch (e) {
                    compositionJson = ""
                    aiAnswer = technical
                    statusText = "Technische JSON-Daten konnten nicht gelesen werden."
                }
            }, "KI TECHNIK · " + labels[mode])
        }, "KI MUSIK · " + labels[mode])
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
        try {
            var a = JSON.parse(settings.chatHistoryJson || "[]")
            chatMessages = a && a.length !== undefined ? a : []
        } catch (e) { chatMessages = [] }
    }

    function saveChatHistory() {
        try { settings.chatHistoryJson = JSON.stringify(chatMessages) } catch (e) {}
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

    function callAI(prompt, callback, stage) {
        var provider = providerName()
        var model = modelBox.text.trim()
        var key = apiKeyBox.text.trim()
        var xhr = new XMLHttpRequest()
        var body = null
        var stageName = stage || "KI"
        logEvent("APP", stageName + " Anfrage", { provider: provider, model: model, prompt: prompt })

        if (provider === "OpenAI") {
            xhr.open("POST", "https://api.openai.com/v1/responses")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("Authorization", "Bearer " + key)
            body = { model: model, input: prompt }
        } else if (provider === "Anthropic") {
            xhr.open("POST", "https://api.anthropic.com/v1/messages")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("x-api-key", key)
            xhr.setRequestHeader("anthropic-version", "2023-06-01")
            body = {
                model: model,
                max_tokens: 5000,
                messages: [{ role: "user", content: prompt }]
            }
        } else {
            var url = "https://generativelanguage.googleapis.com/v1beta/models/" +
                      encodeURIComponent(model) +
                      ":generateContent?key=" + encodeURIComponent(key)
            xhr.open("POST", url)
            xhr.setRequestHeader("Content-Type", "application/json")
            body = { contents: [{ parts: [{ text: prompt }] }] }
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                logEvent("SYSTEM/API", stageName + " Fehler", { provider: provider, model: model, httpStatus: xhr.status, response: xhr.responseText })
                callback(false, "HTTP " + xhr.status + "\n" + xhr.responseText)
                return
            }

            try {
                var r = JSON.parse(xhr.responseText)
                var text = ""

                if (provider === "OpenAI") {
                    text = extractOpenAIText(r)
                } else if (provider === "Anthropic") {
                    text = (r.content && r.content.length && r.content[0].text)
                           ? r.content[0].text : ""
                } else {
                    text = (r.candidates && r.candidates.length &&
                            r.candidates[0].content &&
                            r.candidates[0].content.parts &&
                            r.candidates[0].content.parts.length)
                           ? r.candidates[0].content.parts[0].text : ""
                }

                registerUsage(provider, r)
                logEvent("KI", stageName + " Antwort", { provider: provider, model: model, text: text || xhr.responseText })
                callback(true, text || xhr.responseText)
            } catch (e) {
                callback(false, "Antwort konnte nicht ausgewertet werden.\n" + xhr.responseText)
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

        if (instructionBox.text.trim() === "") {
            statusText = "Bitte einen Auftrag eingeben."
            return
        }
        if (apiKeyBox.text.trim() === "") {
            statusText = "Bitte einen API-Key eingeben."
            return
        }

        var mode = modeBox.currentIndex

        if (mode !== 2) {
            if (!readSelection()) return
        } else {
            selectionJson = ""
        }

        logEvent("NUTZER", "Auftrag", { mode: modeBox.currentText, instruction: instructionBox.text.trim(), instrumentation: freeInstrumentation, measures: freeMeasures })

        saveCurrentKey()
        saveCurrentModel()

        busy = true
        aiAnswer = ""
        musicalDraft = ""
        compositionJson = ""

        if (mode === 0) {
            statusText = "KI analysiert …"
            callAI(makeAnalysisPrompt(), function(ok, text) {
                busy = false
                aiAnswer = text
                statusText = ok ? "KI-Antwort erhalten." : "KI-Aufruf fehlgeschlagen."
            })
            return
        }

        if (mode === 1) {
            statusText = "1/2: KI komponiert die neue Stimme …"

            callAI(makeCompositionPrompt(), function(ok1, draft) {
                if (!ok1) {
                    busy = false
                    aiAnswer = draft
                    statusText = "Komposition fehlgeschlagen."
                    return
                }

                musicalDraft = draft
                aiAnswer = "MUSIKALISCHE KOMPOSITION:\n\n" + draft +
                           "\n\n---\n\n2/2: Technische Umsetzung läuft …"
                statusText = "2/2: Komposition wird für MuseScore umgesetzt …"

                callAI(makeRealizationPrompt(draft), function(ok2, technical) {
                    busy = false

                    if (!ok2) {
                        aiAnswer = "MUSIKALISCHE KOMPOSITION:\n\n" + draft +
                                   "\n\n---\n\nTECHNISCHE UMSETZUNG FEHLGESCHLAGEN:\n" + technical
                        statusText = "Musik komponiert, technische Umsetzung fehlgeschlagen."
                        return
                    }

                    var candidate = extractJsonBlock(technical)
                    try {
                        var obj = JSON.parse(candidate)
                        if (obj && obj.notes && obj.notes.length !== undefined) {
                            compositionJson = candidate
                            aiAnswer = "MUSIKALISCHE KOMPOSITION:\n\n" + draft +
                                       "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                            statusText = "Komposition fertig und zum Einfügen bereit."
                        } else {
                            compositionJson = ""
                            aiAnswer = "MUSIKALISCHE KOMPOSITION:\n\n" + draft +
                                       "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                            statusText = "Komposition fertig, aber Notendaten nicht erkannt."
                        }
                    } catch (e) {
                        compositionJson = ""
                        aiAnswer = "MUSIKALISCHE KOMPOSITION:\n\n" + draft +
                                   "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                        statusText = "Komposition fertig, JSON konnte nicht gelesen werden."
                    }
                })
            })
            return
        }

        if (mode >= 3) {
            runContextMode(mode)
            return
        }

        // Freie Komposition ohne Vorlage
        statusText = "1/2: KI komponiert frei …"

        callAI(makeFreeCompositionPrompt(), function(ok1, draft) {
            if (!ok1) {
                busy = false
                aiAnswer = draft
                statusText = "Freie Komposition fehlgeschlagen."
                return
            }

            musicalDraft = draft
            aiAnswer = "FREIE KOMPOSITION:\n\n" + draft +
                       "\n\n---\n\n2/2: Technische Umsetzung läuft …"
            statusText = "2/2: Freie Komposition wird für MuseScore umgesetzt …"

            callAI(makeFreeRealizationPrompt(draft), function(ok2, technical) {
                busy = false

                if (!ok2) {
                    aiAnswer = "FREIE KOMPOSITION:\n\n" + draft +
                               "\n\n---\n\nTECHNISCHE UMSETZUNG FEHLGESCHLAGEN:\n" + technical
                    statusText = "Komposition fertig, technische Umsetzung fehlgeschlagen."
                    return
                }

                var candidate = extractJsonBlock(technical)
                try {
                    var obj = JSON.parse(candidate)
                    if (obj && obj.parts && obj.parts.length === normalizedInstrumentation().length) {
                        compositionJson = candidate
                        aiAnswer = "FREIE KOMPOSITION:\n\n" + draft +
                                   "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                        statusText = "Freie Komposition fertig und zum Einfügen bereit."
                    } else {
                        compositionJson = ""
                        aiAnswer = "FREIE KOMPOSITION:\n\n" + draft +
                                   "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                        statusText = "Komposition fertig, aber Part-Daten nicht erkannt."
                    }
                } catch (e) {
                    compositionJson = ""
                    aiAnswer = "FREIE KOMPOSITION:\n\n" + draft +
                               "\n\n---\n\nTECHNISCHE UMSETZUNG:\n\n" + technical
                    statusText = "Komposition fertig, JSON konnte nicht gelesen werden."
                }
            })
        })
    }

    onRun: {
        if (settings.provider === "Anthropic") providerBox.currentIndex = 1
        else if (settings.provider === "Google") providerBox.currentIndex = 2
        else providerBox.currentIndex = 0

        loadProviderFields()
        loadChatHistory()
        statusText = "Markiere eine Passage und klicke auf „Auswahl neu lesen“ oder „An KI senden“."
    }

    Rectangle {
        anchors.fill: parent
        color: "#202124"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Label {
                text: "AI Notation Studio · v0.7.0"
                color: "white"
                font.pixelSize: 28
                font.bold: true
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
                    text: "Tokens: " + totalInputTokens + " ein · " + totalOutputTokens + " aus · Kosten: nicht berechenbar"
                    color: "#aaaaaa"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignRight
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                Label {
                    text: "Anbieter"
                    color: "white"
                    font.pixelSize: uiSize
                }

                ComboBox {
                    id: providerBox
                    Layout.fillWidth: true
                    model: ["OpenAI", "Anthropic", "Google"]
                    font.pixelSize: uiSize
                    onCurrentIndexChanged: loadProviderFields()
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
                    placeholderText: "z. B. Violine, Cello"
                    onTextChanged: freeInstrumentation = text
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
                    onValueChanged: freeMeasures = value
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
                }
            }

            Label {
                text: "Auftrag an die KI"
                color: "white"
                font.pixelSize: uiSize
                font.bold: true
            }

            TextArea {
                id: instructionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 105
                wrapMode: TextEdit.Wrap
                font.pixelSize: uiSize
                placeholderText: "z. B. Analysiere diese Passage musikalisch."
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
                    text: busy ? "KI arbeitet …" : "An KI senden"
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

            Label {
                text: "KI-Antwort"
                color: "white"
                font.pixelSize: uiSize
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: answerBox
                    width: parent.width
                    readOnly: true
                    text: aiAnswer
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    font.pixelSize: uiSize
                }
            }

            Button {
                text: modeBox.currentIndex === 2
                      ? "Freie Komposition in Partitur einfügen"
                      : (modeBox.currentIndex >= 3
                         ? pendingContextMode + " in Partitur einfügen"
                         : "KI-Komposition als neue Spur einfügen")
                visible: compositionJson !== ""
                enabled: compositionJson !== ""
                font.pixelSize: uiSize
                onClicked: {
                    if (modeBox.currentIndex === 2) insertFreeComposition()
                    else if (modeBox.currentIndex >= 3) insertContextComposition()
                    else insertCompositionAsNewPart()
                }
            }

            Button {
                text: chatExpanded ? "Chat ausblenden" : "Partitur-Chat"
                font.pixelSize: 14
                onClicked: chatExpanded = !chatExpanded
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

                    RowLayout {
                        Layout.fillWidth: true

                        ComboBox {
                            id: chatModeBox
                            model: ["Besprechen", "Ändern"]
                            currentIndex: chatModeIndex
                            onCurrentIndexChanged: chatModeIndex = currentIndex
                            font.pixelSize: 14
                        }

                        Button { text: "Neuer Chat"; font.pixelSize: 14; onClicked: clearChatHistory() }

                        Button {
                            text: "Bearbeitungsauftrag übernehmen"
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
                            placeholderText: "Frage zur Partitur oder zur markierten Passage …"
                            font.pixelSize: 14
                            onAccepted: sendChatMessage()
                        }

                        Button { text: busy ? "…" : "Senden"; enabled: !busy; font.pixelSize: 14; onClicked: sendChatMessage() }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                color: "#aaaaaa"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "v0.7.0: Fortsetzen, Motiv entwickeln, eine Variante erzeugen, andere Besetzung, Partitur-Chat, MuseScore-Undo/Redo, Kommunikationsprotokoll, Diagnose und Tokenkontrolle. MuseScore-Schreibzugriffe verwenden auditierte API-v1-Funktionen bzw. im 4.7-Quellcode verifizierte Action-Codes."
            }
        }
    }
}
