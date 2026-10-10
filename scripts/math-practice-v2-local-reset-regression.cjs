#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),js=fs.readFileSync(path.join(root,'security/practice-v2-local-reset.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8'),app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const MARKER='iclub_math_practice_v2_local_reset_20261007_v1';
assert(html.includes('security/practice-v2-local-reset.js?v=stage03oldhistory2'),'Bad cleanup cache pin');
assert(app.includes('await window.iclubMathPracticeV2ResetAfterPublish?.(window.sb)'),'No authenticated cleanup boot');
assert(js.includes('const LEGACY_PREFIX = "practice_history_v2:mathematics:tour_"'),'Cleanup must target only retired history');
function storage(initial){const map=new Map(Object.entries(initial)),writes=[];
 return {map,writes,get length(){return map.size},key:n=>[...map.keys()][n]??null,
 getItem:k=>map.get(k)??null,setItem:(k,v)=>{map.set(k,String(v));writes.push(k)},
 removeItem:k=>{map.delete(k);writes.push(k)}}}
function mount(s){const ctx={localStorage:s,setTimeout,clearTimeout};vm.runInNewContext(js,ctx,{timeout:1200});
 assert.equal(typeof ctx.iclubMathPracticeV2ResetAfterPublish,'function');return ctx.iclubMathPracticeV2ResetAfterPublish}
(async()=>{
 const old='practice_history_v2:mathematics:tour_1',modern='practice_history_v3:mathematics:tour_1';
 const data={[old]:'OLD','practice_history_v2:mathematics:tour_2':'OLD2',[modern]:'NEW',
 'practice_history_v2:chemistry:tour_1':'CHEM','iclub_practice_draft_v1':'ACTIVE',
 'iclub_state_v1':'STATE','iclub_my_recs_v1':'RECS'};
 const store=storage(data),run=mount(store),unchanged=JSON.stringify([...store.map]);
 assert.equal(await run(null),false);
 assert.equal(await run({rpc:async()=>({data:false})}),false);
 assert.equal(await run({rpc:async()=>({data:true,error:'offline'})}),false);
 assert.equal(JSON.stringify([...store.map]),unchanged,'Denied cleanup modified data');
 let calls=0;const client={rpc:async name=>{assert.equal(name,'is_math_practice_v2_published_safe_v1');calls++;return {data:true,error:null}}};
 assert.equal(await run(client),true);assert.equal(store.map.has(old),false);
 assert.equal(store.map.has('practice_history_v2:mathematics:tour_2'),false);
 assert.equal(store.map.get(MARKER),'1');
 for(const key of [modern,'practice_history_v2:chemistry:tour_1','iclub_practice_draft_v1','iclub_state_v1','iclub_my_recs_v1'])
  assert.equal(store.map.get(key),data[key],key+' was changed');
 assert(store.writes.every(k=>k===MARKER||k.startsWith('practice_history_v2:mathematics:tour_')),'Unexpected storage mutation');
 assert.equal(await run(client),false);assert.equal(calls,1,'One-time marker not respected');
 const offline=storage(data);assert.equal(await mount(offline)({rpc:async()=>{throw Error('offline')}}),false);
 assert.equal(offline.writes.length,0);
 const missing=storage(data);assert.equal(await mount(missing)({}),false);
 assert.equal(missing.writes.length,0);
 console.log('PRACTICE_V2_NARROW_RESET_OK legacy_removed=1 new_progress_preserved=1 one_time=1 cases=6');
})().catch(err=>{console.error(err);process.exitCode=1});
