#!/usr/bin/env node
// Issue #450 P0-14: two actual PostgreSQL 17 connections, no production SQL.
// Test only fabricated P0-13 epoch table after signed-JWT simulated transition.
'use strict';
const assert=require('node:assert/strict');
const {spawn,spawnSync}=require('node:child_process');
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-14 isolated environment required');
assert(process.env.PGDATABASE==='postgres','P0-14 only disposable postgres DB');
assert(['127.0.0.1','localhost'].includes(process.env.PGHOST),
  'P0-14 only localhost PostgreSQL');
const pgArgs=['-X','-A','-t','-q','-v','ON_ERROR_STOP=1'];
const query=sql=>{
  const p=spawnSync('psql',[...pgArgs,'-c',sql],{encoding:'utf8',timeout:12000});
  if(p.error)throw p.error;
  return {ok:p.status===0,status:p.status,stdout:p.stdout||'',stderr:p.stderr||''};
};
const guard=query([
  'DO $$ BEGIN',
  "IF current_database()<>'postgres'",
  "OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'",
  'OR (SELECT count(*) FROM public.users)<>2',
  'OR (SELECT count(*) FROM auth.users)<>2',
  "OR to_regclass('private.p0_13_epoch_gate') IS NULL",
  "OR (SELECT epoch FROM private.p0_13_epoch_gate WHERE program='math_as_p1_p5')<>2",
  "THEN RAISE EXCEPTION 'P0-14 refused invalid disposable fixture'; END IF;",
  'END $$;'
].join(' '));
assert(guard.ok,'P0-14 refused fixture: '+guard.stderr);
let holder=null,finished=false;
async function holdOpenTransaction(){
 holder=spawn('psql',pgArgs,{stdio:['pipe','pipe','pipe']});
 let stderr='';
 holder.stderr.setEncoding('utf8');
 holder.stderr.on('data',s=>stderr+=s);
 const ready=new Promise((resolve,reject)=>{
   let output='';
   const timeout=setTimeout(()=>reject(new Error('P0-14 lock holder never signaled '+stderr)),12000);
   holder.stdout.setEncoding('utf8');
   holder.stdout.on('data',s=>{
     output+=s;
     if(output.includes('P0_14_SHARE_LOCK_HELD')){clearTimeout(timeout);resolve();}
   });
   holder.on('error',reject);
   holder.on('exit',code=>{
     if(!finished)reject(new Error('P0-14 holder exited early: '+code+' '+stderr));
   });
 });
 holder.stdin.write([
   'BEGIN;',
   "SELECT epoch FROM private.p0_13_epoch_gate WHERE program='math_as_p1_p5' FOR SHARE;",
   "SELECT 'P0_14_SHARE_LOCK_HELD';",
   ''
 ].join('\n'));
 await ready;
}
const finishHolder=()=>new Promise((resolve,reject)=>{
 if(!holder)return resolve();
 finished=true;
 holder.once('exit',code=>code===0?resolve():reject(new Error('P0-14 holder exit '+code)));
 holder.stdin.end('ROLLBACK;\n');
});
(async()=>{
 try{
   await holdOpenTransaction();
   // Active learner holds SHARE lock. Maintenance UPDATE must wait/fail closed.
   const blocked=query([
     "SET lock_timeout='800ms';",
     "UPDATE private.p0_13_epoch_gate SET paused=true WHERE program='math_as_p1_p5';"
   ].join('\n'));
   assert(!blocked.ok,'P0-14 maintenance UPDATE passed through active learner lock');
   assert(/lock timeout/i.test(blocked.stderr),
     'P0-14 expected actual PG lock timeout: '+blocked.stderr);
   const during=query("SELECT epoch::text||':'||paused::text FROM private.p0_13_epoch_gate WHERE program='math_as_p1_p5';");
   assert(during.ok&&during.stdout.trim()==='2:false',
     'P0-14 maintenance updated epoch while share lock held: '+during.stdout);
   await finishHolder();
   const after=query([
     "UPDATE private.p0_13_epoch_gate SET paused=true WHERE program='math_as_p1_p5';",
     "SELECT epoch::text||':'||paused::text FROM private.p0_13_epoch_gate WHERE program='math_as_p1_p5';"
   ].join('\n'));
   assert(after.ok&&after.stdout.trim().endsWith('2:true'),
     'P0-14 maintenance failed after learner completed: '+after.stderr);
   const restore=query([
     "UPDATE private.p0_13_epoch_gate SET paused=false WHERE program='math_as_p1_p5';",
     "SELECT CASE WHEN (SELECT epoch FROM private.p0_13_epoch_gate WHERE program='economics_as')=1",
     " AND (SELECT paused FROM private.p0_13_epoch_gate WHERE program='math_as_p1_p5')=false",
     " AND (SELECT count(*) FROM private.p0_13_fake_write_events)=2",
     " THEN 'P0_14_CLEAN' ELSE 'P0_14_BAD' END;"
   ].join('\n'));
   assert(restore.ok&&restore.stdout.includes('P0_14_CLEAN'),
     'P0-14 protected state changed: '+restore.stdout+' '+restore.stderr);
   console.log('PASS P0-14 two genuine PG17 sessions: active learner blocks epoch maintenance, after completion maintenance passes, protected state intact');
 }finally{
   if(holder&&!finished){
     finished=true;
     try{holder.stdin.end('ROLLBACK;\n');}catch{}
     holder.kill();
   }
 }
})().catch(e=>{console.error('P0-14 FAIL: '+e.message);process.exit(1)});
