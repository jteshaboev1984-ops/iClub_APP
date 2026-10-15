"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs");
const sql=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_home_atomic_delivery_READ_ONLY.sql","utf8");
test("§107 MVCC Home pre-delivery snapshot is one read-only statement, no writes",()=>{
 a.match(sql,/^-- §107/);
 a.match(sql,/\bWITH\s+parameters AS\s*\(/);
 a.match(sql,/\bSELECT EXISTS\s*\(/);
 a.match(sql,/current_database\(\) ~ '\^iclub_ai_v21_scratch_/);
 a.match(sql,/private\.iclub_ai_v21_current_screen/);
 a.match(sql,/private\.iclub_subject_slot_selections/);
 a.match(sql,/private\.iclub_ai_v21_home_source_test_releases/);
 a.match(sql,/private\.iclub_commercial_access_config/);
 a.match(sql,/private\.iclub_ai_qa_home_feature_gate/);
 a.match(sql,/public\.get_iclub_ai_v21_home_scan_scratch_service/);
 a.match(sql,/private\.iclub_ai_has_active_protected_assessment_v1/);
 for(const word of ["{{USER}}","{{HANDLE}}","{{LOCALE}}","{{REVISION}}",
  "{{EXPIRES_MS}}","{{ACTIONS_JSON}}"])a(sql.includes(word),word);
 a.doesNotMatch(sql,/\b(?:INSERT\s+INTO|UPDATE\s+\w+|DELETE\s+FROM|CREATE\s+(?:TABLE|FUNCTION)|ALTER\s+TABLE|DROP\s+TABLE|TRUNCATE\s+TABLE|GRANT\s+\w+|REVOKE\s+\w+|COPY\s+\w+)\b/i);
 a.equal(sql.split(/\bSELECT EXISTS\s*\(/).length>=2,true);
});
