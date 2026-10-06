/* CompactScore 0.1.0 — dependency-free Maxi/Mini transfer codec. */
(function(root){
'use strict';
const VERSION='0.1.0';
const DUR={whole:'w',half:'h',quarter:'q',eighth:'e','16th':'s','32nd':'t','64th':'x','128th':'z',breve:'b'};
const REV=Object.fromEntries(Object.entries(DUR).map(([a,b])=>[b,a]));
// Aliases are scoped; every source key is carried alongside its alias dictionary.
const SC={title:'t',composer:'c',key:'k',timeSignature:'m',tempo:'b'};
const PT={id:'i',instrument:'n'};
const EV={id:'i',dynamic:'d',articulations:'a',articulation:'A',expressionText:'e',slur:'s',tie:'l',ornament:'o',fermata:'f',arpeggio:'r',ratio:'u'};
const MK={type:'t',position:'p',value:'v',text:'x',start:'s',end:'e',startRef:'a',endRef:'b',style:'l',kind:'k',tempo:'q'};
const POS={measure:'m',beat:'b'}; const TMP={text:'x',bpm:'v'};
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
function object(o){return o && typeof o==='object' && !Array.isArray(o);}
function assign(o,k,v){Object.defineProperty(o,k,{value:v,enumerable:true,writable:true,configurable:true});}
function map(o,dict,reverse=false){
 if(!object(o)) throw Error('Ein Objekt wird erwartet.');
 const result={}; const d=reverse?Object.fromEntries(Object.entries(dict).map(([k,v])=>[v,k])):dict;
 for(const [k,v] of Object.entries(o)){
  const key=reverse?(k.startsWith('~')?k.slice(1):(d[k]||k)):(d[k]||'~'+k);
  if(own(result,key)) throw Error('Doppeltes Feld: '+key);
  assign(result,key,v);
 }
 return result;
}
function meta(o,d,reverse=false){const r=map(o,d,reverse); if(own(r,reverse?'tempo':'b')){const k=reverse?'tempo':'b';if(object(r[k]))r[k]=map(r[k],TMP,reverse);}return r;}
function marking(m,reverse=false){const r=map(m,MK,reverse); for(const k of (reverse?['position','start','end']:['p','s','e']))if(object(r[k]))r[k]=map(r[k],POS,reverse);const k=reverse?'tempo':'q';if(object(r[k]))r[k]=map(r[k],TMP,reverse);return r;}
function omit(o,keys){const r={};for(const [k,v]of Object.entries(o))if(!keys.includes(k))assign(r,k,v);return r;}
function json(v){return JSON.stringify(v);}
function suffix(attrs){return Object.keys(attrs).length?json(map(attrs,EV)):'';}
function event(e){
 if(!object(e))throw Error('Ungültiges Ereignis.');
 if(e.type==='tupletEnd' && Object.keys(e).length===1)return ')';
 if(e.type==='tupletStart' && /^\d+:\d+$/.test(e.ratio||'') && (!own(e,'duration')||own(DUR,e.duration))){const extra=omit(e,['type','ratio','duration']);return '('+e.ratio+(e.duration?':'+DUR[e.duration]:'')+suffix(extra);}
 if(['note','rest','chord'].includes(e.type)&&own(DUR,e.duration)&&(!own(e,'dots')||(Number.isInteger(e.dots)&&e.dots>=1&&e.dots<=4))){
  let p=e.type==='rest'?'R':e.type==='note'?e.pitch:Array.isArray(e.pitches)?'['+e.pitches.join(',')+']':null;
  const validPitch=x=>/^[A-G](?:bb|##|b|#)?-?\d+$/.test(x);
  if(p && (e.type==='rest'||e.type==='note'&&validPitch(p)||e.type==='chord'&&e.pitches.length&&e.pitches.every(validPitch))){
   return p+':'+DUR[e.duration]+'.'.repeat(e.dots||0)+suffix(omit(e,['type',e.type==='note'?'pitch':e.type==='chord'?'pitches':'__none','duration','dots']));
  }
 }
 return 'J'+json(e); // Explicit escape; never discard unsupported data.
}
function splitTokens(line){
 const out=[];let begin=0,depth=0,quoted=false,escape=false;
 for(let i=0;i<=line.length;i++){
  const c=line[i];if(quoted){if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')quoted=false;continue;}
  if(c==='"'){quoted=true;continue;}if(c==='{'||c==='[')depth++;if(c==='}'||c===']')depth--;
  if(depth<0)throw Error('Unpassende schließende Klammer.');
  if((c===undefined||/\s/.test(c))&&depth===0){if(i>begin)out.push(line.slice(begin,i));begin=i+1;}
 }
 if(quoted||depth)throw Error('Nicht abgeschlossene Zeichenkette oder Klammer.');return out;
}
function decodeEvent(token){
 if(token===')')return {type:'tupletEnd'};
 if(token.startsWith('J')){const e=JSON.parse(token.slice(1));if(!object(e)||typeof e.type!=='string')throw Error('Ungültiges J-Ereignis.');return e;}
 const at=token.indexOf('{'), base=at<0?token:token.slice(0,at), attrs=at<0?{}:map(JSON.parse(token.slice(at)),EV,true);
 let e,m=base.match(/^\((\d+:\d+)(?::([whqestxzb]))?$/);
 if(m){e={type:'tupletStart',ratio:m[1]};if(m[2])e.duration=REV[m[2]];}
 else {
  m=base.match(/^(R|[A-G](?:bb|##|b|#)?-?\d+|\[[A-G](?:bb|##|b|#)?-?\d+(?:,[A-G](?:bb|##|b|#)?-?\d+)*\]):([whqestxzb])(\.{0,4})$/);
  if(!m)throw Error('Unbekanntes Ereignis: '+base);
  e={type:m[1]==='R'?'rest':m[1][0]==='['?'chord':'note'};
  if(e.type==='note')e.pitch=m[1];else if(e.type==='chord')e.pitches=m[1].slice(1,-1).split(',');
  e.duration=REV[m[2]];if(m[3])e.dots=m[3].length;
 }
 for(const [k,v]of Object.entries(attrs)){if(own(e,k))throw Error('Kernfeld doppelt: '+k);assign(e,k,v);}return e;
}
function encode(score){
 if(!object(score)||!Array.isArray(score.parts)||!object(score.score))throw Error('Maxi/Mini mit score und parts wird erwartet.');
 const lines=['CS1','S '+json(meta(score.score,SC))];
 const rootExtra=omit(score,['format','version','score','parts','globalMarkings']);
 // Envelope retains the original source format and unknown root fields.
 if(score.format!=='AI-Notation-Maxi'||score.version!=='0.1'||Object.keys(rootExtra).length)lines.push('X '+json({format:score.format,version:score.version,...rootExtra}));
 for(const p of score.parts){
  if(!Array.isArray(p.measures))throw Error('Part ohne measures.');
  lines.push('P '+json(map(omit(p,['measures','markings']),PT)));
  for(const m of p.measures){
   if(!Number.isInteger(m.number)||m.number<1||!Array.isArray(m.voices))throw Error('Ungültiger Takt.');
   const extra=omit(m,['number','voices']);
   if(Object.keys(extra).length||!m.voices.length)lines.push('B '+m.number+' '+json(extra));
   for(const v of m.voices){
    if(!Number.isInteger(v.voice)||v.voice<1||!Array.isArray(v.events))throw Error('Ungültige Stimme.');
    lines.push(m.number+'/'+v.voice+(v.events.length?' '+v.events.map(event).join(' '):''));
    const vx=omit(v,['voice','events']);if(Object.keys(vx).length)lines.push('V '+m.number+'/'+v.voice+' '+json(vx));
   }
  }
  if(own(p,'markings')){if(!Array.isArray(p.markings))throw Error('markings muss eine Liste sein.');if(!p.markings.length)lines.push('E []');for(const m of p.markings)lines.push('E '+json(marking(m)));}
 }
 if(own(score,'globalMarkings')){if(!Array.isArray(score.globalMarkings))throw Error('globalMarkings muss eine Liste sein.');if(!score.globalMarkings.length)lines.push('G []');for(const m of score.globalMarkings)lines.push('G '+json(marking(m)));}
 return lines.join('\n')+'\n';
}
function decode(text){
 const lines=text.replace(/^\uFEFF/,'').split(/\r?\n/);let header=false,s=false,p=null;
 const out={format:'AI-Notation-Maxi',version:'0.1',score:{},parts:[]};
 function measure(n){let m=p.measures.find(x=>x.number===n);if(!m){m={number:n,voices:[]};p.measures.push(m);}return m;}
 for(let i=0;i<lines.length;i++){
  let l=lines[i].trim();if(!l||l.startsWith('//'))continue;
  // A line break between a record marker and its JSON is unambiguous.
  if(/^[SPEGX]$/.test(l)&&i+1<lines.length&&/^\s*[\[{]/.test(lines[i+1]))l+=' '+lines[++i].trim();
  try{
   if(!header){if(l!=='CS1')throw Error('CS1-Kopf fehlt.');header=true;continue;}
   let m;
   if(l.startsWith('S ')){if(s||p)throw Error('S muss einmal vor P stehen.');out.score=meta(JSON.parse(l.slice(2)),SC,true);s=true;}
   else if(l.startsWith('X ')){if(p)throw Error('X muss vor P stehen.');const x=JSON.parse(l.slice(2));if(!object(x))throw Error('X muss Objekt sein.');for(const[k,v]of Object.entries(x)){if(['score','parts','globalMarkings'].includes(k))throw Error('Reserviertes X-Feld '+k);assign(out,k,v);}}
   else if(l.startsWith('P ')){if(!s)throw Error('S fehlt.');const x=map(JSON.parse(l.slice(2)),PT,true);if(typeof x.id!=='string'||!x.id||typeof x.instrument!=='string')throw Error('P benötigt i und n.');if(out.parts.some(q=>q.id===x.id))throw Error('Doppelte Part-ID.');if(own(x,'measures')||own(x,'markings'))throw Error('Reserviertes P-Feld.');p={...x,measures:[]};out.parts.push(p);}
   else if((m=l.match(/^(\d+)\/(\d+)(?:\s+(.*))?$/))){if(!p)throw Error('P fehlt.');const n=+m[1],vn=+m[2];if(n<1||vn<1)throw Error('Takt und Stimme beginnen bei 1.');const bar=measure(n);if(bar.voices.some(v=>v.voice===vn))throw Error('Takt/Stimme doppelt.');bar.voices.push({voice:vn,events:splitTokens(m[3]||'').map(decodeEvent)});}
   else if((m=l.match(/^B (\d+) (.*)$/))){if(!p||+m[1]<1)throw Error('Ungültiges B.');const x=JSON.parse(m[2]);if(!object(x)||own(x,'number')||own(x,'voices'))throw Error('Ungültige Taktattribute.');const bar=measure(+m[1]);for(const [k,v]of Object.entries(x))assign(bar,k,v);}
   else if((m=l.match(/^V (\d+)\/(\d+) (.*)$/))){if(!p)throw Error('P fehlt.');const v=measure(+m[1]).voices.find(v=>v.voice===+m[2]);if(!v)throw Error('Stimme fehlt vor V.');const x=JSON.parse(m[3]);if(!object(x)||own(x,'voice')||own(x,'events'))throw Error('Ungültige Stimmattribute.');for(const [k,value]of Object.entries(x))assign(v,k,value);}
   else if(l.startsWith('E ')||l.startsWith('G ')){const global=l[0]==='G';if(!global&&!p)throw Error('P fehlt.');const holder=global?out:p,key=global?'globalMarkings':'markings';const value=JSON.parse(l.slice(2));if(!own(holder,key))holder[key]=[];if(Array.isArray(value)){if(value.length)throw Error('Nur [] ist als leere Markierung erlaubt.');}else holder[key].push(marking(value,true));}
   else throw Error('Unbekannte Zeile.');
  }catch(e){throw Error('Zeile '+(i+1)+': '+e.message);}
 }
 if(!header||!s||!out.parts.length)throw Error('CS1, S und mindestens ein P werden benötigt.');
 return out;
}
// Diagnostic only: never repairs, pads, truncates or blocks a composition.
function inspect(score){
 const issues=[],ids=new Set(), refs=[];const beats={breve:8,whole:4,half:2,quarter:1,eighth:.5,'16th':.25,'32nd':.125,'64th':.0625,'128th':.03125};
 let meter=score.score.timeSignature;
 for(const p of score.parts){let currentMeter=meter;for(const m of p.measures){currentMeter=m.timeSignature||currentMeter;const mm=/^(\d+)\/(\d+)$/.exec(currentMeter||'');const length=mm?+mm[1]*4/+mm[2]:null;
  for(const v of m.voices){let sum=0,stack=[];for(const e of v.events){
   if(e.id){if(ids.has(e.id))issues.push('Doppelte Ereignis-ID: '+e.id);ids.add(e.id);}
   if(e.type==='tupletStart'){const r=/^(\d+):(\d+)$/.exec(e.ratio||'');if(!r||+r[1]===0||+r[2]===0)issues.push('Ungültiges Tuplet: '+p.id+'/'+m.number+'/'+v.voice);else stack.push(+r[2]/+r[1]);}
   else if(e.type==='tupletEnd'){if(!stack.length)issues.push('Tuplet-Ende ohne Anfang: '+p.id+'/'+m.number+'/'+v.voice);else stack.pop();}
   else if(['note','rest','chord'].includes(e.type)){const d=beats[e.duration];if(d===undefined){issues.push('Unbekannte Dauer: '+e.duration);continue;}if(!e.grace)sum+=d*(2-Math.pow(.5,e.dots||0))*stack.reduce((a,b)=>a*b,1);}
  }if(stack.length)issues.push('Offenes Tuplet: '+p.id+'/'+m.number+'/'+v.voice);
  if(length!==null&&Math.abs(sum-length)>1e-7)issues.push(p.id+' Takt '+m.number+' Stimme '+v.voice+': '+sum+' statt '+length+' Viertel (Auftakt/verkürzten Takt prüfen).');
 }} for(const mark of p.markings||[])for(const k of ['startRef','endRef'])if(mark[k])refs.push(mark[k]);}
 for(const mark of score.globalMarkings||[])for(const k of ['startRef','endRef'])if(mark[k])refs.push(mark[k]);
 for(const r of refs)if(!ids.has(r))issues.push('Unbekannte Bogenreferenz: '+r);
 return issues;
}
const api={VERSION,encode,decode,inspect};if(typeof module!=='undefined'&&module.exports)module.exports=api;root.CompactScore=api;
})(typeof globalThis!=='undefined'?globalThis:this);
