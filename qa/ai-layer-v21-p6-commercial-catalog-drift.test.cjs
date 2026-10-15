"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs");
const snap=require("./ai-layer-v21-p6-live-commercial-catalog-snapshot.json");
const {verifyCommercialCatalog}=require("./ai-layer-v21-p6-commercial-catalog-drift.cjs");
const pg=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_commercial_pg_proc_READ_ONLY.sql","utf8");
const valid=()=>snap.functions.map(x=>({
 schema:x.schema,name:x.name,identity_args:x.identityArgs,
 definition_md5:x.definitionMd5
}));
test("§103 pin exact two audited commercial functions without any release grant",()=>{
 const good=verifyCommercialCatalog(valid());
 a.equal(good.matched,true);
 a.equal(good.metadataOnly,true);
 a.equal(good.releaseAllowed,false);
 a.equal(good.requiresIndependentAuthorization,true);
 a.equal(snap.liveReleaseAllowed,false);
 a.equal(snap.automaticLiveDatabaseConnection,false);
 a.equal(snap.allowsLiveStudentQuery,false);
});
test("§103 deny changed function name, arguments, definition or row set",()=>{
 for(const transform of [
  rows=>{rows[0].definition_md5="a".repeat(32)},
  rows=>{rows[1].identity_args="user_id uuid"},
  rows=>{rows[0].schema="private"},
  rows=>{rows[0].name="wrong"},
  rows=>{rows[1]=structuredClone(rows[0])},
  rows=>{rows.pop()},
  rows=>{rows.push({schema:"public",name:"fake"})},
  rows=>{rows[0].definition_md5=undefined}
 ]){
  const rows=valid();transform(rows);
  a.equal(verifyCommercialCatalog(rows).matched,false,transform.toString());
 }
 for(const rows of [null,undefined,[],{},[false],[null]]){
  a.equal(verifyCommercialCatalog(rows).matched,false);
 }
});
test("§103 catalog probe is metadata-only and names pinned functions",()=>{
 a.match(pg,/pg_catalog\.pg_proc/);
 a.match(pg,/pg_catalog\.pg_namespace/);
 a.match(pg,/pg_get_function_identity_arguments/);
 a.match(pg,/pg_get_functiondef/);
 for(const row of snap.functions)a(pg.includes(row.name),
  "Catalog probe missing "+row.name);
 a.doesNotMatch(pg,/\b(?:INSERT|UPDATE|DELETE|ALTER|CREATE|DROP|TRUNCATE|COPY|GRANT|REVOKE)\s+(?:ON|TABLE|SCHEMA|FROM|INTO|FUNCTION)\b/i);
 a.doesNotMatch(pg,/\b(?:public\.users|private\.iclub_subscription_entitlements|private\.iclub_subject_slot_selections)\b/i);
});
