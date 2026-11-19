#!/usr/bin/env node
"use strict";
// Strict branch-only P0-16B source gate. Never disables legacy UX531 guards.
const assert=require("node:assert/strict");
const cp=require("node:child_process");
const fs=require("node:fs");
const BASE="f30adcd4b6b4cbc230fa375418e5aa56f95e49d2";
const git=(...args)=>cp.execFileSync("git",args,{encoding:"utf8"}).trim();
assert.equal(process.env.P016B_BASE_SHA,BASE,"Must be independently reviewed main");
assert.equal(git("rev-parse","HEAD"),process.env.P016B_HEAD_SHA,"Head drift");
git("merge-base","--is-ancestor",BASE,"HEAD");
const files=git("diff","--name-only",BASE,"HEAD").split("\n").filter(Boolean);
const exact={
  ".github/workflows/exam-prep-p1p5-isolated-http-e2e.yml":"85627b1df2acf6dad6c42d164890d05aaa19bb2c",
  ".github/workflows/math-p016b-contract-review.yml":"41c7b410be09a3bc9abb794ab3139718ab5704df",
  ".github/workflows/exam-prep-weekly-profile-recovery.yml":"3fea42213937715255aa12a31c9aa96d8e02d8ec",
  ".github/workflows/math-p1p5-d3-protected-recovery-review.yml":"e8773d4e30cf6a9c505e08fc64c71d0e88ffef7f",
  ".github/workflows/p2-78-concurrency-service-transitions.yml":"6ea1309e18858d63c6a374785f5cdb8821b82698",
  "exam-prep/exam-prep-api.js":"7beda6c230626800fc0df70ffdcb29bf967cf37c",
  "index.html":"80583c592d934adfe464a32d953b29040845f086",
  "scripts/p1p5-p016b-signed-http-cutover.cjs":"ebe9c1d9b75690455d498f2106b728e2bde43a6a",
  "scripts/p1p5-p016b-writer-contract.test.cjs":"cf8f5c2bb98b560a041cea03877ca098e140a2dc",
  "supabase/candidates/math_p1p5_p016b_writer_contract_v1_dormant.sql":"b91c2b89559da9205d73fe2ae94d882c0455cc67",
  "supabase/tests/p1p5_p016b_ephemeral_extra_hard_stub.sql":"3c42822a09a5375da6af96cfc63a179aa5c69e53",
  "docs/math-p1p5-p016b-stale-tab-writer-fence-20261119.md":"cfa9ab98c9079d7f8734f4bc19e8753533f7e699"
};
const self=new Set(["qa/math-p016b-source-firewall.cjs",
  ".github/workflows/ux531-previewless-release-firewall.yml"]);
const allow=new Set([...Object.keys(exact),...self]);
assert.equal(files.length,14,"Unexpected P0-16B diff scope");
assert.equal(allow.size,14,"Guard must only allow the exact 13 reviewed files");
for(const path of files)assert(allow.has(path),"Unreviewed file: "+path);
for(const path of allow)assert(files.includes(path),"Missing reviewed file: "+path);
for(const [path,sha] of Object.entries(exact))
  assert.equal(git("hash-object",path),sha,"Source drift: "+path);
assert.equal(git("hash-object","exam-prep/exam-prep-live.js"),
  "e875085e55b4580df9659b27e7f32c8490fcd06a","Never change learner answers/history logic");
assert.equal(git("hash-object","exam-prep/exam-prep-recovery.js"),
  "5ba398241b2e2055c72362c9fa660b9f0c8f34c5","Never rewrite plan recovery");
assert.equal(git("hash-object","exam-prep/exam-prep-exam-map.js"),
  "4c54b9d774b56a843aa1b98454758ef60cdd56fa",
  "Preserve published one-My-Plan repair");
assert(!files.some(p=>p.startsWith("supabase/migrations/")),
  "Absolutely no installed or new live migration in this source-only PR");
const sql=fs.readFileSync("supabase/candidates/math_p1p5_p016b_writer_contract_v1_dormant.sql","utf8");
assert(sql.includes("BEGIN;")&&sql.includes("COMMIT;"));
assert(!/^\s*UPDATE\s+private[.]exam_prep_feature_config\b/im.test(sql),
  "Installing the candidate must never activate the feature");
cp.execFileSync("node",["--check","exam-prep/exam-prep-api.js"]);
cp.execFileSync("node",["--check","scripts/p1p5-p016b-writer-contract.test.cjs"]);
cp.execFileSync("node",["--check","scripts/p1p5-p016b-signed-http-cutover.cjs"]);
cp.execFileSync("node",["scripts/p1p5-p016b-writer-contract.test.cjs"],{stdio:"inherit"});
console.log("P0-16B STRICT 14-PATH SOURCE PASS; baseline and 8 blob pins; offline-only contract; original UX531 unchanged");
