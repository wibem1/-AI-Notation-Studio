"""MuseScore embedding regression: a fixed parent can exceed the actual native window."""
import os,sys,tempfile,json
from pathlib import Path
os.environ['QT_QPA_PLATFORM']='offscreen';os.environ['QT_QUICK_BACKEND']='software'
tmp=tempfile.TemporaryDirectory();os.environ['XDG_CONFIG_HOME']=tmp.name
if '--qt5' in sys.argv:
 from PyQt5.QtGui import QGuiApplication,QWheelEvent
 from PyQt5.QtQuick import QQuickView,QQuickItem
 from PyQt5.QtCore import QUrl,QPoint,QPointF,Qt,QCoreApplication
 from PyQt5.QtTest import QTest
else:
 from PySide6.QtGui import QGuiApplication,QWheelEvent
 from PySide6.QtQuick import QQuickView,QQuickItem
 from PySide6.QtCore import QUrl,QPoint,QPointF,Qt,QCoreApplication
 from PySide6.QtTest import QTest
ROOT=Path(__file__).resolve().parents[1]
app=QGuiApplication([]);app.setOrganizationName('ClippedWindowTests');app.setApplicationName('ClippedWindowTests')
def load(source):
 v=QQuickView();v.engine().addImportPath(str(ROOT/'tests/qml-stubs'))
 wrapper=Path(tmp.name)/(source.stem+'-Viewer.qml')
 wrapper.write_text('import QtQuick 2.2\nItem {width:900;height:900; Loader {anchors.fill:parent; source:'+json.dumps(QUrl.fromLocalFile(str(source)).toString())+'}}')
 v.setSource(QUrl.fromLocalFile(str(wrapper)));assert not v.errors(),v.errors()
 v.show();v.resize(900,500);QTest.qWait(100)
 return v,v.rootObject().findChild(QQuickItem,'compositionScroll')
# No expanded technical controls or idea editor: this was missing from earlier tests.
old,f=load(ROOT/'versions/AI-Notation-Studio-App-0.10.7.qml')
assert old.height()==500 and old.rootObject().height()==900
assert f.height()==864
if '--qt5' not in sys.argv:assert f.property('contentHeight')<=f.height()
assert f.property('contentHeight')>old.height()
print('Original failure reproduced: content clipped by native window but Flickable considers it fully visible')
old.close()
v,f=load(ROOT/'AI-Notation-Studio-App.qml');bar=v.rootObject().findChild(QQuickItem,'compositionScrollBar')
assert v.rootObject().height()==900 and v.height()==500
assert f.height()==464
assert f.property('contentHeight')>f.height()
point=bar.mapToScene(QPointF(9,bar.height()-10))
assert point.y()<v.height()
QTest.mouseClick(v,Qt.LeftButton,Qt.NoModifier,QPoint(int(point.x()),int(point.y())))
QTest.qWait(200);assert f.property('contentY')>0
f.setProperty('contentY',0)
pos=f.mapToScene(QPointF(f.width()-30,10))
QCoreApplication.sendEvent(v,QWheelEvent(pos,pos,QPoint(0,0),QPoint(0,-120),Qt.NoButton,Qt.NoModifier,Qt.NoScrollPhase,False))
QTest.qWait(250);assert f.property('contentY')>0
f.setProperty('contentY',f.property('contentHeight')-f.height())
assert f.property('contentY')>0
v.resize(900,400);QTest.qWait(100);assert f.height()==364
print('Actual clipped embedding scrolls by scrollbar and wheel, reaches bottom and follows window resize')
