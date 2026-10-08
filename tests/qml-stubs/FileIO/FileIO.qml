import QtQuick 2.2
QtObject {
 property string source: ""
 property string data: ""
 signal error(string msg)
 function read() { return typeof startupTestFiles !== "undefined" ? startupTestFiles.read(source) : data }
 function write(text) { return typeof startupTestFiles !== "undefined" ? startupTestFiles.write(source,text) : true }
}
