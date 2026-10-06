"""Run: python tests/test_compactscore.py (PySide6 + lxml). Tests the embedded Qt runtime, not only source JS."""
from pathlib import Path
from tempfile import TemporaryDirectory
import json
from lxml import etree
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QJSEngine
ROOT=Path(__file__).resolve().parents[1]
app=QCoreApplication([])
engine=QJSEngine()
qml=(ROOT/'AI-Notation-Studio-App.qml').read_text()
a=qml.index('function createCompactRuntime()');b=qml.index('    // END COMPACTSCORE RUNTIME',a)
def run(code):
    v=engine.evaluate(code)
    if v.isError():raise AssertionError(v.toString())
    return v.toString()
run(qml[a:b]+'\nvar compact=createCompactRuntime();')
class LocalSchema(etree.Resolver):
    def resolve(self,url,pubid,context):
        if url.startswith('http'):return self.resolve_filename(str(ROOT/'tests/schema'/url.split('/')[-1]),context)
p=etree.XMLParser();p.resolvers.add(LocalSchema())
schema=etree.XMLSchema(etree.parse(str(ROOT/'tests/schema/musicxml.xsd'),p))
for name,parts in [('Elegie',2),('Herbstlicher-Abendgesang',1)]:
    text=(ROOT/'tests/fixtures'/f'{name}.cs').read_text()
    run('var data=compact.score.decode('+json.dumps(text)+');var original=JSON.stringify(data);')
    assert run('JSON.stringify(compact.score.decode(compact.score.encode(data)))===original')=='true'
    result=json.loads(run('JSON.stringify(compact.xml.convert(data))'))
    assert result['measures']==16 and result['parts']==parts and not result['warnings']
    assert run('JSON.stringify(data)===original')=='true'
    d=etree.fromstring(result['xml'].encode());schema.assertValid(d)
    assert len(d.findall('part'))==parts
    assert len(d.findall('.//part[@id="P1"]/measure'))==16
    assert d.find('.//divisions') is not None
    assert d.find('.//slur') is not None and d.find('.//pedal') is not None
    # Both hands retain a fixed staff allocation.
    piano=d.findall('part')[-1]
    for n in piano.findall('.//note'):
        if n.findtext('voice')=='2':assert n.findtext('staff')=='2'
    if name=='Elegie':
        assert len(d.findall('.//breath-mark'))==2
        assert len(d.findall('.//wavy-line'))==2
        assert len(d.findall('.//time-modification'))>0
        assert d.find('.//pitch[octave="0"]') is not None
    print(name+': Qt roundtrip, native notation, MusicXML XSD OK')
assert run('compact.ai.response("anthropic",{content:[{type:"thinking",thinking:"x"},{type:"text",text:"CS1"},{type:"text",text:"S {}"}]}).text')=='CS1\nS {}'
assert run('compact.ai.response("google",{candidates:[{content:{parts:[{thought:true,text:"secret"},{text:"CS1"}]},finishReason:"MAX_TOKENS"}]}).truncated')=='true'
assert run('compact.ai.response("openai",{output:[{type:"message",content:[{type:"output_text",text:"CS1"}]}]}).text')=='CS1'
run('var tokens=compact.ai.usage("anthropic",{usage:{input_tokens:1245,output_tokens:4543,output_tokens_details:{thinking_tokens:2969}}});')
assert run('tokens.thinking')=='2969'
cost=json.loads(run('JSON.stringify(compact.ai.cost(tokens,compact.ai.prices("anthropic","claude-sonnet-5-5")))'))
assert abs(cost['usd']-.04792)<1e-10
assert run('compact.ai.cost(tokens,compact.ai.prices("anthropic","unknown"))===null')=='true'
assert run('compact.ai.sanitize("key secret123",["secret123"])')=='key [Schlüssel entfernt]'
# Actual application import/open functions with a FileIO / MuseScore test double.
a=qml.index('    function isCompactResult()');b=qml.index('    Dialog {\n        id: compactImportDialog',a)
run('''var compositionJson="",compactSourceText="",compactWarnings=[],musicalDraft="",aiAnswer="",statusText="",busy=false;
var files={},opened=[],metatags={};var Qt={resolvedUrl:function(p){return "file:///tmp/"+p;}};
var compactFile={source:"",write:function(x){files[this.source]=x;return true;},read:function(){return files[this.source];}};
function fileUrlToLocalPath(x){return x.replace("file://","");}
function readScore(p){opened.push(p);return {setMetaTag:function(k,v){metatags[k]=v;}};}
function scoreMemoryTagName(){return "memory";}function currentScoreMemoryObject(){return {compositionJson:compositionJson,compactSourceText:compactSourceText};}
function logEvent(){};
'''+qml[a:b])
run('acceptCompactText('+json.dumps((ROOT/'tests/fixtures/Elegie.cs').read_text())+');openCompactScore();')
assert run('opened.length')=='1'
assert run('metatags["AI-Notation-Studio-Source-CS1"].indexOf("CS1")')=='0'
assert 'Neue Partitur' in run('statusText')
print('Provider responses, truncation, costs, redaction and application import/open OK')
# Exercise request construction and the actual asynchronous callback for all three providers.
a=qml.index('    function callAI(');b=qml.index('    function sendToAI()',a)
run('''var provider="OpenAI",modelBox={text:"test-model"},apiKeyBox={text:"secret123"},request=null,result=null;
function providerName(){return provider;}function redact(s){return compact.ai.sanitize(s,["secret123"]);}
function registerUsage(){};
function XMLHttpRequest(){request=this;this.headers={};this.open=function(m,u){this.url=u;};this.setRequestHeader=function(k,v){this.headers[k]=v;};this.send=function(b){this.body=JSON.parse(b);};}
XMLHttpRequest.DONE=4;
'''+qml[a:b])
for provider,payload in [('OpenAI',{'output_text':'CS1'}),('Anthropic',{'content':[{'type':'text','text':'CS1'}]}),('Google',{'candidates':[{'content':{'parts':[{'text':'CS1'}]}}]})]:
    run('provider='+json.dumps(provider)+';callAI("task",function(ok,text){result={ok:ok,text:text};},"test","format");')
    req=json.loads(run('JSON.stringify({body:request.body,url:request.url,headers:request.headers})'))
    assert 'secret123' not in req['url']
    if provider=='OpenAI':assert req['body']['instructions']=='format' and req['body']['max_output_tokens']==32768
    if provider=='Anthropic':assert req['body']['system']=='format' and req['body']['max_tokens']==32768
    if provider=='Google':assert req['headers']['x-goog-api-key']=='secret123' and req['body']['generationConfig']['maxOutputTokens']==32768
    run('request.status=200;request.readyState=4;request.responseText='+json.dumps(json.dumps(payload))+';request.onreadystatechange();')
    assert json.loads(run('JSON.stringify(result)'))=={'ok':True,'text':'CS1'}
print('OpenAI, Anthropic and Google request/callback contracts OK')
