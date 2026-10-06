/* CompactScore -> native MusicXML. No network, no changes to the source score. */
(function(root){
'use strict';
var DUR={breve:8,whole:4,half:2,quarter:1,eighth:.5,'16th':.25,'32nd':.125,'64th':.0625,'128th':.03125};
var PROGRAM={piano:1,violin:41,viola:42,cello:43,contrabass:44,flute:74,oboe:69,clarinet:72,bassoon:71,horn:61,trumpet:57,trombone:58,tuba:59,guitar:25,harp:47,organ:20,vibraphone:12};
var NAMES={piano:'Klavier',violin:'Violine',viola:'Viola',cello:'Cello',contrabass:'Kontrabass',flute:'Flöte',oboe:'Oboe',clarinet:'Klarinette',bassoon:'Fagott',horn:'Horn',trumpet:'Trompete',trombone:'Posaune',tuba:'Tuba',guitar:'Gitarre',harp:'Harfe',organ:'Orgel',vibraphone:'Vibraphon'};
var KEYS={C:0,G:1,D:2,A:3,E:4,B:5,'F#':6,'C#':7,F:-1,Bb:-2,Eb:-3,Ab:-4,Db:-5,Gb:-6,Cb:-7,Am:0,Em:1,Bm:2,'F#m':3,'C#m':4,'G#m':5,'D#m':6,'A#m':7,Dm:-1,Gm:-2,Cm:-3,Fm:-4,Bbm:-5,Ebm:-6,Abm:-7};
function esc(s){return String(s===undefined?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&apos;');}
function gcd(a,b){while(b){var c=a%b;a=b;b=c;}return a;}
function lcm(a,b){return a/gcd(a,b)*b;}
function pitch(p){var m=/^([A-G])(bb|##|b|#)?(-?\d+)$/.exec(p||'');if(!m)throw Error('Ungültige Tonhöhe: '+p);var alter={'':0,b:-1,bb:-2,'#':1,'##':2}[m[2]||''];return {step:m[1],alter:alter,octave:Number(m[3]),midi:(Number(m[3])+1)*12+{C:0,D:2,E:4,F:5,G:7,A:9,B:11}[m[1]]+alter};}
function key(text){var m=/^([A-Ga-g])([#b]?)(.*)$/.exec(String(text||'C').replace(/♭/g,'b').replace(/♯/g,'#').trim());if(!m)throw Error('Unbekannte Tonart: '+text);var minor=/minor|moll|^m$/i.test(m[3].trim()),name=m[1].toUpperCase()+m[2]+(minor?'m':'');if(KEYS[name]===undefined)throw Error('Unbekannte Tonart: '+text);return {fifths:KEYS[name],minor:minor};}
function meter(s){var m=/^(\d+)\/(\d+)$/.exec(s||'4/4');if(!m||!Number(m[1])||!Number(m[2]))throw Error('Ungültige Taktart: '+s);return {num:Number(m[1]),den:Number(m[2]),quarters:Number(m[1])*4/Number(m[2])};}
function flatten(events){
 var result=[],stack=[],pending=[];
 events.forEach(function(e){
  if(e.type==='tupletStart'){var r=/^(\d+):(\d+)$/.exec(e.ratio||'');if(!r||!Number(r[1])||!Number(r[2]))throw Error('Ungültiges Tuplet.');var t={actual:Number(r[1]),normal:Number(r[2]),level:stack.length+1,start:result.length,duration:e.duration||'eighth'};if(t.level>6)throw Error('Mehr als sechs verschachtelte Tuplets.');stack.push(t);pending.push(t);return;}
  if(e.type==='tupletEnd'){var t=stack.pop();if(!t||result.length===t.start)throw Error('Tuplet ohne Noten.');result[result.length-1].stops.push(t);return;}
  if(!['note','chord','rest'].includes(e.type))throw Error('Ereignis kann noch nicht nach MusicXML umgesetzt werden: '+e.type);
  if(DUR[e.duration]===undefined)throw Error('Unbekannte Notendauer: '+e.duration);
  var q=DUR[e.duration]*(2-Math.pow(.5,e.dots||0)),den=128*Math.pow(2,e.dots||0),factor=1,actual=1,normal=1;
  stack.forEach(function(t){factor*=t.normal/t.actual;actual*=t.actual;normal*=t.normal;den*=t.actual;});
  var row={event:e,q:e.grace?0:q*factor,denominator:den,actual:actual,normal:normal,starts:pending,stops:[],tuplets:stack.slice(0)};pending=[];result.push(row);
 });
 if(stack.length)throw Error('Nicht geschlossenes Tuplet.');return result;
}
function layout(part){
 var instrument=String(part.instrument||'piano').toLowerCase().replace(/[\s_-]/g,''),ids=[];
 part.measures.forEach(function(m){m.voices.forEach(function(v){if(!ids.includes(v.voice))ids.push(v.voice);});});ids.sort(function(a,b){return a-b;});
 var voices=ids.map(function(id){var pitches=[];part.measures.forEach(function(m){m.voices.filter(function(v){return v.voice===id;}).forEach(function(v){v.events.forEach(function(e){(e.pitch?[e.pitch]:e.pitches||[]).forEach(function(p){pitches.push(pitch(p).midi);});});});});pitches.sort(function(a,b){return a-b;});var median=pitches.length?pitches[Math.floor(pitches.length/2)]:60;return {id:id,staff:instrument==='piano'&&ids.length>1&&median<60?2:1};});
 // A piano voice remains on the same staff for the entire piece.
 var staves=instrument==='piano'?2:1;
 [1,2].forEach(function(staff){if(voices.filter(function(v){return v.staff===staff;}).length>4)throw Error('Mehr als vier Stimmen in einem System.');});
 var clef=instrument==='viola'?['C',3]:['cello','contrabass','bassoon','trombone','tuba'].includes(instrument)?['F',4]:['G',2];
 return {instrument:instrument,voices:voices,staves:staves,clef:clef};
}
function convert(score){
 if(!score||!score.score||!Array.isArray(score.parts)||!score.parts.length)throw Error('Keine Partitur.');
 var warnings=[],division=128,maximum=0,plans=score.parts.map(function(p){var plan=layout(p);plan.part=p;plan.rows={};p.measures.forEach(function(m){maximum=Math.max(maximum,m.number);m.voices.forEach(function(v){var rows=flatten(v.events);plan.rows[m.number+'/'+v.voice]=rows;rows.forEach(function(r){division=lcm(division,r.denominator);});});});return plan;});
 if(division>10000000)throw Error('Rhythmische Auflösung ist zu groß.');
 var baseKey=key(score.score.key),baseMeter=meter(score.score.timeSignature),tempo=Number(score.score.tempo&&score.score.tempo.bpm||72);
 function ticks(q){var t=q*division;if(Math.abs(t-Math.round(t))>.00001)throw Error('Rhythmus ist nicht exakt darstellbar.');return Math.round(t);}
 function textDirection(text,staff,offset){return '<direction><direction-type><words>'+esc(text)+'</words></direction-type><offset>'+ticks(offset||0)+'</offset><staff>'+staff+'</staff></direction>';}
 function direction(body,staff,q,sound){return '<direction><direction-type>'+body+'</direction-type><offset>'+ticks(q||0)+'</offset><staff>'+staff+'</staff>'+(sound||'')+'</direction>';}
 var xml='<?xml version="1.0" encoding="UTF-8"?>\n<score-partwise version="4.0"><work><work-title>'+esc(score.score.title||'Komposition')+'</work-title></work><movement-title>'+esc(score.score.title||'Komposition')+'</movement-title>';
 if(score.score.composer)xml+='<identification><creator type="composer">'+esc(score.score.composer)+'</creator></identification>';
 xml+='<part-list>';
 plans.forEach(function(plan,i){var id='P'+(i+1),name=NAMES[plan.instrument]||plan.part.instrument;if(!PROGRAM[plan.instrument])warnings.push('Instrument „'+name+'“: MusicXML verwendet Klavier als Klangvorbelegung.');xml+='<score-part id="'+id+'"><part-name>'+esc(name)+'</part-name><score-instrument id="'+id+'-I"><instrument-name>'+esc(name)+'</instrument-name></score-instrument><midi-instrument id="'+id+'-I"><midi-channel>'+(i%15<9?i%15+1:i%15+2)+'</midi-channel><midi-program>'+(PROGRAM[plan.instrument]||1)+'</midi-program></midi-instrument></score-part>';});xml+='</part-list>';
 plans.forEach(function(plan,pi){
  var part=plan.part,spans={},directions={},notationPositions={},eventPositions={},currentMeter=baseMeter;
  function at(position){if(!position)return null;var m=Number(position.measure),q=Number(position.beat)-1;if(m<1||!isFinite(q)||q<0)return null;return {measure:m,q:q};}
  function mark(position,body,staff,sound){var pos=at(position);if(!pos){warnings.push('Markierung ohne gültige Position.');return;}if(!directions[pos.measure])directions[pos.measure]=[];directions[pos.measure].push({q:pos.q,xml:direction(body,staff||1,pos.q,sound)});}
  function spanRef(ref,token){if(!spans[ref])spans[ref]=[];spans[ref].push(token);}
  function noteMark(position,token,end){var pos=at(position);if(!pos)return;if(!notationPositions[pos.measure])notationPositions[pos.measure]=[];notationPositions[pos.measure].push({q:pos.q,token:token,end:!!end});}
  // Resolve IDs and staff positions before creating directions and spanners.
  part.measures.forEach(function(m){plan.voices.forEach(function(v){var q=0;(plan.rows[m.number+'/'+v.id]||[]).forEach(function(row){if(row.event.id)eventPositions[row.event.id]={measure:m.number,q:q,staff:v.staff};q+=row.q;});});});
  var slurNumber=0;
  (part.markings||[]).concat(score.globalMarkings||[]).forEach(function(m){
   if(m.type==='dynamic'&&m.position){var d=String(m.value||'');mark(m.position,'<dynamics>'+(/^(p{1,6}|f{1,6}|mp|mf|sf|sfp|sfz|sffz|fp|rf|rfz|fz|n)$/.test(d)?'<'+d+'/>':'<other-dynamics>'+esc(d)+'</other-dynamics>')+'</dynamics>');}
   else if(['expression','staffText','technique','text'].includes(m.type)&&m.position)mark(m.position,'<words>'+esc(m.text||m.value||'')+'</words>');
   else if(m.type==='tempo'&&m.position){var t=m.tempo||{},body=t.text?'<words>'+esc(t.text)+'</words>':'';if(t.bpm)body+='<metronome><beat-unit>quarter</beat-unit><per-minute>'+Number(t.bpm)+'</per-minute></metronome>';if(body)mark(m.position,body.replace(/<\/words><metronome>/g,'</words></direction-type><direction-type><metronome>'),1,t.bpm?'<sound tempo="'+Number(t.bpm)+'"/>':'');}
   else if(m.type==='hairpin'&&m.start&&m.end){var number=1,kind=/diminuendo|decrescendo/.test(m.kind||'')?'diminuendo':'crescendo';mark(m.start,'<wedge type="'+kind+'" number="'+number+'"/>');mark(m.end,'<wedge type="stop" number="'+number+'"/>');}
   else if(m.type==='pedal'&&m.start&&m.end){var pedalStaff=plan.staves;mark(m.start,'<pedal type="start" line="yes" number="1"/>',pedalStaff,'<sound damper-pedal="yes"/>');mark(m.end,'<pedal type="stop" line="yes" number="1"/>',pedalStaff,'<sound damper-pedal="no"/>');}
   else if(m.type==='slur'&&m.startRef&&m.endRef){var a=eventPositions[m.startRef],b=eventPositions[m.endRef];if(!a||!b){warnings.push('Bogen mit unbekannter Notenreferenz.');return;}var number=(slurNumber++%6)+1,line=/^(solid|dashed|dotted)$/.test(m.style||'')?m.style:'solid';spanRef(m.startRef,'<slur type="start" number="'+number+'" line-type="'+line+'"/>');spanRef(m.endRef,'<slur type="stop" number="'+number+'"/>');}
   else if(m.type==='breath'&&m.position)noteMark(m.position,'<articulations><breath-mark/></articulations>',true);
   else if(m.type==='trillLine'&&m.start&&m.end){noteMark(m.start,'<ornaments><trill-mark/><wavy-line type="start" number="1"/></ornaments>');noteMark(m.end,'<ornaments><wavy-line type="stop" number="1"/></ornaments>',true);}
   else if(m.type==='ottava'&&m.start&&m.end){var kind=String(m.kind||m.value||'8va'),down=/bassa|vb|below/.test(kind),size=/15/.test(kind)?15:8;mark(m.start,'<octave-shift type="'+(down?'up':'down')+'" size="'+size+'" number="1"/>');mark(m.end,'<octave-shift type="stop" size="'+size+'" number="1"/>');}
   else if(m.type==='clef'&&m.position){if(!directions[m.position.measure])directions[m.position.measure]=[];var c=/bass/.test(m.value)?['F',4]:/alto/.test(m.value)?['C',3]:/tenor/.test(m.value)?['C',4]:['G',2];directions[m.position.measure].push({q:Number(m.position.beat)-1,clef:c});}
   else {warnings.push('Markierung „'+m.type+'“ bleibt im CS1-Original erhalten; MusicXML unterstützt sie in dieser Version noch nicht.');}
  });
  xml+='<part id="P'+(pi+1)+'">';
  for(var mn=1;mn<=maximum;mn++){
   var measure=part.measures.filter(function(m){return m.number===mn;})[0],changed=measure&&measure.timeSignature&&measure.timeSignature!==currentMeter.num+'/'+currentMeter.den;if(changed)currentMeter=meter(measure.timeSignature);
   var length=currentMeter.quarters;plan.voices.forEach(function(v){var sum=(plan.rows[mn+'/'+v.id]||[]).reduce(function(a,r){return a+r.q;},0);if(sum>length+.00001){warnings.push('Takt '+mn+' Stimme '+v.id+' ist länger als die Taktart.');length=Math.max(length,sum);}});
   xml+='<measure number="'+mn+'">';
   if(mn===1||changed){xml+='<attributes>';if(mn===1)xml+='<divisions>'+division+'</divisions><key><fifths>'+baseKey.fifths+'</fifths><mode>'+(baseKey.minor?'minor':'major')+'</mode></key>';xml+='<time><beats>'+currentMeter.num+'</beats><beat-type>'+currentMeter.den+'</beat-type></time>';if(mn===1){xml+='<staves>'+plan.staves+'</staves>';for(var staff=1;staff<=plan.staves;staff++){var clef=staff===2?['F',4]:plan.clef;xml+='<clef number="'+staff+'"><sign>'+clef[0]+'</sign><line>'+clef[1]+'</line></clef>';}}xml+='</attributes>';}
   if(mn===1){if(score.score.tempo&&score.score.tempo.text)xml+=textDirection(score.score.tempo.text,1,0);xml+=direction('<metronome><beat-unit>quarter</beat-unit><per-minute>'+tempo+'</per-minute></metronome>',1,0,'<sound tempo="'+tempo+'"/>');}
   (directions[mn]||[]).sort(function(a,b){return a.q-b.q;}).forEach(function(d){if(!d.clef)xml+=d.xml;});
   plan.voices.forEach(function(v,vi){
    if(vi)xml+='<backup><duration>'+ticks(length)+'</duration></backup>';
    var onset=0,rows=plan.rows[mn+'/'+v.id]||[],clefs=(directions[mn]||[]).filter(function(d){return !!d.clef;});
    rows.forEach(function(row){var e=row.event;
     while(clefs.length&&clefs[0].q<=onset+.00001){var c=clefs.shift();if(vi===0)xml+='<attributes><clef number="'+v.staff+'"><sign>'+c.clef[0]+'</sign><line>'+c.clef[1]+'</line></clef></attributes>';}
     if(e.dynamic)xml+=direction('<dynamics><'+(/^(p{1,6}|f{1,6}|mp|mf|sfz|fp)$/.test(e.dynamic)?e.dynamic:'other-dynamics')+'/></dynamics>',v.staff,0);
     if(e.expressionText)xml+=textDirection(e.expressionText,v.staff,0);
     var pitches=e.type==='chord'?e.pitches:e.type==='note'?[e.pitch]:[null];
     pitches.forEach(function(p,ni){var properties='',notations='',ties=[];
      if(e.tie==='stop'||e.tie==='continue')ties.push('stop');if(e.tie==='start'||e.tie==='continue')ties.push('start');
      if(e.grace)properties+='<grace/>';if(ni)properties+='<chord/>';
      if(p){var note=pitch(p);properties+='<pitch><step>'+note.step+'</step>'+(note.alter?'<alter>'+note.alter+'</alter>':'')+'<octave>'+note.octave+'</octave></pitch>';}else properties+='<rest/>';
      if(!e.grace)properties+='<duration>'+ticks(row.q)+'</duration>';
      ties.forEach(function(t){properties+='<tie type="'+t+'"/>';notations+='<tied type="'+t+'"/>';});
      properties+='<voice>'+v.id+'</voice><type>'+e.duration+'</type>';for(var dot=0;dot<(e.dots||0);dot++)properties+='<dot/>';
      if(row.actual!==1)properties+='<time-modification><actual-notes>'+row.actual+'</actual-notes><normal-notes>'+row.normal+'</normal-notes></time-modification>';
      properties+='<staff>'+v.staff+'</staff>';
      if(ni===0){
       notations+=(spans[e.id]||[]).join('');
       if(e.slur==='start'||e.slur==='continue')notations+='<slur type="start" number="6"/>';if(e.slur==='stop'||e.slur==='continue')notations+='<slur type="stop" number="6"/>';
       var arts=e.articulations||e.articulation||[];if(typeof arts==='string')arts=[arts];var a=arts.map(function(x){return ['staccato','staccatissimo','tenuto','accent','marcato','detached-legato','soft-accent'].includes(x)?'<'+(x==='marcato'?'strong-accent':x)+'/>':'<other-articulation>'+esc(x)+'</other-articulation>';}).join('');if(a)notations+='<articulations>'+a+'</articulations>';
       if(e.ornament){var o={trill:'trill-mark',turn:'turn',mordent:'mordent',prall:'inverted-mordent',prallprall:'inverted-mordent'}[e.ornament];notations+='<ornaments>'+(o?'<'+o+'/>':'<other-ornament>'+esc(e.ornament)+'</other-ornament>')+'</ornaments>';}
       if(e.fermata)notations+='<fermata>'+(e.fermata==='short'?'angled':e.fermata==='long'?'square':'normal')+'</fermata>';
       if(e.arpeggio)notations+='<arpeggiate'+(/down/.test(e.arpeggio)?' direction="down"':/up/.test(e.arpeggio)?' direction="up"':'')+'/>';
       row.starts.forEach(function(t){notations+='<tuplet type="start" number="'+t.level+'" bracket="yes"/>';});row.stops.forEach(function(t){notations+='<tuplet type="stop" number="'+t.level+'"/>';});
       (notationPositions[mn]||[]).forEach(function(m){if(!m.used&&vi===0&&m.q>=onset-.00001&&(m.end?m.q<=onset+row.q+.00001:m.q<onset+row.q-.00001)){notations+=m.token;m.used=true;}});
      }
      xml+='<note>'+properties+(notations?'<notations>'+notations+'</notations>':'')+'</note>';
     });onset+=row.q;
    });
    if(onset<length-.00001){var missing=ticks(length-onset);if(!rows.length)xml+='<note><rest measure="yes"/><duration>'+missing+'</duration><voice>'+v.id+'</voice><staff>'+v.staff+'</staff></note>';else{xml+='<forward><duration>'+missing+'</duration><voice>'+v.id+'</voice><staff>'+v.staff+'</staff></forward>';warnings.push('Takt '+mn+' Stimme '+v.id+' ist kürzer als die Taktart; Vorschau ergänzt die fehlende Zeit.');}}
   });
   if(mn===maximum)xml+='<barline location="right"><bar-style>light-heavy</bar-style></barline>';xml+='</measure>';
  }Object.keys(notationPositions).forEach(function(n){notationPositions[n].forEach(function(m){if(!m.used)warnings.push('Notenmarkierung in Takt '+n+' bei Viertelposition '+(m.q+1)+' konnte keinem Ereignis zugeordnet werden.');});});xml+='</part>';
 });xml+='</score-partwise>';
 return {xml:xml,warnings:warnings.filter(function(x,i,a){return a.indexOf(x)===i;}),measures:maximum,parts:plans.length};
}
var api={convert:convert};if(typeof module!=='undefined'&&module.exports)module.exports=api;root.CompactMusicXML=api;
})(typeof globalThis!=='undefined'?globalThis:this);
