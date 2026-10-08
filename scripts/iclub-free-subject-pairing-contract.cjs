#!/usr/bin/env node
"use strict";
const fs = require("fs");
const assert = (condition, message) => { if (!condition) throw new Error(message); };
const sql = fs.readFileSync("supabase/migrations/20261008160000_iclub_free_subject_auto_competitive_v2.sql","utf8");
const rollback = fs.readFileSync("supabase/reversions/20261008160000_iclub_free_subject_auto_competitive_v2_revert.sql","utf8");
const ui = fs.readFileSync("subject-access-ui.js","utf8");
const matrix = fs.readFileSync("supabase/tests/iclub_subject_selection_shadow_ui_v1_matrix.sql","utf8");
for (const part of [
  "create or replace function public.choose_iclub_my_free_subject_v2",
  "auth.uid()",
  "v_cfg.subject_limits_mode<>'shadow'",
  "private.iclub_rollout_allows_user_v1",
  "coalesce(u.is_school_student,false)",
  "lower(coalesce(v_caps->>'plan_code',''))<>'free'",
  "v_subject.type<>'main'",
  "pg_advisory_xact_lock",
  "free_subject_swap_v2",
  "free_subject_choice_v2",
  "competitive_selected',v_school",
  "access_unchanged',true",
  "grant execute on function public.choose_iclub_my_free_subject_v2(text) to authenticated"
]) assert(sql.toLowerCase().includes(part.toLowerCase()),"Missing Free subject server invariant: "+part);
assert(!/\b(?:update|delete\s+from|insert\s+into)\s+public\.(?:users|user_subjects|practice_attempts|tour_attempts|certificates|recommendations)\b/i.test(sql),
  "Free migration must not write historic learner data");
assert(sql.includes("raise exception 'free_subject_choice_failed'"),
  "Failure after slot clearing must roll the entire transaction back");
assert(sql.includes("p_competitive_selected:=coalesce(p_study_selected,false)"),
  "Browser cannot bypass automatic Free pairing via old subject RPC");
assert(rollback.includes("drop function if exists public.choose_iclub_my_free_subject_v2") &&
  rollback.includes("subject_selection_ui_enabled or subject_limits_mode<>'off'"),
  "Free rule rollback must restore old code only while unused");
assert(ui.includes('window.sb.rpc("choose_iclub_my_free_subject_v2"'),"Free UI does not use atomic server command");
assert(ui.includes('if (planCode() === "free") renderFreeCompetitive(competitive)'),
  "Free selector still shows duplicate Competitive switches");
assert(ui.includes('freeCompetitiveAuto: "Tanlagan faningiz musobaqalar'),
  "Natural Uzbek Free Competition text missing");
assert(matrix.includes("Free atomic subject swap failed") &&
  matrix.includes("Non-school Free incorrectly acquired Competitive"),
  "Missing school/non-school Free database regression checks");
console.log("iClub approved Free auto-Competitive pairing: GREEN, dormant, reversible, no legacy data writes.");
