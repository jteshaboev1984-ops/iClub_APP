#!/usr/bin/env node
'use strict';
// Math Practice #574: fixture-only union of 81+31+3+2 source-authored stage
// payloads. All output is PRIVATE temp SQL (contains protected question text).
// Never stdout/CI-log the content, never commit, never use hosted credentials.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const args=process.argv.slice(2);
const specs=[['81',81],['31',31],['3',3],['2',2]];
function get(flag){
 const i=args.indexOf('--'+flag);
 assert.ok(i>=0&&args[i+1],flag+' input is required');
 return path.resolve(args[i+1]);
}
const groups=[],payload=[],allIds=new Set(),allKeys=new Set();
for(const [key,n] of specs){
 const sql=fs.readFileSync(get('stage'+key),'utf8');
 const match=sql.match(/v_items jsonb := '((?:''|[^'])*)'::jsonb;/);
 assert.ok(match,'unrecognized ephemeral source staging SQL format');
 const items=JSON.parse(match[1].replace(/''/g,"'"));
 assert.equal(items.length,n,'incorrect authored stage size');
 for(const q of items){
  assert.ok(Number.isSafeInteger(q.old_id)&&q.old_id>=7485&&q.old_id<=7979);
  assert.ok(!allIds.has(q.old_id),'double-versioned original');
  assert.ok(!allKeys.has(q.new_key),'double-versioned key');
  assert.ok(/^[a-f0-9]{64}$/.test(q.old_hash)&&/^[a-f0-9]{64}$/.test(q.new_hash));
  assert.equal(q.release_version,'math_p1_practice_v2_fix_20261120');
  assert.equal(q.new_key,q.old_key+'-V20261120','version key mismatch');
  assert.ok(['en','ru','uz'].every(l=>q.text?.[l]&&q.explanation?.[l]));
  allIds.add(q.old_id);allKeys.add(q.new_key);
  groups.push({group:key,id:q.old_id});
  payload.push(q);
 }
}
assert.equal(payload.length,117);
assert.equal(allIds.size,117);
const q=s=>"'"+String(s).replace(/'/g,"''")+"'";
const fixture='-- PRIVATE EPHEMERAL SQL ONLY: never commit/print.\n'+
  'v_items jsonb := '+q(JSON.stringify(payload))+'::jsonb;\n';
const groupSql='-- DISPOSABLE PG17 only. Question texts/answer keys never stored here.\n'+
 'create table private.math_practice_117_group_fixture(\n'+
 " group_name text not null check(group_name in ('81','31','3','2')),\n"+
 ' old_id bigint primary key\n);\n'+
 'insert into private.math_practice_117_group_fixture(group_name,old_id)\n'+
 'values '+groups.map(x=>'('+q(x.group)+','+x.id+')').join(',\n')+';\n';
for(const [flag,text] of [['bundle-out',fixture],['groups-out',groupSql]]){
 const out=get(flag);
 fs.writeFileSync(out,text,{encoding:'utf8',flag:'wx',mode:0o600});
}
console.log(JSON.stringify({fixture_scope:117,group_sizes:{81:81,31:31,3:3,2:2},
 duplicate_old_ids:0,duplicate_version_keys:0,
 generated_private_fixture_files:2,question_text_printed:false,hosted_writes:0}));
