'use strict';
/* QA branch only. Stage 09 checksum-verified builder MUST run first.
 * Unpacks reviewed Stage 03 presentation modules into the ephemeral build,
 * then composes Practice and Exam Prep without changing the signed base files.
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const zlib = require('node:zlib');
const {execFileSync} = require('node:child_process');
const root = __dirname;
const dist = path.join(root, 'dist');
if (!fs.existsSync(path.join(dist, 'index.html')) ||
    !fs.existsSync(path.join(dist, 'exam-prep', 'exam-prep-host.js')))
  throw new Error('Stage09 verified dist is required before Stage03');
const expected = Object.freeze({
  'practice-results-tabs.js': '9cb30778e03586d061034991f25330b65e96c463d4a6f3910e96680d7c00d0c7',
  'practice-results-tabs.css': '87e4571c5b9f1e7eaeb6e20243b6414c60c4e0dcb53eed031137e681fe4e91eb',
  'practice-v2-reset-preserve-guard.js': '6744b97b656baa9058b7b1b488d83fc87d3784b44468ca7d7c91b19403963934',
  'stage03-preview-compose.cjs': 'e8333f880763be88f6ab9c509e0b492248045597182c6b05f5855699426a5ca2',
  'stage03-exam-prep-all-subjects.cjs': '3cb40513d9d512befcf73feb86bd7ef4ea4a0e678f8a5596627653b0d3b03b9e'
});
const encoded = fs.readFileSync(path.join(root,'stage03-ui-package.pack'),'utf8').trim();
const pkg = JSON.parse(zlib.gunzipSync(Buffer.from(encoded,'base64')).toString('utf8'));
if (Object.keys(pkg).sort().join('|') !== Object.keys(expected).sort().join('|'))
  throw new Error('Unexpected Stage03 package contents');
const content = {};
for (const [name, hash] of Object.entries(expected)) {
  if (typeof pkg[name] !== 'string' ||
      fs.existsSync(path.join(root,name)) ||
      (name.endsWith('.js') || name.endsWith('.css')) && fs.existsSync(path.join(dist,name)))
    throw new Error('Unsafe Stage03 file collision '+name);
  const data = Buffer.from(pkg[name],'utf8');
  if (crypto.createHash('sha256').update(data).digest('hex') !== hash)
    throw new Error('Stage03 integrity check failed '+name);
  content[name] = data;
}
for (const [name, data] of Object.entries(content))
  fs.writeFileSync(path.join(root,name),data);
for (const name of ['practice-results-tabs.js','practice-results-tabs.css','practice-v2-reset-preserve-guard.js'])
  fs.copyFileSync(path.join(root,name),path.join(dist,name));
execFileSync(process.execPath,['stage03-preview-compose.cjs'],{cwd:root,stdio:'inherit'});
execFileSync(process.execPath,['stage03-exam-prep-all-subjects.cjs'],{cwd:root,stdio:'inherit'});
const topicChoicePatch = path.join(root,'stage03-topic-choice-decision.cjs');
if (!fs.existsSync(topicChoicePatch)) throw new Error('Missing approved topic choice update');
const patchSource = fs.readFileSync(topicChoicePatch,'utf8');
if (!patchSource.includes('STAGE03_TOPIC_DECISION_READY') ||
    !patchSource.includes('if (decision !== "replace") return;'))
  throw new Error('Topic choice update contract mismatch');
execFileSync(process.execPath,['stage03-topic-choice-decision.cjs'],{cwd:root,stdio:'inherit'});
// Preserve the signed Stage09 build; compose AI UI corrections only into ephemeral Preview assets.
for (const script of ['stage06-ai-chat-context.cjs','stage07-context-tutor-priority.cjs']) {
  const full = path.join(root,script);
  if (!fs.existsSync(full)) throw new Error('Missing approved QA chat composition '+script);
  execFileSync(process.execPath,[script],{cwd:root,stdio:'inherit'});
}
const index = fs.readFileSync(path.join(dist,'index.html'),'utf8');
const reset = index.indexOf('security/practice-v2-local-reset.js');
const guard = index.indexOf('practice-v2-reset-preserve-guard.js');
const app = index.indexOf('<script src="app.js?');
if (!(reset >= 0 && reset < guard && guard < app &&
      index.includes('practice-results-tabs.js?v=stage03tabs1') &&
      index.includes('p304premium2-mathv2reset1-allsubjects1')))
  throw new Error('Stage03 final app load order / script pin mismatch');
console.log('STAGE03_COMBINED_PREVIEW_READY source_protected=1 new_public_modules=3');
