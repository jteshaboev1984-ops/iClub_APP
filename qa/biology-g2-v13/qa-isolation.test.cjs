'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const html=fs.readFileSync('qa/biology-g2-v13/index.html','utf8');

test('historical Biology G2 fixture is network isolated',()=>{
  for(const directive of ["default-src 'none'","connect-src 'none'","form-action 'none'","img-src 'none'","base-uri 'none'"])
    assert.ok(html.includes(directive),`missing CSP ${directive}`);
  assert.doesNotMatch(html,/<script[^>]+src\s*=/i);
  assert.doesNotMatch(html,/<(?:form|iframe|img|link|video|audio)\b[^>]*\bsrc\s*=/i);
  assert.doesNotMatch(html,/\b(?:fetch|XMLHttpRequest|WebSocket|indexedDB|localStorage|sessionStorage|sendBeacon)\s*(?:\(|\.)/i);
  assert.doesNotMatch(html,/document\.cookie|navigator\.serviceWorker|eval\s*\(/i);
});
test('QA is multilingual and in-memory-only',()=>{
  for(const lang of ['ru','uz','en'])assert.ok(html.includes(`data-lang="${lang}"`),`missing locale ${lang}`);
  assert.match(html,/const words\s*=\s*\{/);
  assert.match(html,/Object\.defineProperty\(window,'iClubSyntheticQa'/);
  assert.match(html,/SYNTHETIC QA FIXTURE ONLY/);
});
test('no release or app entrypoint modifications',()=>{
  const readme=fs.readFileSync('qa/biology-g2-v13/README.md','utf8');
  assert.match(readme,/not\*\* a learner route|not\*\* a learner|not a learner route/i);
  assert.match(readme,/no.*production SQL|No production SQL/i);
});
