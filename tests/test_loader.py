"""Host + actual app loading, recovery and Windows file URLs. Run with --qt5 or default Qt6."""
import os,sys,tempfile,json,subprocess
from pathlib import Path
os.environ['QT_QPA_PLATFORM']='offscreen';os.environ['QT_QUICK_BACKEND']='software'
config=tempfile.TemporaryDirectory();os.environ['XDG_CONFIG_HOME']=config.name
if '--qt5' in sys.argv:
 from PyQt5.QtGui import QGuiApplication
 from PyQt5.QtQuick import QQuickView
 from PyQt5.QtCore import QUrl,QObject,QMetaObject,qVersion
 from PyQt5.QtQml import QQmlComponent
else:
 from PySide6.QtGui import QGuiApplication
 from PySide6.QtQuick import QQuickView
 from PySide6.QtCore import QUrl,QObject,QMetaObject,qVersion
 from PySide6.QtQml import QQmlComponent
ROOT=Path(__file__).resolve().parents[1]
app=QGuiApplication([]);app.setOrganizationName('LoaderTests');app.setApplicationName('LoaderTests')
v=QQuickView();e=v.engine();e.addImportPath(str(ROOT/'tests/qml-stubs'))
# The earlier missing-Settings claim was a test-stub defect: MuseScore exports it.
old=subprocess.check_output(['git','show','ece06db88dcbb9d22488947ca7ab6882e2a127df:AI-Notation-Studio.qml'])
c=QQmlComponent(e);c.setData(old,QUrl.fromLocalFile(str(ROOT/'OldHost.qml')))
assert not c.errors(),[x.toString() for x in c.errors()]
print('Original host Settings resolves with faithful API stub:',qVersion())
v.setSource(QUrl.fromLocalFile(str(ROOT/'AI-Notation-Studio.qml')));assert not v.errors(),[x.toString() for x in v.errors()]
r=v.rootObject();assert r
assert r.property('implicitHeight')<=app.primaryScreen().availableGeometry().height()-100
assert r.property('implicitWidth')<=app.primaryScreen().availableGeometry().width()-80
v.setResizeMode(QQuickView.SizeRootObjectToView);v.resize(900,900)
for file in r.findChildren(QObject):
 if file.metaObject().indexOfProperty('data')>=0 and file.metaObject().indexOfProperty('source')>=0:file.setProperty('data',(ROOT/'AI-Notation-Studio-App.qml').read_text())
# Simulate a previously saved 0.10.3 app; the new bundled URL must win.
for child in r.findChildren(QObject):
 if child.metaObject().indexOfProperty('activeHotAppSource')>=0:
  child.setProperty('activeHotAppSource',QUrl.fromLocalFile(str(ROOT/'versions/AI-Notation-Studio-App-0.10.3.qml')).toString())
  child.setProperty('activeHotAppVersion','0.10.3')
QMetaObject.invokeMethod(r,'run');v.show()
for i in range(10):app.processEvents()
assert r.property('width')==v.width() and r.property('height')==v.height(),(r.property('width'),r.property('height'),v.width(),v.height())
assert r.property('hotAppActive'),r.property('updateStatus')
assert r.property('title')=='AI Notation Studio'
assert any(x.property('version')=='0.10.7' for x in r.findChildren(QObject))
assert not any(x.property('version')=='0.10.3' for x in r.findChildren(QObject))
if '--qt5' not in sys.argv:assert not v.grabWindow().isNull()
e.globalObject().setProperty('host',e.newQObject(r))
def js(code):
 val=e.evaluate(code)
 if val.isError():raise AssertionError(val.toString())
 return val.toString()
# C: drive, percent escapes, unicode, UNC, literal #, POSIX and localhost.
cases=[('file:///C:/Users/Wilhelm/My%20Plugins/a.qml','C:/Users/Wilhelm/My Plugins/a.qml'),('file://localhost/C:/Plugins/a.qml','C:/Plugins/a.qml'),('file:///home/user/My%20Plugins/a.qml','/home/user/My Plugins/a.qml'),('file://server/share/Plugins/a.qml','//server/share/Plugins/a.qml'),('file:///C:/Users/M%C3%BCller/a%23b.qml','C:/Users/Müller/a#b.qml')]
for source,path in cases:
 assert js('host.fileUrlToLocalPath('+json.dumps(source)+')')==path
 assert js('host.fileUrlToLocalPath(host.normalizedAppUrl('+json.dumps(source)+'))')==path
assert js('host.normalizedAppUrl("C:\\\\Users\\\\Wilhelm\\\\Plugins\\\\a.qml")')=='file:///C:/Users/Wilhelm/Plugins/a.qml'
# A missing cached file must not conceal the functional host surface.
js('host.activateHotApp("file:///no-such-app.qml","0.10.7")')
for i in range(10):app.processEvents()
assert not r.property('hotAppActive') and not r.property('hotAppRequested')
assert 'nicht gestartet' in r.property('updateStatus')
assert 'no-such-app.qml' in r.property('startupDetails')
# Compilation errors (including missing imports) must be visible, not only logged.
bad=Path(config.name)/'BadApp.qml';bad.write_text('import MissingModuleForStartupTest 1.0\nItem {}')
js('host.activateHotApp('+json.dumps(QUrl.fromLocalFile(str(bad)).toString())+',"0.10.7")')
for i in range(10):app.processEvents()
assert not r.property('hotAppActive')
assert 'MissingModuleForStartupTest' in r.property('startupDetails')
if '--qt5' not in sys.argv:
 shot=v.grabWindow();assert shot.pixelColor(4,4).name()=='#202124'
 assert shot.save(str(Path(config.name)/'startup-fallback.png'))
# The complete actual app must load through the host, not only as a standalone root.
url=QUrl.fromLocalFile(str(ROOT/'AI-Notation-Studio-App.qml')).toString()
js('host.activateHotApp('+json.dumps(url)+',"0.10.7")')
for i in range(30):app.processEvents()
assert r.property('hotAppActive'),r.property('updateStatus')
assert r.property('hotAppRequested')
assert r.property('width')==v.width() and r.property('height')==v.height(),(r.property('width'),r.property('height'),v.width(),v.height())
if '--qt5' not in sys.argv:assert not v.grabWindow().isNull()
assert any(x.property('version')=='0.10.7' and x.property('title')=='AI Notation Studio – interne App (nicht starten)' for x in r.findChildren(QObject))
print('Host rendered, Windows/UNC paths and missing-app fallback OK; full app loaded:',qVersion())
