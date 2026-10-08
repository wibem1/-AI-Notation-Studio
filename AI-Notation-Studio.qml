import QtQuick 2.2
import MuseScore 3.0
import MuseScore 3.0 as MS
import FileIO 3.0

MuseScore {
    id: root
    menuPath: "Plugins.AI Notation Studio"
    description: "Starter für AI Notation Studio"
    version: "0.7.14"
    requiresScore: true
    pluginType: "dialog"
    title: "AI Notation Studio"
    implicitWidth: 900
    implicitHeight: 900
    width: 900
    height: 900

    property bool hotAppActive: false
    property bool hotAppRequested: false
    property string hotAppVersion: ""
    property string updateStatus: "App wird vorbereitet …"
    property string startupDetails: ""
    property var pendingComponent: null

    MS.Settings {
        id: settings
        category: "AI-Notation-Studio"
        property string activeHotAppSource: ""
        property string activeHotAppVersion: ""
    }

    FileIO {
        id: updaterFile
        onError: function(msg) { startupDetails = String(msg) }
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

    function activateHotApp(sourceUrl, versionText) {
        if (!sourceUrl) return false
        sourceUrl = normalizedAppUrl(sourceUrl)
        hotAppRequested = false
        hotAppActive = false
        hotAppLoader.source = ""
        hotAppVersion = versionText || ""
        startupDetails = "Datei: " + sourceUrl
        updateStatus = "App wird geladen …"
        pendingComponent = Qt.createComponent(sourceUrl)
        if (pendingComponent.status === Component.Error) {
            restoreAfterAppFailure(pendingComponent.errorString())
            return false
        }
        hotAppLoader.source = sourceUrl
        hotAppRequested = true
        return true
    }

    function restoreAfterAppFailure(message) {
        hotAppActive = false
        updateStatus = "Die App konnte nicht gestartet werden."
        startupDetails += "\n\n" + String(message)
        var failedSource = String(hotAppLoader.source)
        Qt.callLater(function() {
            if (String(hotAppLoader.source) !== failedSource) return
            hotAppRequested = false
        })
    }

    function tryBundledApp() {
        var url = String(Qt.resolvedUrl("AI-Notation-Studio-App.qml"))
        return activateHotApp(url, "0.10.4")
    }

    function startApp() {
        startupDetails = ""
        if (settings.activeHotAppSource && compareVersions(settings.activeHotAppVersion, "0.10.4") > 0) {
            if (activateHotApp(settings.activeHotAppSource, settings.activeHotAppVersion)) return
        }
        tryBundledApp()
    }

    onRun: Qt.callLater(startApp)

    Rectangle {
        anchors.fill: parent
        color: "#202124"
        visible: !hotAppActive
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 20
            Text {
                text: "AI Notation Studio · Starter 0.7.14"
                color: "white"
                font.pixelSize: 26
            }
            Text {
                width: parent.width
                text: updateStatus
                color: "white"
                font.pixelSize: 20
                wrapMode: Text.Wrap
            }
            TextEdit {
                width: parent.width
                text: startupDetails
                color: "#dddddd"
                font.pixelSize: 15
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
            }
            Rectangle {
                width: 260
                height: 46
                color: "#42464c"
                Text { anchors.centerIn: parent; text: "Erneut laden"; color: "white"; font.pixelSize: 18 }
                MouseArea { anchors.fill: parent; onClicked: startApp() }
            }
            Text {
                width: parent.width
                text: "Beide QML-Dateien müssen im selben Ordner liegen. Bei einem Fehler bitte den angezeigten Text kopieren oder fotografieren."
                color: "#bbbbbb"
                wrapMode: Text.Wrap
                font.pixelSize: 16
            }
        }
    }

    Loader {
        id: hotAppLoader
        anchors.fill: parent
        active: hotAppRequested
        visible: hotAppActive
        onLoaded: {
            try {
                if (!item || typeof item.bootstrapRun !== "function") throw Error("App-Einstieg fehlt.")
                item.bootstrapRun()
                hotAppActive = true
                updateStatus = "App geladen."
            } catch (e) { restoreAfterAppFailure(String(e)) }
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                var detail = pendingComponent ? pendingComponent.errorString() : ""
                restoreAfterAppFailure(detail || "QML-Datei konnte nicht geladen werden.")
            }
        }
    }
}
