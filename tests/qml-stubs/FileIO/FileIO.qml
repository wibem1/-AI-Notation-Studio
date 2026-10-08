import QtQuick 2.2
QtObject {
 property string source: ""
 property string data: ""
 signal error(string msg)
 function read() { return data }
 function write(text) { return true }
}
