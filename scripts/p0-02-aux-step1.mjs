import fs from 'node:fs';

const APP = 'app.js';
let app = fs.readFileSync(APP, 'utf8');

function assert(ok, msg) { if (!ok) throw new Error(msg); }

function matchingBrace(src, open) {
  assert(src[open] === '{', 'opening brace expected');
  let depth = 0, mode = 'code', quote = '', escaped = false, tpl = 0;
  for (let i = open; i < src.length; i++) {
    const ch = src[i], nx = src[i + 1] || '';
    if (mode === 'line') { if (ch === '\n') mode = 'code'; continue; }
    if (mode === 'block') { if (ch === '*' && nx === '/') { mode = 'code'; i++; } continue; }
    if (mode === 'string') {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if (ch === quote) { mode = 'code'; quote = ''; }
      continue;
    }
    if (mode === 'template') {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if (ch === '`' && tpl === 0) { mode = 'code'; continue; }
      if (ch === '$' && nx === '{') { tpl++; i++; continue; }
      if (tpl > 0) { if (ch === '{') tpl++; else if (ch === '}') tpl--; }
      continue;
    }
    if (ch === '/' && nx === '/') { mode = 'line'; i++; continue; }
    if (ch === '/' && nx === '*') { mode = 'block'; i++; continue; }
    if (ch === '"' || ch === "'") { mode = 'string'; quote = ch; continue; }
    if (ch === '`') { mode = 'template'; tpl = 0; continue; }
    if (ch === '{') depth++;
    else if (ch === '}') { depth--; if (depth === 0) return i; }
  }
  throw new Error('unmatched brace');
}

function range(name) {
  const re = new RegExp(`\\b(?:async\\s+)?function\\s+${name}\\s*\\(`, 'g');
  const hits = Array.from(app.matchAll(re));
  assert(hits.length === 1, `${name}: expected one declaration, got ${hits.length}`);
  const start = hits[0].index;
  const open = app.indexOf('{', start);
  const end = matchingBrace(app, open) + 1;
  return { start, end, text: app.slice(start, end) };
}

function replace(name, code) {
  const r = range(name);
  app = app.slice(0, r.start) + code.trim() + app.slice(r.end);
}

replace('restorePracticeQuizSecrets', `async function restorePracticeQuizSecrets(quiz) {
  try {
    if (!quiz || quiz.mode !== "practice") return null;
    if (quiz.safeSessionId && !quiz.drillType) {
      const api = getPracticeSafeApi();
      if (!api?.questions) return null;
      return buildPracticeSafeQuizFromRows(quiz, await api.questions(Number(quiz.safeSessionId)));
    }
    if (quiz.safeDrillSessionId && quiz.drillType) {
      const api = getPracticeSafeApi()?.drill;
      if (!api?.questions) return null;
      return buildPracticeSafeQuizFromRows(quiz, await api.questions(Number(quiz.safeDrillSessionId)));
    }
  } catch (error) {
    try { trackEvent("practice_safe_resume_error", { message: String(error?.message || error || "unknown"), subject_key: quiz?.subjectKey || null, drill_type: quiz?.drillType || null }); } catch {}
  }
  return null;
}`);

replace('buildPracticeSet', `async function buildPracticeSet(subjectKey) {
  void subjectKey;
  return [];
}`);

replace('buildPracticeSetForTour', `async function buildPracticeSetForTour(subjectKey, forcedTourNo) {
  void subjectKey; void forcedTourNo;
  return [];
}`);

replace('buildPastPracticeSet', `async function buildPastPracticeSet(subjectKey) {
  void subjectKey;
  return [];
}`);

assert(!range('restorePracticeQuizSecrets').text.includes('.from("questions")'), 'restore still has direct questions read');
assert(!range('buildPracticeSet').text.includes('.from("questions")'), 'buildPracticeSet still has direct questions read');
assert(!range('buildPracticeSetForTour').text.includes('.from("questions")'), 'buildPracticeSetForTour still has direct questions read');
assert(!range('buildPastPracticeSet').text.includes('buildPracticeSetForTour'), 'past builder still uses legacy builder');

fs.writeFileSync(APP, app);
