"""Exercise the shipped updater's callbacks and FileIO installation in Qt JS; no network."""
from pathlib import Path
import json
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QJSEngine
app=QCoreApplication([]);e=QJSEngine()
qml=(Path(__file__).resolve().parents[1]/'AI-Notation-Studio-App.qml').read_text()
a=qml.index('    function currentVersionString()');b=qml.index('    function scoreMemoryTagName()',a)
def run(code):
 v=e.evaluate(code)
 assert not v.isError(),v.toString()
 return v.toString()
run('''var root={version:"0.10.5"},settings={},hotAppActive=false,hotAppRequested=false,hotAppVersion="";
var updateBusy=false,updateRemoteVersion="",updateSourceText="",updateIsHotApp=false,updateStatus="",updaterTargetPath="";
var requests=[],writes={},hotAppLoader={source:""};
var Qt={resolvedUrl:function(s){return "file:///C:/Users/Test/Plugins/"+s;},callLater:function(f){f();}};
var updaterFile={source:"",write:function(text){writes[this.source]=text;return true;},read:function(){return writes[this.source];}};
function XMLHttpRequest(){requests.push(this);this.readyState=0;this.status=0;}
XMLHttpRequest.DONE=4;
XMLHttpRequest.prototype.open=function(method,url){this.url=url;};
XMLHttpRequest.prototype.setRequestHeader=function(){};
XMLHttpRequest.prototype.send=function(){};
'''+qml[a:b])
remote=qml.replace('version: "0.10.5"','version: "0.10.6"',1)
run('var remote='+json.dumps(remote)+';checkForUpdate();')
assert run('updateBusy')=='true'
run('var req=requests[0];req.status=200;req.responseText=remote;req.readyState=4;req.onreadystatechange();')
assert run('updateBusy')=='false'
assert run('updateRemoteVersion')=='0.10.6'
assert run('updateSourceText===remote && updateIsHotApp')=='true'
# Duplicate completion must not process or revert the result.
run('req.responseText="invalid";req.onreadystatechange();')
assert run('updateRemoteVersion')=='0.10.6'
run('installUpdate();')
assert run('writes["C:/Users/Test/Plugins/AI-Notation-Studio-App-0.10.6.qml"]===remote')=='true'
assert run('hotAppLoader.source')=='file:///C:/Users/Test/Plugins/AI-Notation-Studio-App-0.10.6.qml'
assert run('hotAppRequested')=='true'
assert run('settings.activeHotAppVersion')=='0.10.6'
assert run('updateSourceText')==''
# Equal versions are reported as current.
run('hotAppActive=false;checkForUpdate();var equal=requests[1];equal.status=200;equal.responseText='+json.dumps(qml)+';equal.readyState=4;equal.onreadystatechange();')
assert 'Aktuell' in run('updateStatus')
assert run('updateBusy')=='false'
# Failed remote app request reaches the existing fallback and releases busy state.
run('checkForUpdate();var bad=requests[2];bad.status=404;bad.readyState=4;bad.onreadystatechange();')
assert run('requests.length')=='4'
run('var fallback=requests[3];fallback.status=503;fallback.readyState=4;fallback.onreadystatechange();')
assert run('updateBusy')=='false'
assert '503' in run('updateStatus')
print('Update callback, duplicate response, version comparison, Windows installation and HTTP error handling OK')
