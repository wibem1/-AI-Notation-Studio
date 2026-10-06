import QtQuick 2.2
Item {
 property string menuPath: ""
 property string description: ""
 property string version: ""
 property bool requiresScore: false
 property string pluginType: ""
 property string title: ""
 property var curScore: null
 signal run()
}
