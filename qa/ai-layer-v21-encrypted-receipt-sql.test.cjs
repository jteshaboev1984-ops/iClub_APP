"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs");
const s=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_encrypted_reply_UNAPPLIED.sql","utf8");
const pg=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_encrypted_reply_local_pg.psql","utf8");
test("Receipt SQL is local scratch only and stores no plaintext or encryption keys",()=>{
 assert.match(s,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(s,/ciphertext text NOT NULL/);
 assert.match(s,/auth_tag text NOT NULL/);
 assert.match(s,/REVOKE ALL ON TABLE private\.iclub_ai_v21_encrypted_reply_receipts/);
 assert.doesNotMatch(s,/CREATE TABLE.*raw_prompt|api_key|plaintext_response/i);
});
test("Completion and encrypted receipt insertion occur atomically",()=>{
 assert.match(s,/v:=public\.finish_iclub_ai_delivery_service_v21/);
 assert.match(s,/INSERT INTO private\.iclub_ai_v21_encrypted_reply_receipts/);
 assert.match(pg,/synthetic_receipt_insert_failed/);
 assert.match(pg,/Half-written ciphertext or charged learner/);
 assert.match(pg,/Quota and receipt did not complete together/);
});
test("Read response is ciphertext-only and matching identity, finalized, unexpired",()=>{
 for(const k of ["d.status='completed'","q.status='completed'",
  "a.expires_at>now()","a.identity_digest=p_identity_digest",
  "r.ciphertext","r.auth_tag","r.key_ref"])assert.ok(s.includes(k),k);
 assert.match(pg,/Wrong session accepted/);
 assert.match(pg,/Wrong source digest accepted/);
 assert.match(pg,/Expired cipher visible/);
 assert.match(pg,/Duplicate receipt committed/);
});

test("Ciphertext length validation is PostgreSQL-compatible",()=>{
 assert.doesNotMatch(s,/\{20,11000\}/);
 assert.match(s,/length\(ciphertext\) BETWEEN 20 AND 11000/);
 assert.match(s,/length\(p_ciphertext\) NOT BETWEEN 20 AND 11000/);
});
