#!/usr/bin/env node
'use strict';
// Issue #412: provider-free, static UI/source contract (not authenticated E2E).
// Existing separate PG17/GoTrue/Chromium workflow covers the wider Tutor route.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const tutor=fs.readFileSync('iclub-ai-v21-ui.js','utf8');
const html=fs.readFileSync('index.html','utf8');
const prepared=fs.readFileSync('iclub-ai-v21-beta-client.js','utf8');

assert.equal((tutor.match(/academicSourceUnavailable:/g)||[]).length,3,
  'Every RU/UZ/EN copy block must have the academic no-source fallback');
for(const phrase of [
  'нет доступного утверждённого объяснения iClub',
  'tasdiqlangan izoh mavjud emas',
  'no approved iClub explanation available'
]) assert(tutor.includes(phrase),'Academic no-source copy missing: '+phrase);
assert(tutor.includes('const academicQuestion = Boolean(academicContext || practiceContext ||'),
  'A server-approved academic path must select the academic no-source notice');
assert(tutor.includes('(context.academic && promptKey === "" && cleanText.length > 0)'),
  'Typed subject/Math Exam Prep question must be distinguished from general help');
assert(tutor.includes('? copy().academicSourceUnavailable') &&
       tutor.includes('window.iClubAiV21BetaClient ? copy().betaScope : copy().inDevelopment'),
  'Academic and general prepared fallback boundaries must coexist');
assert(tutor.includes('["in_development", "subject_not_ready", "approved_source_missing"') &&
       tutor.includes('"source_not_ready", "no_source", "topic_not_released"'),
  'Do not turn missing source into a model answer');
assert(tutor.includes('const PUBLISHED_PREPARED_ACTIONS = new Set([') &&
       tutor.includes('const PREPARED_SCREEN_ACTIONS = Object.freeze({'),
  'Reviewed navigation quick actions must remain intact');
assert(prepared.includes('const EDGE="iclub-ai-v21-prepared"') &&
       prepared.includes('async function askAcademic(') &&
       prepared.includes('async function askPracticePrepared('),
  'Existing provider-free authenticated routes must remain in place');
assert(html.includes('iclub-ai-v21-ui.js?ai-source-availability-20261119-v1'),
  'Updated Tutor asset must have a distinct cache key');
assert(!html.includes('practice-ai-prepared-qa.js') &&
       !html.includes('practice-ai-prepared-qa.css'),
  'Do not accidentally load a second QA Tutor panel');
console.log('AI_TUTOR_PROVIDER_FREE_ACADEMIC_NO_SOURCE_RU_UZ_EN_PASS');
