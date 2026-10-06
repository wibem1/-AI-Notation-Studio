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
    version: "0.9.0"
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

    property string compactInstructions: "Gib die fertige Komposition ausschließlich in CompactScore CS1 aus, ohne Markdown oder Vorentwurf. Keine MIDI-Controller, technischen Performancekurven, Nullwerte oder ungenutzten Felder erzeugen. Musikalisch benötigte Angaben beibehalten.\nCS1 ist ein Zeilenformat. S steht einmal am Anfang; P beginnt ein Instrument. Eine Zeile Takt/Stimme enthält die Ereignisse dieser Stimme; alle Stimmen beginnen bei Taktanfang. Leerzeichen trennen Ereignisse. Noten haben immer absolute Tonhöhen mit Oktave, ohne implizite Vorzeichen aus der Tonart.\nBeispiel:\nCS1\nS {\"t\":\"Titel\",\"k\":\"d minor\",\"m\":\"4/4\",\"b\":{\"v\":72,\"x\":\"Andante\"}}\nP {\"i\":\"violin\",\"n\":\"violin\"}\n1/1 R:h D4:q{\"i\":\"a\"} E4:e. F4:s\n2/1 [D4,F4,A4]:h D4:h{\"i\":\"b\",\"f\":\"normal\"}\nE {\"t\":\"dynamic\",\"p\":{\"m\":1,\"b\":3},\"v\":\"p\"}\nE {\"t\":\"expression\",\"p\":{\"m\":1,\"b\":3},\"x\":\"cantabile\"}\nE {\"t\":\"slur\",\"a\":\"a\",\"b\":\"b\"}\nNoten: C4:q; Pause: R:h; Akkord: [C4,E4,G4]:q.\nDauern: b=Brevis,w=Ganze,h=Halbe,q=Viertel,e=Achtel,s=16tel,t=32tel,x=64tel,z=128tel. Ein oder mehrere Punkte verlängern die Dauer. Triolen: (3:2:e C4:e D4:e E4:e ) ; allgemein (n:m:d Dauerfaktor m/n bis ).\nOptionale Attribute direkt am Ereignis als JSON: i=ID nur für referenzierte Noten, a=Artikulationsliste, o=Ornament, l=Bindung start/stop/continue, f=Fermate, r=Arpeggio. Beispiel C4:q{\"a\":[\"tenuto\"],\"l\":\"start\"}. Artikulationen gelten nur für diese Note.\nE-Markierungen gelten für das aktuelle Instrument; G-Markierungen global. Schlüssel: t=type,p=position,v=value,x=text,s=start,e=end,a=startRef,b=endRef,l=style,k=kind,q=tempo. Position: {\"m\":Takt,\"b\":Viertelposition}, 1 ist Taktanfang, 1.5 eine Achtel später. Dynamik und Spieltechnik nur am Beginn oder bei Änderung; Dynamik gilt im Instrument bis zur nächsten Änderung. Bögen verbinden IDs. Haarspange: E {\"t\":\"hairpin\",\"k\":\"crescendo\",\"s\":{\"m\":1,\"b\":1},\"e\":{\"m\":2,\"b\":1}}. Pedal genauso mit t=pedal ohne k. Tempo: G {\"t\":\"tempo\",\"p\":{\"m\":2,\"b\":1},\"q\":{\"v\":60,\"x\":\"rit.\"}}. Schlüsselwechsel: E {\"t\":\"clef\",\"p\":{\"m\":2,\"b\":1},\"v\":\"bass\"}. Sonstige seltene Markierungsfelder behalten den vollständigen Namen mit vorangestelltem ~. Keine unveränderten Zustände wiederholen.\n"

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

    function runCompactComposition() {
        statusText = "KI komponiert in CS1 …"
        var task = instructionBox.text.trim() + "\nBesetzung: " + freeInstrumentation +
                   "\nGenau " + freeMeasures + " Takte. Jedes Instrument als eigenen P-Block ausgeben. Klavier mit Stimmen für beide Hände. Englische Instrumentnamen verwenden.\nArbeitsvorlieben: " + settings.generalMemoryText
        callAI(task, function(ok, text) {
            busy = false
            if (!ok) { aiAnswer = text; statusText = "CS1-Komposition fehlgeschlagen."; return }
            try { acceptCompactText(text); saveScoreMemory(true) }
            catch (e) { aiAnswer = text + "\n\nImportfehler: " + e; statusText = "CS1-Antwort erhalten; Importfehler prüfen." }
        }, "CS1-Komposition", compactInstructions)
    }

    function openCompactScore() {
        if (busy || !isCompactResult()) return
        try {
            var data = JSON.parse(compositionJson)
            var source = compact.score.encode(data)
            var result = compact.xml.convert(data)
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
            try { acceptCompactText(compactImportText.text) }
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
          function layout(part) {
            var instrument = String(part.instrument || 'piano').toLowerCase().replace(/[\s_-]/g, ''),
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
                var length = currentMeter.quarters;
                plan.voices.forEach(function (v) {
                  var sum = (plan.rows[mn + '/' + v.id] || []).reduce(function (a, r) {
                    return a + r.q;
                  }, 0);
                  if (sum > length + .00001) {
                    warnings.push('Takt ' + mn + ' Stimme ' + v.id + ' ist länger als die Taktart.');
                    length = Math.max(length, sum);
                  }
                });
                xml += '<measure number="' + mn + '">';
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
        return {
          score: scope.CompactScore,
          xml: scope.CompactMusicXML,
          ai: scope.CompactAI
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

        // Ab v0.9.0 liegt die eigentliche App in einer getrennten, live ladbaren Datei.
        // Solange diese Datei noch nicht veröffentlicht ist, fällt der Updater auf
        // die bisherige monolithische Plugin-Datei zurück.
        var xhr = new XMLHttpRequest()
        xhr.open("GET", updateHotAppUrl())
        try {
            xhr.setRequestHeader("Cache-Control", "no-cache")
            xhr.setRequestHeader("Pragma", "no-cache")
        } catch (ignoreHeaders) {}

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

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
        if (s.indexOf("file://") !== 0)
            return s
        s = s.replace(/^file:\/\//, "")
        try { s = decodeURIComponent(s) } catch (ignoreDecode) {}
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

                updaterFile.source = hotTarget
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

        settings.activeHotAppSource = sourceUrl
        settings.activeHotAppVersion = versionText || ""
        hotAppVersion = versionText || ""
        hotAppActive = true

        // Andere URL => neue QML-Komponente statt MuseScores gecachter Plugin-Komponente.
        hotAppLoader.source = ""
        hotAppLoader.source = sourceUrl
        return true
    }

    function clearHotAppActivation() {
        settings.activeHotAppSource = ""
        settings.activeHotAppVersion = ""
        hotAppVersion = ""
        hotAppActive = false
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
            compactSourceText: compactSourceText
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
                version: "0.9.0",
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

    function registerUsage(provider, r) {
        var name = provider.toLowerCase()
        lastUsage = compact.ai.usage(name, r)
        lastPrices = compact.ai.prices(name, r.model || r.modelVersion || modelBox.text.trim())
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
                    saveScoreMemory(true)
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

    function callAI(prompt, callback, stage, formatInstructions) {
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
            if (formatInstructions) { body.instructions = formatInstructions; body.max_output_tokens = 32768; body.store = false; body.service_tier = "default" }
        } else if (provider === "Anthropic") {
            xhr.open("POST", "https://api.anthropic.com/v1/messages")
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.setRequestHeader("x-api-key", key)
            xhr.setRequestHeader("anthropic-version", "2023-06-01")
            body = {
                model: model,
                max_tokens: formatInstructions ? 32768 : 5000,
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
            if (formatInstructions) {
                body.systemInstruction = { parts: [{ text: formatInstructions }] }
                body.generationConfig = { maxOutputTokens: 32768 }
            }
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                logEvent("SYSTEM/API", stageName + " Fehler", { provider: provider, model: model, httpStatus: xhr.status, response: xhr.responseText })
                callback(false, "HTTP " + xhr.status + "\n" + redact(xhr.responseText))
                return
            }

            try {
                var r = JSON.parse(xhr.responseText)
                var result = compact.ai.response(provider.toLowerCase(), r)
                registerUsage(provider, r)
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
        compactSourceText = ""
        compactWarnings = []

        if (mode === 2) { runCompactComposition(); return }

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
                            saveScoreMemory(true)
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

    }

    function bootstrapRun() {
        if (settings.activeHotAppSource && settings.activeHotAppSource !== "") {
            if (settings.activeHotAppVersion !== root.version &&
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
                    "AI Notation Studio v0.9.0\n\n" +
                    "KOMPOSITION / ANALYSE\n" +
                    "Dieser Bereich führt den eigentlichen musikalischen Auftrag aus. Der gewählte Modus bestimmt, ob analysiert, eine neue Stimme komponiert, frei komponiert, fortgesetzt, ein Motiv entwickelt, eine Variante erzeugt oder neu instrumentiert wird.\n\n" +
                    "PARTITUR-CHAT\n" +
                    "Der Chat ist davon getrennt. „Nur besprechen“ verändert nichts. „Änderung vorbereiten“ formuliert lediglich einen Vorschlag für einen Bearbeitungsauftrag. Erst mit „Vorschlag als Kompositionsauftrag übernehmen“ wird dieser Text in das Auftragsfeld übernommen.\n\n" +
                    "ZWEI-STUFEN-PRINZIP\n" +
                    "Freie Komposition verwendet CS1 in einem KI-Aufruf und öffnet über MusicXML eine neue Partitur. Die übrigen Kompositionsmodi behalten ihre zweistufige Umsetzung. CS1 und Mini/Maxi-JSON können direkt importiert werden.\n\n" +
                    "RÜCKGÄNGIG / WIEDERHOLEN\n" +
                    "Verwendet MuseScores eigene Undo-Historie.\n\n" +
                    "TECHNISCHES\n" +
                    "Provider, Modell und API-Key stehen gesammelt im unteren Bereich „Technisches“, damit der musikalische Arbeitsbereich übersichtlich bleibt.\n\n" +
                    "PROTOKOLL / DIAGNOSE\n" +
                    "Zeigt die Kommunikation, technische Daten und Tokenwerte. API-Keys werden nicht in die Diagnose übernommen.\n\n" +
                    "GEDÄCHTNIS\n" +
                    "Es gibt zwei getrennte Ebenen. Das generelle Gedächtnis enthält allgemeine Arbeitsvorlieben und Vorbelegungen der Felder. Das Score-Gedächtnis gehört ausschließlich zum geöffneten Score und enthält Chat, letzten Auftrag und Arbeitsstände.\n\n" +
                    "UPDATE\n" +
                    "v0.9.0 ist die erste live ladbare App-Version. Künftige Versionen werden als eigene QML-Dateien mit neuer URL geladen, damit MuseScores QML-Cache keinen Neustart mehr erzwingt."
            }
        }
    }

    Rectangle {
        id: legacyUi
        anchors.fill: parent
        visible: !hotAppActive
        color: "#202124"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "AI Notation Studio · v0.9.0"
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
                    text: "Tokens: " + totalInputTokens + " ein · " + totalOutputTokens + " aus · Kosten: nicht berechenbar"
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

            Label {
                text: "Ergebnis des Kompositions-/Analyseauftrags"
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

            RowLayout {
                Layout.fillWidth: true
                Button { text: "CS1 / JSON importieren"; enabled: !busy; onClicked: compactImportDialog.open() }
                Label { text: costText; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: "white" }
            }

            Button {
                text: isCompactResult() ? "Komposition in MuseScore öffnen" : modeBox.currentIndex === 2
                      ? "Freie Komposition in Partitur einfügen"
                      : (modeBox.currentIndex >= 3
                         ? pendingContextMode + " in Partitur einfügen"
                         : "KI-Komposition als neue Spur einfügen")
                visible: compositionJson !== ""
                enabled: compositionJson !== ""
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
                    text: "Anbieter"
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

            Label {
                Layout.fillWidth: true
                color: "#aaaaaa"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "v0.9.0: CompactScore CS1, MusicXML-Import und geschätzte KI-Kosten."
            }
        }
    }

    Loader {
        id: hotAppLoader
        anchors.fill: parent
        visible: hotAppActive
        active: hotAppActive

        onLoaded: {
            if (item && typeof item.bootstrapRun === "function")
                item.bootstrapRun()
        }

        onStatusChanged: {
            if (status === Loader.Error) {
                hotAppActive = false
                updateStatus = "Live-App konnte nicht geladen werden. Die bisherige Oberfläche bleibt aktiv."
            }
        }
    }
}
