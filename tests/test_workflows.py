"""Tests each mode/strategy with deterministic provider replies; no paid AI calls."""
from pathlib import Path
import json
from lxml import etree
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QJSEngine
ROOT=Path(__file__).resolve().parents[1];app=QCoreApplication([]);e=QJSEngine();qml=(ROOT/'AI-Notation-Studio-App.qml').read_text()
def run(code):
 v=e.evaluate(code)
 if v.isError():raise AssertionError(v.toString())
 return v.toString()
def function(name):
 a=qml.index('    function '+name+'(');b=qml.find('\n    function ',a+5);return qml[a:b]
a=qml.index('function createCompactRuntime()');b=qml.index('    // END COMPACTSCORE RUNTIME',a)
run(qml[a:b]+';var compact=createCompactRuntime();')
class R(etree.Resolver):
 def resolve(self,url,pubid,context):
  if url.startswith('http'):return self.resolve_filename(str(ROOT/'tests/schema'/url.split('/')[-1]),context)
p=etree.XMLParser();p.resolvers.add(R());schema=etree.XMLSchema(etree.parse(str(ROOT/'tests/schema/musicxml.xsd'),p))
fixture=(ROOT/'tests/fixtures/Herbstlicher-Abendgesang.cs').read_text()
run('var sample='+json.dumps(fixture)+';var xml=compact.xml.convert(compact.score.decode(sample)).xml;')
base=run('xml')
# Native score merging retains all original notation and expression nodes.
for kind,start,parts,measures in [('newParts',0,2,16),('newParts',4,2,17),('append',64,1,32)]:
 result=json.loads(run('JSON.stringify(compact.context.combine(xml,xml,{kind:'+json.dumps(kind)+',startQuarter:'+str(start)+'}))'))
 d=etree.fromstring(result['xml'].encode());schema.assertValid(d)
 assert len(d.findall('part'))==parts and all(len(x.findall('measure'))==measures for x in d.findall('part'))
 assert d.find('.//pedal') is not None and d.find('.//slur') is not None
 if kind=='newParts':
  assert d.findall('part')[0].findtext('measure/note/pitch/step')=='A'
  if start:assert d.findall('part')[1].find('measure/note/rest') is not None
 print('Native context',kind,start,parts,measures,'OK')
assert run('compact.context.inspect(xml,5).prefixQuarter')=='1'
# Workflow API is controlled by queued replies to check the exact call sequence.
a=qml.index('    function providerModel(');b=qml.index('    function openCompactScore()',a)
run('''var compactInstructions="CompactScore CS1";var settings={keyOpenAI:"a-key",keyAnthropic:"b-key",keyGoogle:"c-key",modelOpenAI:"a",modelAnthropic:"b",modelGoogle:"c",compositionStrategy:0,sameStageModel:false,secondProvider:"Google",generalMemoryText:"legato"};
var apiKeyBox={text:"a-key"},modelBox={text:"a"},stageTwoModelBox={text:"c"},modeBox={currentIndex:2,currentText:"Free"},instrumentBox={currentText:"Klavier"},instructionBox={text:"Testauftrag"};
var selectionJson="reference",freeMeasures=16,freeInstrumentation="Klavier",compositionJob=null,compositionCosts=[],compositionIdea="",ideaReady=false,compositionJson="",compactSourceText="",compactWarnings=[],musicalDraft="",aiAnswer="",statusText="",busy=false;
var requests=[],queue=[],saved=0,files={};var curScore={title:"Original"};var Qt={resolvedUrl:function(x){return "file:///tmp/"+x;}};
var compactFile={source:"",read:function(){return files[this.source];}};
function providerName(){return "OpenAI";}function normalizedInstrumentation(){return ["piano"];}function contextTargetInstruments(){return ["piano"];}function contextMeasures(){return 16;}function selectionMeasureCount(){return 16;}
function selectionBounds(){return {startTick:0,endTick:30720};}function scoreEndTick(){return 30720;}
function fileUrlToLocalPath(x){return x.replace("file://","");}function writeScore(s,path){files[path]=xml;return true;}
function saveScoreMemory(){saved++;}function logEvent(){};
function callAI(prompt,callback,stage,format,options){requests.push({prompt:prompt,stage:stage,format:format,options:options});queue.push(callback);}
function acceptCompactText(text){var d=compact.score.decode(text),r=compact.xml.convert(d);compositionJson=JSON.stringify(d);compactSourceText=text;compactWarnings=r.warnings;}
'''+qml[a:b])
for mode in range(1,7):
 for strategy in range(3):
  run(f'settings.compositionStrategy={strategy};requests=[];queue=[];compositionJson="";modeBox.currentIndex={mode};compositionJob=prepareCompositionJob({mode});runCompositionJob(compositionJob);')
  assert run('requests.length')=='1'
  if strategy==0:
   assert run('requests[0].format.indexOf("CompactScore")>=0')=='true'
   run('queue.shift()(true,sample);')
  elif strategy==1:
   assert run('requests[0].prompt.indexOf("Noch keine vollständig ausnotierte")>=0')=='true'
   run('queue.shift()(true,"Eine Idee");')
   assert run('ideaReady')=='true' and run('requests.length')=='1' and run('busy')=='false'
   run('compositionIdea="Vom Nutzer geänderte Idee";composeFromIdea();')
   assert run('requests.length')=='2' and run('requests[1].prompt.indexOf("Vom Nutzer geänderte Idee")>=0')=='true'
   assert run('requests[1].options.provider')=='Google'
   run('queue.shift()(true,sample);')
  else:
   assert run('requests[0].prompt.indexOf("vollständige, endgültige")>=0')=='true'
   run('queue.shift()(true,"Ausgearbeitete Musik");')
   assert run('requests.length')=='2' and run('requests[1].prompt.indexOf("Ausgearbeitete Musik")>=0')=='true'
   assert run('requests[1].options.provider')=='Google'
   run('queue.shift()(true,sample);')
  assert run('busy')=='false' and run('compositionJson.length>0')=='true',(mode,strategy,run('statusText'))
  assert run('ideaReady')=='false'
 print('Mode',mode,'all three workflows OK')
# First-provider credentials and second-provider credentials must be checked before spending.
run('settings.compositionStrategy=1;settings.keyGoogle="";')
assert run('try {prepareCompositionJob(2);"bad"} catch(x){x.message.indexOf("Stufe 2")>=0}')=='true'
run('settings.keyGoogle="c-key";settings.sameStageModel=true;')
assert run('prepareCompositionJob(2).second.provider')=='OpenAI'
# Editing the main controls after stage 1 cannot change the captured job or erase its draft on failure.
run('settings.sameStageModel=false;settings.compositionStrategy=2;requests=[];queue=[];compositionJob=prepareCompositionJob(2);runCompositionJob(compositionJob);queue.shift()(true,"Fertige Musik");queue.shift()(false,"Netzwerkfehler");')
# The completed first-stage music survives a failed second stage.
assert run('compositionJob.draft')=='Fertige Musik'
assert run('busy')=='false'
run('requests=[];queue=[];compositionJob=prepareCompositionJob(2);runCompositionJob(compositionJob);queue.shift()(true,"Fertige Musik");')
run('instructionBox.text="anderer Auftrag";modeBox.currentIndex=5;')
assert run('compositionJob.instruction')=='Testauftrag'
assert run('requests[1].options.provider')=='Google'
# Actual cost registration captures the requested model and independent provider for each stage.
run('var lastUsage=null,lastPrices=null,lastCost=null,totalInputTokens=0,totalOutputTokens=0,totalCostUsd=0,unknownCosts=false,costText="";')
run(function('registerUsage'))
run('compositionCosts=[];registerUsage("Anthropic",{model:"claude-sonnet-5-5",usage:{input_tokens:1245,output_tokens:4543}},"claude-sonnet-5-5","Stufe 1",{jobId:compositionJob.id},1);')
assert abs(float(run('compositionCosts[0].cost.usd'))-.04792)<1e-9
run('registerUsage("Google",{usageMetadata:{promptTokenCount:100,candidatesTokenCount:200}},"unknown","Stufe 2",{jobId:compositionJob.id},2);')
assert 'unbekannte Kosten' in run('compositionCostText()')
assert run('compositionCosts[1].model')=='unknown'
print('Captured context/models, key preflight and per-stage cost ledger OK')
# Pickup, time changes and mid-measure range alignment are read from MusicXML timing, not a fixed grid.
run('var shortData=compact.score.decode("CS1\\nS {\\"t\\":\\"Test\\",\\"k\\":\\"C major\\",\\"m\\":\\"4/4\\"}\\nP {\\"i\\":\\"piano\\",\\"n\\":\\"piano\\"}\\n1/1 R:q C4:h.\\n1/2 R:w");var shortXML=compact.xml.convert(shortData).xml;')
merged=json.loads(run('JSON.stringify(compact.context.combine(xml,shortXML,{kind:"newParts",startQuarter:5}))'))
schema.assertValid(etree.fromstring(merged['xml'].encode()))
assert run('try {compact.context.combine(xml,xml,{kind:"newParts",startQuarter:5});"bad"} catch(x){x.message.indexOf("Anfangspausen")>=0}')=='true'
# Existing transposing instruments retain sounding pitch in the continuation.
run('var transposedBase=shortXML.replace("</attributes>","<transpose><diatonic>-1</diatonic><chromatic>-2</chromatic></transpose></attributes>");')
tr=json.loads(run('JSON.stringify(compact.context.combine(transposedBase,shortXML,{kind:"append",startQuarter:4}))'))
d=etree.fromstring(tr['xml'].encode());schema.assertValid(d)
assert d.findtext('part/measure[@number="2"]/note/pitch/step')=='D'
assert d.findtext('part/measure[@number="2"]/attributes/key/fifths')=='2'
assert d.findtext('part/measure[@number="2"]/attributes/transpose/chromatic')=='-2'
print('Mid-measure alignment and native instrument transposition OK')
# Explicit pickup length survives CS1 and shares the real source measure boundary.
run('var pickup=compact.score.decode("CS1\\nS {\\"t\\":\\"Auftakt\\",\\"k\\":\\"C major\\",\\"m\\":\\"4/4\\"}\\nP {\\"i\\":\\"piano\\",\\"n\\":\\"Klavier\\"}\\nB 1 {\\"actualDurationQuarters\\":1,\\"implicit\\":true}\\n1/1 C4:q\\n1/2 C3:q\\n2/1 D4:w\\n2/2 D3:w");var pickupXML=compact.xml.convert(pickup).xml;')
assert run('compact.context.inspect(pickupXML,1).startMeasure')=='2'
assert run('compact.context.inspect(pickupXML,1).end')=='5'
combined=json.loads(run('JSON.stringify(compact.context.combine(pickupXML,pickupXML,{kind:"newParts",startQuarter:0}))'))
d=etree.fromstring(combined['xml'].encode());schema.assertValid(d)
assert d.findtext('part/measure/attributes/staves')=='2'
assert d.find('part/measure').get('implicit')=='yes'
# Existing source notes and expressions are untouched in the combined copy.
original=etree.fromstring(run('pickupXML').encode())
assert etree.tostring(d.find('part'))==etree.tostring(original.find('part'))
assert len(set(n.get('id') for n in d.findall('.//score-part')))==2
assert len(set(n.text for n in d.findall('.//midi-channel')))==2
print('Pickup, German instrument aliases, original score preservation and channel allocation OK')
