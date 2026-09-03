import fs from 'node:fs';
import { range } from './p0-02-aux-patcher.mjs';

const path = 'app.js';
let app = fs.readFileSync(path, 'utf8');
const r = range(app, 'createTourAttempt');
const callsBefore = (app.match(/\bcreateTourAttempt\s*\(/g) || []).length;
if (callsBefore !== 1) throw new Error(`createTourAttempt must be declaration-only before inerting; found ${callsBefore} occurrences`);

const stub = `async function createTourAttempt(uid, tourId) {
  void uid;
  void tourId;
  // P0 hardening: active Tour creation is server-authoritative via start_tour_attempt_safe_v4.
  return null;
}`;
app = app.slice(0, r.start) + stub + app.slice(r.end);

const callsAfter = (app.match(/\bcreateTourAttempt\s*\(/g) || []).length;
if (callsAfter !== 1) throw new Error(`createTourAttempt stub count mismatch: ${callsAfter}`);
const after = range(app, 'createTourAttempt').text;
for (const banned of ['.from("tour_attempts")', '.insert(', '.delete(', '.update(']) {
  if (after.includes(banned)) throw new Error(`createTourAttempt still contains ${banned}`);
}

fs.writeFileSync(path, app);
