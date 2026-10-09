'use strict';
// QA Preview composition only. The Stage09 signed source stays immutable.
// Restore the one-time Mathematics Practice v2 cleanup, but limit deletion to
// provably obsolete v2 history keys; new v3 attempts and shared drafts survive.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = path.join(__dirname, 'dist', 'security', 'practice-v2-local-reset.js');
const htmlFile = path.join(__dirname, 'dist', 'index.html');
const previous = fs.readFileSync(source, 'utf8');
const html = fs.readFileSync(htmlFile, 'utf8');
if (!previous.includes('iclub_math_practice_v2_local_reset_20261007_v1') ||
    !previous.includes('storage.removeItem(DRAFT_KEY)') ||
    !previous.includes('globalThis.iclubMathPracticeV2ResetAfterPublish = (client) => {'))
  throw Error('Unexpected original reset source; refusing to patch');
const previousPin = 'security/practice-v2-local-reset.js?v=mathv2postpublish1';
if (html.split(previousPin).length !== 2)
  throw Error('Unexpected Practice reset cache pin');
const legacyGuard = '<script src="practice-v2-reset-preserve-guard.js?v=stage03preserve1"></script>';
if (html.split(legacyGuard).length !== 2)
  throw Error('Unexpected old QA guard; previous no-op must be replaced');


const safe = [
  '(() => {',
  '  "use strict";',
  '  const MARKER = "iclub_math_practice_v2_local_reset_20261007_v1";',
  '  const LEGACY_PREFIX = "practice_history_v2:mathematics:tour_";',
  '  let inFlight = null;',
  '  globalThis.iclubMathPracticeV2ResetAfterPublish = (client) => {',
  '    if (inFlight) return inFlight;',
  '    inFlight = (async () => {',
  '      let storage;',
  '      try {',
  '        storage = globalThis.localStorage;',
  '        if (!storage || storage.getItem(MARKER) === "1" ||',
  '            !client || typeof client.rpc !== "function") return false;',
  '      } catch { return false; }',
  '      let timer = null;',
  '      let result;',
  '      try {',
  '        result = await Promise.race([',
  '          Promise.resolve().then(() => client.rpc("is_math_practice_v2_published_safe_v1")),',
  '          new Promise(resolve => {',
  '            timer = setTimeout(() => resolve({ data: false, error: "timeout" }), 2500);',
  '          })',
  '        ]);',
  '      } catch { return false; }',
  '      finally { if (timer !== null) clearTimeout(timer); }',
  '      if (result?.error || result?.data !== true) return false;',
  '      try {',
  '        const legacyKeys = [];',
  '        for (let i = 0; i < storage.length; i += 1) {',
  '          const key = storage.key(i);',
  '          if (typeof key === "string" && key.toLowerCase().startsWith(LEGACY_PREFIX))',
  '            legacyKeys.push(key);',
  '        }',
  '        for (const key of legacyKeys) storage.removeItem(key);',
  '        storage.setItem(MARKER, "1");',
  '        return true;',
  '      } catch { return false; }',
  '    })();',
  '    return inFlight.finally(() => { inFlight = null; });',
  '  };',
  '})();',
  ''
].join('\n');
new Function(safe);
for (const forbidden of ['iclub_practice_draft_v1', 'iclub_state_v1',
                          'iclub_my_recs_v1', 'practice_history_v3', '.clear('])
  if (safe.includes(forbidden)) throw Error('New-bank protection violation: ' + forbidden);
function storage(initial) {
  const map = new Map(Object.entries(initial));
  const writes = [];
  return {
    get length() { return map.size; },
    key(n) { return Array.from(map.keys())[n] ?? null; },
    getItem(key) { return map.has(key) ? map.get(key) : null; },
    setItem(key, value) { writes.push('set:' + key); map.set(key, String(value)); },
    removeItem(key) { writes.push('remove:' + key); map.delete(key); },
    map, writes
  };
}
async function test() {
  const marker = 'iclub_math_practice_v2_local_reset_20261007_v1';
  const old = 'practice_history_v2:mathematics:tour_1';
  const next = 'practice_history_v3:mathematics:tour_1';
  const draft = 'iclub_practice_draft_v1';
  const state = 'iclub_state_v1';
  const recs = 'iclub_my_recs_v1';
  const other = 'practice_history_v2:biology:tour_1';
  function boot(store) {
    const env = {localStorage: store, setTimeout, clearTimeout};
    vm.runInNewContext(safe, env, {timeout: 1000});
    return env.iclubMathPracticeV2ResetAfterPublish;
  }
  const initial = {[old]:'old', [next]:'new', [draft]:'active-new-draft',
                   [state]:'live-state', [recs]:'user-recs', [other]:'biology'};
  const s = storage(initial);
  const run = boot(s);
  let called = 0;
  const published = {rpc: async name => {
    if (name !== 'is_math_practice_v2_published_safe_v1') throw Error('Wrong RPC');
    called++; return {data:true, error:null};
  }};
  if (await run({rpc: async () => ({data:false})}) !== false || s.writes.length)
    throw Error('Before publish/failed proof must preserve all state');
  if (await run(published) !== true || s.map.has(old) ||
      s.map.get(marker) !== '1' || called !== 1)
    throw Error('Published legacy history cleanup failed');
  for (const key of [next,draft,state,recs,other])
    if (s.map.get(key) !== initial[key]) throw Error('Protected data changed: ' + key);
  const count = s.writes.length;
  if (await run(published) !== false || s.writes.length !== count || called !== 1)
    throw Error('One-time marker failed, reset repeated');
  const offline = storage(initial);
  if (await boot(offline)({rpc:async () => {throw Error('offline');}}) !== false ||
      offline.writes.length) throw Error('Offline error erased state');
  const noAuth = storage(initial);
  if (await boot(noAuth)(null) !== false || noAuth.writes.length)
    throw Error('Unauthenticated call erased state');
  console.log('STAGE03_MATH_LEGACY_RESET_GUARD_OK cases=5 v3_preserved=1 draft_preserved=1 one_time=1');
}
test().then(() => {
  fs.writeFileSync(source, safe, 'utf8');
  fs.writeFileSync(htmlFile,
    html.replace(previousPin, 'security/practice-v2-local-reset.js?v=stage03oldhistory2')
      .replace(legacyGuard, ''), 'utf8');
  console.log('STAGE03_MATH_LEGACY_RESET_READY verified_server_proof=1 old_namespace_only=1 stale_guard_removed=1');
}).catch(error => { console.error(error); process.exitCode = 1; });
