import fs from 'node:fs';
import { replaceNamed } from './p0-02-aux-patcher.mjs';

function assert(ok, message) { if (!ok) throw new Error(message); }
function replaceOnce(src, needle, replacement, label) {
  const first = src.indexOf(needle);
  assert(first >= 0, `${label}: anchor missing`);
  assert(src.indexOf(needle, first + needle.length) < 0, `${label}: anchor not unique`);
  return src.slice(0, first) + replacement + src.slice(first + needle.length);
}

let app = fs.readFileSync('app.js','utf8');
let html = fs.readFileSync('index.html','utf8');

app = replaceNamed(app, 'syncCredentialsToSupabaseOnce', `async function syncCredentialsToSupabaseOnce() {
  if (__credSyncInFlight) return;
  if (!window.sb) return;

  __credSyncInFlight = true;
  try {
    const { data: userData } = await window.sb.auth.getUser();
    const uid = userData?.user?.id;
    if (!uid) return;

    const canWriteCreds = await hasDbUserRow(uid);
    if (!canWriteCreds) return;

    const c = credentialsStore();
    const snap = buildCredentialSnapshotForDb(c);

    const { error } = await window.sb.rpc("sync_user_credentials_safe_v1", {
      p_snapshot: snap
    });
    if (error) throw error;

    // The server is authoritative. Re-hydrate immediately so a rejected
    // client-side candidate status cannot remain visible in local UI state.
    __credDbReady = false;
    await ensureCredentialsDbSynced();
  } catch (e) {
    try { console.error("[cred] safe sync exception:", e); } catch {}
  } finally {
    __credSyncInFlight = false;
  }
}`);

html = replaceOnce(
  html,
  'app.js?v=support4-p0credreview1',
  'app.js?v=support4-p0credsafe1',
  'app cache key'
);

const fnStart = app.indexOf('async function syncCredentialsToSupabaseOnce()');
assert(fnStart >= 0, 'safe credential sync function missing');
const fnEnd = app.indexOf('\n}', fnStart);
assert(app.includes('window.sb.rpc("sync_user_credentials_safe_v1"'), 'credential safe RPC call missing');
assert(!app.slice(fnStart, fnStart + 2400).includes('.from("user_credentials")'), 'credential sync still writes table directly');
assert(app.includes('__credDbReady = false;\n    await ensureCredentialsDbSynced();'), 'authoritative rehydrate missing');

fs.writeFileSync('app.js', app);
fs.writeFileSync('index.html', html);
