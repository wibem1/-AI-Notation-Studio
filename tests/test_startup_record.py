"""Regression for MuseScore's line-based FileIO reader and activation verification."""
from pathlib import Path
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QJSEngine
app=QCoreApplication([]);e=QJSEngine();root=Path(__file__).resolve().parents[1]
def run(code):
 v=e.evaluate(code);assert not v.isError(),v.toString();return v.toString()
def helpers(path):
 s=path.read_text();a=s.index('    function readStartupRecord()');b=s.index('    property var modelLists:',a);return s[a:b]
run('''var root={version:"0.10.10"},stored="",writes=0;
var Qt={resolvedUrl:function(s){return "file:///plugins/"+s;}};
function fileUrlToLocalPath(s){return s.replace("file://","");}
function extractPluginVersion(s){var m=s.match(/version\\s*:\\s*"([0-9]+\\.[0-9]+\\.[0-9]+)"/);return m?m[1]:"";}
var startupFile={source:"",read:function(){return this.source.indexOf(".qml")>=0?'version: "0.10.10"\\n\\n':stored+"\\n\\n";},write:function(s){stored=s;writes++;return true;}};
'''+helpers(root/'versions/AI-Notation-Studio-App-0.10.10.qml'))
assert run('persistRunningVersion()')=='false'
assert run('JSON.parse(stored).version')=='0.10.10'
print('Old code reports failure even though the record was successfully written')
run(helpers(root/'AI-Notation-Studio-App.qml'))
assert run('persistRunningVersion()')=='true'
assert run('writes')=='1' # Existing matching record should not be rewritten.
run('stored="";')
assert run('persistRunningVersion()')=='true'
assert run('writes')=='2'
run('stored="";startupFile.write=function(){return false;};')
assert run('persistRunningVersion()')=='false'
print('Parsed record comparison tolerates native read newlines and still reports real write failures')
