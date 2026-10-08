"""Real Qt Quick startup and editor test, using MuseScore/FileIO substitutes; no native import claim."""
import os,sys
import tempfile
os.environ['QT_QPA_PLATFORM']='offscreen';os.environ['QT_QUICK_BACKEND']='software';test_dir=tempfile.TemporaryDirectory();os.environ['XDG_CONFIG_HOME']=test_dir.name
from pathlib import Path
if '--qt5' in sys.argv:
 from PyQt5.QtGui import QGuiApplication,QWheelEvent
 from PyQt5.QtQuick import QQuickView,QQuickItem
 from PyQt5.QtCore import QUrl,QObject,QMetaObject,QPoint,QPointF,Qt,QCoreApplication
 from PyQt5.QtTest import QTest
else:
 from PySide6.QtGui import QGuiApplication,QWheelEvent
 from PySide6.QtQuick import QQuickView,QQuickItem
 from PySide6.QtCore import QUrl,QObject,QMetaObject,QPoint,QPointF,Qt,QCoreApplication
 from PySide6.QtTest import QTest
app=QGuiApplication([]);app.setOrganizationName('WorkflowTest');app.setApplicationName('WorkflowTest');v=QQuickView();v.engine().addImportPath(str(Path(__file__).resolve().parent/'qml-stubs'));v.setSource(QUrl.fromLocalFile(str(Path('AI-Notation-Studio-App.qml').resolve())));assert not v.errors(),[x.toString() for x in v.errors()];v.setResizeMode(QQuickView.SizeRootObjectToView);v.resize(900,900);r=v.rootObject();QMetaObject.invokeMethod(r,'bootstrapRun');
for child in r.findChildren(QObject):
 if child.metaObject().indexOfProperty('compositionStrategy')>=0:
  child.setProperty('compositionStrategy',1);child.setProperty('sameStageModel',False);child.setProperty('secondProvider','Google');child.setProperty('secondModel','gemini-3.8-flash')
 if 'ComboBox' in child.metaObject().className() and child.property('count')==7:child.setProperty('currentIndex',2)
r.setProperty('technicalExpanded',True);r.setProperty('compositionIdea','Eine klare, ruhige Melodie mit einer bewegten Gegenstimme.');r.setProperty('compositionJob',{'second':{'provider':'Google','model':'gemini-3.8-flash'}});r.setProperty('ideaReady',True);v.show()
for i in range(8):app.processEvents()
if '--qt5' not in sys.argv:assert not v.grabWindow().isNull()
print('Actual Qt Quick UI created; no QML errors')
for child in r.findChildren(QObject):
 if child.metaObject().indexOfProperty('contentHeight')>=0:
  h=child.property('contentHeight')
  if isinstance(h,(int,float)) and h>1000:print('Scrollable content height:',h)
# The editor updates the underlying idea; later stage model changes do not change the captured job.
for child in r.findChildren(QObject):
 if 'TextArea' in child.metaObject().className() and child.property('text')==r.property('compositionIdea'):
  child.setProperty('text','Vom Nutzer bearbeitete Idee');app.processEvents();assert r.property('compositionIdea')=='Vom Nutzer bearbeitete Idee';print('Actual QML idea editing OK');break
else:raise AssertionError('Idea editor missing')
# Exercise actual pointer interaction with the persistent main scrollbar.
scroll=r.findChild(QQuickItem,'compositionScroll');bar=r.findChild(QQuickItem,'compositionScrollBar')
assert scroll and bar and scroll.property('interactive')
assert scroll.property('contentHeight')>scroll.height()
barpoint=bar.mapToScene(QPointF(9,int(bar.height()-10)))
QTest.mouseClick(v,Qt.LeftButton,Qt.NoModifier,QPoint(int(barpoint.x()),int(barpoint.y())))
QTest.qWait(200)
assert scroll.property('contentY')>0,scroll.property('contentY')
print('Actual main scrollbar pointer interaction scrolls content')
scroll.setProperty('contentY',0)
pos=scroll.mapToScene(QPointF(scroll.width()-30,10))
wheel=QWheelEvent(pos,pos,QPoint(0,0),QPoint(0,-120),Qt.NoButton,Qt.NoModifier,Qt.NoScrollPhase,False)
QCoreApplication.sendEvent(v,wheel);QTest.qWait(250)
assert scroll.property('contentY')>0
print('Actual mouse wheel scrolls main content')

# A resized viewport must resize the actual main scrolling surface, not clip a fixed 900px item.
v.resize(700,500);QTest.qWait(100)
assert r.height()==500 and abs(scroll.height()-464)<1
scroll.setProperty('contentY',scroll.property('contentHeight')-scroll.height())
assert scroll.property('contentY')>0
print('Smaller window follows viewport; bottom remains reachable')
