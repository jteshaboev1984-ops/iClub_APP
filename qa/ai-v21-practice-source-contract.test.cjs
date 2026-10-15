"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const app=readFileSync("app.js","utf8");
const migration=readFileSync(
 "supabase/migrations/20261007006700_math_practice_v2_deterministic_feedback_v5.sql","utf8");
const resolver=readFileSync(
 "qa/sql_drafts/iclub_ai_v21_practice_attempt_resolution_UNAPPLIED.sql","utf8");
const ts=readFileSync("qa/edge_v21/practice_resolver_service.ts","utf8");
test("real app passes Safe V5 finalizer's legacy attempt id, not canonical session id",()=>{
 assert.match(app,/safePersistedResult\s*=\s*\{[\s\S]*?attemptId:\s*Number\(finalResult\?\.attempt_id/);
 assert.match(app,/attemptId:\s*Number\(quiz\.safePersistedResult\.attemptId/);
 assert.match(app,/dataset\.practiceAiAttemptId\s*=\s*String\(attemptId\)/);
 const at=migration.indexOf("create or replace function public.finalize_practice_session_safe_v5(");
 assert.ok(at>0,"Safe V5 finalization function missing");
 const part=migration.slice(at);
 for(const exact of [
  "legacy_attempt_id=v_attempt_id",
  "'attempt_id',v_attempt_id",
  "'session_id',p_session_id"
 ])assert.ok(part.includes(exact),"V5 finalizer drift: "+exact);
});
test("exact ID bridging joins V4 session, legacy attempt and owned answered question",()=>{
 for(const phrase of [
  "s.legacy_attempt_id=p_attempt_reference",
  "a.session_id=s.id AND a.question_id=p_question_id",
  "s.user_id=p_user_id",
  "s.status='finalized'",
  "a.answered_at IS NOT NULL",
  "a.is_correct IS NOT NULL",
  "p_question_id = ANY(s.question_ids)",
  "count(DISTINCT s.id)"
 ])assert.ok(resolver.includes(phrase),"Resolver drift: "+phrase);
 assert.ok(resolver.includes("'sessionId',v_session"));
 assert.ok(!resolver.includes("FROM public.practice_attempts"),
  "Only V4 canonical ownership should be resolvable");
});
test("separate resolver RPC never substitutes legacy attempt for V4 session ID",()=>{
 assert.ok(ts.includes('resolve_iclub_ai_v21_practice_attempt_service'));
 assert.ok(ts.includes("p_attempt_reference:attemptReference"));
 assert.ok(ts.includes("p_question_id:questionId"));
 const code=readFileSync("qa/ai-v21-real-academic-screen-bridge.cjs","utf8");
 assert.ok(code.includes("this.client.openPractice(resolved.sessionId,candidate.questionId)"));
 assert.ok(!code.includes("this.client.openPractice(candidate.attemptReference"));
});
