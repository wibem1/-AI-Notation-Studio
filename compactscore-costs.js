/* CompactScore AI 0.2.0 — provider adapters and token-based standard USD costs. */
(function(root){
'use strict';
const SOURCES={openai:'https://developers.openai.com/api/docs/models/',anthropic:'https://platform.claude.com/docs/en/about-claude/pricing',google:'https://ai.google.dev/gemini-api/docs/pricing'};
const CATALOG={
 openai:[{id:'gpt-6.1-sol',name:'GPT-6.1 Sol',input:2,output:10,read:.1,write:2.5},{id:'gpt-6-luna',name:'GPT-6 Luna',input:.1,output:.5,read:.01,write:.125},{id:'gpt-6-astra',name:'GPT-6 Astra',input:10,output:50,read:1,write:12.5}],
 anthropic:[{id:'claude-sonnet-5-5',name:'Claude Sonnet 5.5',input:2,output:10,read:.2,write:2.5,writeHour:4},{id:'claude-opus-5-5',name:'Claude Opus 5.5',input:4,output:20,read:.2,write:5,writeHour:8},{id:'claude-haiku-4-5',name:'Claude Haiku 4.5',input:1,output:5,read:.1,write:1.25,writeHour:2},{id:'claude-sonnet-5',name:'Claude Sonnet 5',input:2,output:10,read:.2,write:2.5,writeHour:4},{id:'claude-sonnet-4-6',name:'Claude Sonnet 4.6',input:3,output:15,read:.3,write:3.75,writeHour:6},{id:'claude-opus-5',name:'Claude Opus 5',input:5,output:25,read:.5,write:6.25,writeHour:10}],
 google:[{id:'gemini-3.8-flash',name:'Gemini 3.8 Flash',input:.75,output:3.75,read:.075,write:0,validUntil:'2026-12-31',future:{input:1.5,output:7.5,read:.15}},{id:'gemini-3.1-flash-lite',name:'Gemini 3.1 Flash-Lite',input:.25,output:1.5,read:.025,write:0}]
};
const validCount=x=>typeof x==='number'&&Number.isFinite(x)&&x>=0;
const zero=x=>validCount(x)?x:0;
function prices(provider,model,now=new Date()){
 const m=(CATALOG[provider]||[]).find(m=>m.id===model||model.startsWith(m.id+'-20'));if(!m)return null;
 const p={...m,source:SOURCES[provider],verified:'2026-10-06'};if(m.future&&now.toISOString().slice(0,10)>m.validUntil)Object.assign(p,m.future);return p;
}
function usage(provider,response){
 const u=provider==='google'?response.usageMetadata:response.usage;if(!u)return null;
 let input,output,thinking=null,read=0,write=0,writeHour=0,regular;
 if(provider==='openai'){
  input=u.input_tokens;output=u.output_tokens;read=zero(u.input_tokens_details?.cached_tokens);write=zero(u.input_tokens_details?.cache_write_tokens);thinking=validCount(u.output_tokens_details?.reasoning_tokens)?u.output_tokens_details.reasoning_tokens:null;
  regular=validCount(input)?Math.max(0,input-read-write):null;
 }else if(provider==='anthropic'){
  regular=u.input_tokens;read=zero(u.cache_read_input_tokens);write=zero(u.cache_creation_input_tokens);writeHour=zero(u.cache_creation?.ephemeral_1h_input_tokens);write=Math.max(0,write-writeHour);input=validCount(regular)?regular+read+write+writeHour:null;output=u.output_tokens;
  if(validCount(u.output_tokens_details?.thinking_tokens))thinking=u.output_tokens_details.thinking_tokens;else if(validCount(u.thinking_tokens))thinking=u.thinking_tokens;
 }else if(provider==='google'){
  input=u.promptTokenCount;read=zero(u.cachedContentTokenCount);thinking=zero(u.thoughtsTokenCount);
  if(validCount(u.candidatesTokenCount))output=u.candidatesTokenCount+thinking;
  else if(validCount(u.totalTokenCount)&&validCount(input))output=Math.max(0,u.totalTokenCount-input-zero(u.toolUsePromptTokenCount));
  else output=null;
  regular=validCount(input)?Math.max(0,input-read):null;
 }
 if(!validCount(input)||!validCount(output))return null;
 return {input,output,thinking,cacheRead:read,cacheWrite:write+writeHour,write5m:write,writeHour,regularInput:regular,total:input+output,raw:u};
}
function cost(tokens,p){
 if(!tokens||!p)return null;
 const needed=['input','output'];if(tokens.cacheRead)needed.push('read');if(tokens.write5m)needed.push('write');if(tokens.writeHour)needed.push('writeHour');
 if(!needed.every(k=>validCount(p[k])))return null;
 const input=tokens.regularInput*p.input/1e6,output=tokens.output*p.output/1e6,cacheRead=tokens.cacheRead*(p.read||0)/1e6,cacheWrite=(tokens.write5m*(p.write||0)+tokens.writeHour*(p.writeHour||0))/1e6;
 return {usd:input+output+cacheRead+cacheWrite,input,output,cacheRead,cacheWrite};
}
function response(provider,data){
 let text='',truncated=false,finish='';
 if(provider==='openai'){
  text=typeof data.output_text==='string'?data.output_text:(data.output||[]).filter(x=>x.type==='message').reduce((a,x)=>a.concat(x.content||[]),[]).filter(x=>x.type==='output_text').map(x=>x.text||'').join('\n');
  truncated=data.status==='incomplete';finish=data.incomplete_details?.reason||data.status||'';
 }else if(provider==='anthropic'){
  text=(data.content||[]).filter(x=>x.type==='text').map(x=>x.text||'').join('\n');truncated=data.stop_reason==='max_tokens';finish=data.stop_reason||'';
 }else if(provider==='google'){
  const c=data.candidates?.[0];text=(c?.content?.parts||[]).filter(x=>!x.thought&&typeof x.text==='string').map(x=>x.text).join('\n');truncated=c?.finishReason==='MAX_TOKENS';finish=c?.finishReason||data.promptFeedback?.blockReason||'';
 }
 return {text,truncated,finish,tokens:usage(provider,data),model:data.model||data.modelVersion||null};
}
function sanitize(text,secrets=[]){let s=String(text||'');for(const secret of secrets)if(secret&&secret.length>3)s=s.split(secret).join('[Schlüssel entfernt]');return s;}
const api={prices,usage,cost,response,sanitize};if(typeof module!=='undefined'&&module.exports)module.exports=api;root.CompactAI=api;})(typeof globalThis!=='undefined'?globalThis:this);