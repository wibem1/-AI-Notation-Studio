import QtQuick 2.2
QtObject {
 property string source: ""
 signal error(string msg)
 function read() { return "" }
 function write(text) { return true }
}
