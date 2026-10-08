"""Actual model-list JS: provider auth, filtering, pagination, caching and failures."""
from pathlib import Path
import json
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QJSEngine
app=QCoreApplication([]);e=QJSEngine();qml=(Path(__file__).resolve().parents[1]/'AI-Notation-Studio-App.qml').read_text()
a=qml.index('    function modelChoices(');b=qml.index('    property string compactInstructions:',a)
def run(code):
 r=e.evaluate(code);assert not r.isError(),r.toString();return r.toString()
run('''var settings={secondProvider:"Google",secondModel:"gemini-custom"};
var selected={OpenAI:"gpt-custom",Anthropic:"claude-custom",Google:"gemini-custom"};
var keys={OpenAI:"TEST_OPENAI_SECRET",Anthropic:"TEST_ANTHROPIC_SECRET",Google:"TEST_GOOGLE_SECRET"};
function providerModel(p){return selected[p];}function providerKey(p){return keys[p];}
var modelLists={},modelListBusy=false,modelListStatus="",modelListGeneration=0,modelListRequest=null,modelCatalogSettings={modelsJson:"{}"},requests=[];
function XMLHttpRequest(){this.headers={};requests.push(this);}
XMLHttpRequest.DONE=4;
XMLHttpRequest.prototype.open=function(m,u){this.url=u;};
XMLHttpRequest.prototype.setRequestHeader=function(k,v){this.headers[k]=v;};
XMLHttpRequest.prototype.send=function(){};
function reply(i,data,status){var r=requests[i];r.responseText=JSON.stringify(data);r.status=status||200;r.readyState=4;r.onreadystatechange();}
'''+qml[a:b])
run('loadModels("OpenAI");')
assert run('requests[0].headers.Authorization')=='Bearer TEST_OPENAI_SECRET'
run('reply(0,{data:[{id:"gpt-test-a"},{id:"o-test-other"},{id:"o4-mini-test"},{id:"gpt-test-a"},{id:"gpt-audio-test"},{id:"text-embedding-test"}]});')
assert json.loads(run('JSON.stringify(modelLists.OpenAI)'))==['gpt-test-a','o4-mini-test']
assert json.loads(run('JSON.stringify(modelChoices("OpenAI"))'))[0]=='gpt-custom'
assert run('modelListBusy')=='false'
run('loadModels("Anthropic");reply(1,{data:[{id:"claude-test-a"},{id:"claude-retired",lifecycle:"retired"}],has_more:true,last_id:"claude-test-a"});')
assert 'after_id=claude-test-a' in run('requests[2].url')
assert run('requests[2].headers["x-api-key"]')=='TEST_ANTHROPIC_SECRET'
assert run('requests[2].headers["anthropic-version"]')=='2023-06-01'
run('reply(2,{data:[{id:"claude-test-b"}],has_more:false});')
assert json.loads(run('JSON.stringify(modelLists.Anthropic)'))==['claude-test-a','claude-test-b']
run('loadModels("Google");reply(3,{models:[{name:"models/gemini-text-a",supportedGenerationMethods:["generateContent"]},{name:"models/embedding",supportedGenerationMethods:["embedContent"]},{name:"models/gemini-image",supportedGenerationMethods:["generateContent"]}],nextPageToken:"page two"});')
assert 'pageToken=page%20two' in run('requests[4].url')
assert run('requests[4].headers["x-goog-api-key"]')=='TEST_GOOGLE_SECRET'
run('reply(4,{models:[{name:"models/gemini-text-b",supportedGenerationMethods:["generateContent"]}]});')
assert json.loads(run('JSON.stringify(modelLists.Google)'))==['gemini-text-a','gemini-text-b']
cache=run('modelCatalogSettings.modelsJson');assert 'SECRET' not in cache
run('loadModels("OpenAI");reply(5,{error:"bad key"},401);')
assert run('modelListBusy')=='false' and '401' in run('modelListStatus')
assert json.loads(run('JSON.stringify(modelLists.OpenAI)'))==['gpt-test-a','o4-mini-test']
run('keys.Google="";loadModels("Google");')
assert run('requests.length')=='6' and 'API-Key' in run('modelListStatus')
# Late replies after timeout/cancellation cannot replace the cached list.
run('loadModels("Anthropic");modelListGeneration++;modelListBusy=false;reply(6,{data:[{id:"late-model"}]});')
assert json.loads(run('JSON.stringify(modelLists.Anthropic)'))==['claude-test-a','claude-test-b']
print('Three provider auth paths, pagination/filtering, saved custom choice, key-free cache and failure preservation OK')
