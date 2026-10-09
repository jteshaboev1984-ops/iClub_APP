'use strict';
/* Temporary protected-preview builder. Does not execute in production.
 * Stage 10 isolated QA build trigger 2026-10-09: keep all application checksums and source unchanged.
 */
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const root = __dirname;
const payloadFile = path.join(root, 'stage09-preview-payload.txt');
const payload = JSON.parse(zlib.gunzipSync(Buffer.from(fs.readFileSync(payloadFile, 'utf8').trim(), 'base64')).toString('utf8'));
if (payload.base_sha !== '702c04bd94f0e16b232236e55298bb5f11462e2e') throw new Error('Unexpected source baseline');
const combinedPatch = Object.values(payload.patches).join('\n');
execFileSync('git', ['apply', '--check', '-'], { cwd: root, input: combinedPatch });
execFileSync('git', ['apply', '-'], { cwd: root, input: combinedPatch });
for (const [relative, contents] of Object.entries(payload.added)) {
  const dest = path.join(root, relative);
  if (!dest.startsWith(root + path.sep) || fs.existsSync(dest)) throw new Error('Unexpected extra source file ' + relative);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, contents, 'utf8');
}
const expected = {
  'app.js': 'a6c25b5e7d74839efa4dd663ba709aaf9a4799160b03031260617b12c158635a',
  'global-ai-ui.js': '955d2392904d28aeab6791db79d045d2a6238761e11d877b8797343c8c6b6964',
  'index.html': '940d087fe47d554e9127696c655d8ceaadca750854f437257fe41f774c762ec8',
  'security/practice-v2-local-reset.js': '25c1bf3e5ef1a888dbfd8e13e3408881afea464567b285eadf594d323bacb53a',
  'supabase/functions/global-ai/index.ts': 'bd98ff8c3a7e925f4193e6280e0a0c83b33deab8ff3d7e60aa7641c4182ca9a0',
  'practice-active-owner-v1.js': '6c999b2acd03f119ebcddbd7db1252c3a65cc6a52b2da3fedafcb166094ea408',
  'practice-draft-identity-v1.js': '0d37eede3880b0c02bbe2fa0e84f0f7d5b6b1331632ab587d7cda0ed6eb70d40',
  'practice-draft-ownership-v1.js': '9e9f1b6fab8d94b8962cdc7e869de791e9420c3b6f8c75ffc70e1dfd9f4793df',
  'supabase/functions/global-ai/stage07_verified_learner_summary.ts': '5e3a346311aea7dc3c9ef79bdb6770a53b6a1bb2bde964b50d9972262e0371b2'
};
for (const [relative, hash] of Object.entries(expected)) {
  const actual = crypto.createHash('sha256').update(fs.readFileSync(path.join(root, relative))).digest('hex');
  if (hash !== actual) throw new Error('Checksum mismatch in ' + relative);
}
const exclude = new Set(['.git', '.github', 'docs', 'qa', 'scripts', 'supabase', 'node_modules', 'dist', '.vercel']);
const approved = /\.(?:html|js|css|json|svg|png|jpg|jpeg|gif|ico|webp|avif|woff2?|ttf|otf|pdf|txt|webmanifest|map)$/i;
const dist = path.join(root, 'dist');
fs.mkdirSync(dist, { recursive: true });
let files = 0;
function copy(from, to, depth = 0) {
  if (depth > 12) throw new Error('Excessive nesting');
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || exclude.has(entry.name) || entry.name.startsWith('STAGE09_') || entry.name.startsWith('stage09-preview-')) continue;
    const source = path.join(from, entry.name), destination = path.join(to, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) { fs.mkdirSync(destination, { recursive: true }); copy(source, destination, depth + 1); }
    else if (entry.isFile() && approved.test(entry.name)) { fs.mkdirSync(path.dirname(destination), { recursive: true }); fs.copyFileSync(source, destination); files++; }
  }
}
copy(root, dist);
if (!fs.existsSync(path.join(dist, 'index.html')) || !fs.existsSync(path.join(dist, 'practice-active-owner-v1.js'))) throw new Error('Preview not complete');
console.log(`STAGE09_PREVIEW_BUILT_OK verified=${Object.keys(expected).length} public_files=${files}`);