#!/usr/bin/env node
'use strict';
// Mathematics Practice P1 — a strict non-writing candidate/version fingerprint
// gate. Historical question IDs/answer rows are never modified or exposed.
// This intentionally DOES NOT stage/publish future versions.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const crypto=require('node:crypto'),{spawnSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const guard=read('scripts/math-practice-v2-editorial-future-only-contract.cjs');
const sql=read('supabase/preflight/math_practice_v2_81_future_only_hash_pin_readonly.sql');
const run=spawnSync(process.execPath,[path.join(root,'scripts/math-practice-v2-editorial-future-only-contract.cjs')],{
  cwd:root,encoding:'utf8',maxBuffer:2*1024*1024});
assert.equal(run.status,0,'source correction gate not clean: '+(run.stderr||'').slice(0,800));
const manifest=JSON.parse(run.stdout);
assert.equal(manifest.questions,495);
assert.equal(manifest.edited,112);
assert.equal(manifest.future_version_required,81);
assert.equal(manifest.editorial_equal_key,31);
assert.equal(manifest.history_sensitive_candidates,16);
const m=guard.match(/const FUTURE_VERSION_REQUIRED = new Set\(\[([\s\S]*?)\]\)/);
assert.ok(m,'missing immutable future-only source ID list');
const future=m[1].split(',').map(v=>Number(v.trim())).sort((a,b)=>a-b);
assert.equal(future.length,81);
assert.equal(new Set(future).size,81);
const rows=[...sql.matchAll(/\((\d+)::bigint,'([0-9a-f]{64})'::text\)/g)].map(x=>({id:Number(x[1]),published_hash:x[2]}));
assert.equal(rows.length,81,'missing live old-version fingerprints');
assert.deepEqual(rows.map(x=>x.id),future,'live version pins diverge from source future-only ID contract');
const all=new Map(manifest.edited_manifest.map(v=>[v.id,v]));
assert.equal(all.size,112);
for(const r of rows){
 const item=all.get(r.id);
 assert.ok(item&&item.category==='future_version_required','pinned live item not future-versioned');
 assert.match(item.old_sha256,/^[0-9a-f]{64}$/);
 assert.match(item.new_sha256,/^[0-9a-f]{64}$/);
 assert.notEqual(item.old_sha256,item.new_sha256,'expected semantic/source change missing');
 // Published database row hash is deliberately NOT equated with the authored
 // JSON-item hash: their canonical digests have distinct payload schemas.
 assert.match(r.published_hash,/^[0-9a-f]{64}$/);
}
const stripped=sql.replace(/--[^\n]*/g,'');
assert.match(stripped,/^\s*with\s+expected\s*\(/i);
assert.doesNotMatch(stripped,/\b(insert|update|delete|truncate|alter|drop|create|grant|revoke|call|execute|copy|do)\b/i,
  'preflight must remain strictly SELECT-only');
for(const token of ['m.content_hash=e.old_content_hash','current_active_pool_links=1','tour_links=0',
  "s.status='in_progress' and e.question_id=any(s.question_ids)",
  'source_version_pin_ready'])
 assert.ok(sql.includes(token),'version-history safety check missing');
const generation=read('docs/practice-bank-generations-release-gate.md');
assert.ok(generation.includes('Routine question fixes do not change generation'),
 'existing Practice generation policy changed');
const combined=rows.map(r=>({
 id:r.id,published_hash:r.published_hash,baseline_authored_hash:all.get(r.id).old_sha256,
 candidate_authored_hash:all.get(r.id).new_sha256}));
const digest=crypto.createHash('sha256').update(JSON.stringify(combined)).digest('hex');
console.log(JSON.stringify({p1_total:495,protected_future_only:81,editorial:31,
  historically_answered_across_all_candidates:16,
  old_and_new_source_and_live_pin_manifest_sha256:digest,
  selector:'do not change bank generation for routine question fixes',
  sql_read_only:true,old_ids_immutable:true,
  status:'source_guard_ready_production_release_NOT_AUTHORIZED'},null,2));
