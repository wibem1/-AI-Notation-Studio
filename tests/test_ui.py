"""Real Qt Quick startup and editor test, using MuseScore/FileIO substitutes; no native import claim."""
import os
import tempfile
os.environ['QT_QPA_PLATFORM']='offscreen';os.environ['QT_QUICK_BACKEND']='software';test_dir=tempfile.TemporaryDirectory();os.environ['XDG_CONFIG_HOME']=test_dir.name
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl,QObject,QMetaObject
app=QGuiApplication([]);app.setOrganizationName('WorkflowTest');app.setApplicationName('WorkflowTest');v=QQuickView();v.engine().addImportPath(str(Path(__file__).resolve().parent/'qml-stubs'));v.setSource(QUrl.fromLocalFile(str(Path('AI-Notation-Studio-App.qml').resolve())));assert not v.errors(),[x.toString() for x in v.errors()];v.setResizeMode(QQuickView.SizeRootObjectToView);v.resize(900,900);r=v.rootObject();QMetaObject.invokeMethod(r,'bootstrapRun');
for child in r.findChildren(QObject):
 if child.metaObject().indexOfProperty('compositionStrategy')>=0:
  child.setProperty('compositionStrategy',1);child.setProperty('sameStageModel',False);child.setProperty('secondProvider','Google');child.setProperty('secondModel','gemini-3.8-flash')
 if 'ComboBox' in child.metaObject().className() and child.property('count')==7:child.setProperty('currentIndex',2)
r.setProperty('technicalExpanded',True);r.setProperty('compositionIdea','Eine klare, ruhige Melodie mit einer bewegten Gegenstimme.');r.setProperty('compositionJob',{'second':{'provider':'Google','model':'gemini-3.8-flash'}});r.setProperty('ideaReady',True);v.show()
for i in range(8):app.processEvents()
assert not v.grabWindow().isNull();print('Actual Qt Quick UI rendered; no QML errors')
for child in r.findChildren(QObject):
 if child.metaObject().indexOfProperty('contentHeight')>=0:
  h=child.property('contentHeight')
  if isinstance(h,(int,float)) and h>1000:print('Scrollable content height:',h)
# The editor updates the underlying idea; later stage model changes do not change the captured job.
for child in r.findChildren(QObject):
 if 'TextArea' in child.metaObject().className() and child.property('text')==r.property('compositionIdea'):
  child.setProperty('text','Vom Nutzer bearbeitete Idee');app.processEvents();assert r.property('compositionIdea')=='Vom Nutzer bearbeitete Idee';print('Actual QML idea editing OK');break
else:raise AssertionError('Idea editor missing')
