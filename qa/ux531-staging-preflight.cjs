#!/usr/bin/env node
/* UX #531 staging isolation preflight. Read-only; never authenticates, deploys, or mutates Supabase.
   --audit: report source blockers safely (always exits 0)
   --self-test: exercise fail-closed input validations (no network)
   --enforce: reject a proposed staging artifact until proven NOT to use production backend.
   A successful preflight does NOT replace real HTTP/JWT E2E or account cleanup. */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const ROOT = path.resolve(__dirname, '..');
const PRODUCTION_REF = 'mmmduffgpvwjdpruzikw';
const PRODUCTION_HOST = 'https://' + PRODUCTION_REF + '.supabase.co';

function validateOrigins(uiOrigin, backendOrigin, declaredRef) {
  const ui = new URL(String(uiOrigin || ''));
  const db = new URL(String(backendOrigin || ''));
  assert.equal(ui.protocol, 'https:', 'QA front-end MUST use HTTPS');
  assert.equal(ui.pathname, '/', 'QA app origin must not contain a path');
  assert.equal(ui.search, '', 'QA app origin must not contain query parameters');
  assert.equal(ui.hash, '', 'QA app origin must not contain a fragment');
  assert.notEqual(ui.hostname, 'i-club-app.vercel.app', 'Refusing the live iClub domain');
  assert.notEqual(ui.hostname, 'i-club-app-jasurbeks-projects-c5451f97.vercel.app', 'Refusing live iClub alias');
  assert.equal(db.protocol, 'https:', 'QA backend MUST use HTTPS');
  assert.equal(db.pathname, '/', 'QA backend must be the project root');
  assert.equal(db.search, '', 'QA backend may not contain query parameters');
  assert.equal(db.hash, '', 'QA backend may not contain a fragment');
  const matched = /^([a-z]{20})\.supabase\.co$/.exec(db.hostname);
  assert(matched, 'QA backend must be an explicit separate Supabase project host');
  assert.notEqual(matched[1], PRODUCTION_REF, 'Refusing PRODUCTION iClub Supabase');
  assert.equal(matched[1], declaredRef, 'Isolated project ID must agree with verified backend ref');
  assert.notEqual(ui.hostname, db.hostname, 'UI and DB must have separate origins');
  return { appHost: ui.hostname, backendRef: matched[1] };
}

function scriptsFromHtml(directory) {
  const html = fs.readFileSync(path.join(directory, 'index.html'), 'utf8');
  const out = [];
  const re = /<script\b[^>]*\bsrc=["']([^"']+)["'][^>]*>/gi;
  let match;
  while ((match = re.exec(html))) {
    const src = match[1];
    if (/^https?:\/\//i.test(src) || src.startsWith('//')) continue;
    const relative = decodeURIComponent(src.split('?')[0].split('#')[0]).replace(/^\.?\//, '');
    const absolute = path.resolve(directory, relative);
    assert(absolute.startsWith(directory + path.sep), 'Script path escapes QA artifact: ' + relative);
    assert(fs.existsSync(absolute), 'Missing staged script: ' + relative);
    out.push({ relative, content: fs.readFileSync(absolute, 'utf8') });
  }
  return { html, scripts: out };
}

function findProductionReferences(directory) {
  const inventory = scriptsFromHtml(directory);
  const references = [];
  for (const script of inventory.scripts) {
    const lines = script.content.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes(PRODUCTION_REF)) {
        references.push({ file: script.relative, line: i + 1 });
      }
    }
  }
  return { ...inventory, references };
}

function enforce() {
  const dir = path.resolve(process.env.ICLUB_UX531_STAGE_DIR || '');
  assert(process.env.ICLUB_UX531_STAGE_DIR, 'Missing isolated staging build directory');
  assert(fs.statSync(dir).isDirectory(), 'Staging artifact is not a directory');
  const appUrl = process.env.ICLUB_UX531_STAGE_APP_ORIGIN;
  const dbUrl = process.env.ICLUB_UX531_STAGE_BACKEND_URL;
  const backendRef = process.env.ICLUB_UX531_STAGE_BACKEND_REF;
  const sha = String(process.env.ICLUB_UX531_STAGE_COMMIT_SHA || '');
  assert(/^[a-f0-9]{40}$/.test(sha), 'Must pin exact 40-character staging Git SHA');
  assert.equal(process.env.ICLUB_UX531_STAGE_ISOLATED_CONFIRMED, 'true',
    'Independent backend existence and ownership must be verified out of band');
  const origin = validateOrigins(appUrl, dbUrl, backendRef);
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'ux531-staging-manifest.json'), 'utf8'));
  assert.equal(manifest.commit_sha, sha, 'Artifact commit differs from pinned branch SHA');
  assert.equal(manifest.backend_ref, backendRef, 'Artifact backend differs from verified isolated project');
  const inspected = findProductionReferences(dir);
  assert.equal(inspected.references.length, 0,
    'Staged browser scripts still reference live iClub Supabase: ' +
    inspected.references.map(x => x.file + ':' + x.line).join(', '));
  assert(inspected.html.includes('http-equiv="Content-Security-Policy"'),
    'Staging page needs restrictive browser CSP before its scripts');
  const meta = inspected.html.match(/<meta\b[^>]*http-equiv="Content-Security-Policy"[^>]*>/i);
  assert(meta && meta[0].includes(origin.backendRef + '.supabase.co'),
    'Browser connect-src must explicitly limit API calls to the isolated project');
  assert(inspected.html.includes('content="default-src') || meta[0].includes('connect-src'),
    'Staging CSP must set connect-src; do not rely on CORS');
  const app = fs.readFileSync(path.join(dir, 'app.js'), 'utf8');
  assert(app.includes(dbUrl.replace(/\/$/, '')), 'Staged app.js is not configured for the isolated backend');
  console.log('PREFLIGHT PASS (NOT E2E): inspected browser source; backend=' + origin.backendRef +
    ', sha=' + sha + ', appHost=' + origin.appHost);
}

function audit() {
  const found = findProductionReferences(ROOT);
  const unique = [...new Set(found.references.map(x => x.file))];
  console.log('UX531 staging source audit (READ-ONLY; no network, no auth, no data writes)');
  console.log('Active app includes ' + found.scripts.length + ' local browser scripts.');
  console.log('Production Supabase reference in ' + unique.length + ' directly loaded scripts:');
  for (const filename of unique) {
    console.log(' - ' + filename + ': ' +
      found.references.filter(x => x.file === filename).map(x => x.line).join(', '));
  }
  console.log('STAGING STATUS: BLOCKED until separate backend, rewritten runtime artifact, CSP, exact SHA, and Work E2E.');
}

function selfTest() {
  const fake = 'abcdefghijklmnopqrst';
  const safe = validateOrigins('https://ux531-qa.example.test/', 'https://' + fake + '.supabase.co/', fake);
  assert.equal(safe.backendRef, fake);
  assert.throws(() => validateOrigins('https://ux531-qa.example.test/',
    PRODUCTION_HOST, PRODUCTION_REF), /PRODUCTION/);
  assert.throws(() => validateOrigins('https://i-club-app.vercel.app/',
    'https://' + fake + '.supabase.co/', fake), /live iClub/);
  assert.throws(() => validateOrigins('https://ux531-qa.example.test/',
    'https://' + fake + '.supabase.co/', 'anotherprojectrefxx'), /project ID/);
  console.log('SELF-TEST PASS: separate backend accepted, production and mismatched project IDs rejected.');
}

const mode = process.argv[2] || '--audit';
try {
  if (mode === '--audit') audit();
  else if (mode === '--self-test') selfTest();
  else if (mode === '--enforce') enforce();
  else throw new Error('Use --audit, --self-test or --enforce');
} catch (error) {
  console.error('UX531 STAGING PRE-FLIGHT BLOCKED: ' + error.message);
  process.exitCode = 1;
}
