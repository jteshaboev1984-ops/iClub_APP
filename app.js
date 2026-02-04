/* =========================================================
   iClub WebApp — app.js (v1 skeleton, aligned to new index.html)
   Plain HTML/CSS/JS, no build tools
   ========================================================= */

(() => {
  "use strict";

    // ---------------------------
  // Helpers
  // ---------------------------
  const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

// ---------------------------
// Tours loading overlay (Subject Tours screen)
// ---------------------------
function showToursLoading() {
  const el = document.getElementById("tours-loading");
  if (!el) return;

  // update label via i18n if available
  const txt = el.querySelector(".tours-loading-text");
  if (txt && typeof t === "function") txt.textContent = t("loading") || txt.textContent;

  el.classList.remove("hidden");
}

function hideToursLoading() {
  const el = document.getElementById("tours-loading");
  if (!el) return;
  el.classList.add("hidden");
}

  function escapeHTML(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  // ---------------------------
  // Credentials: normalize subject_id (IMPORTANT)
  // ---------------------------
  function normSubjectId(v) {
    return String(v ?? "").trim().toLowerCase();
  }

  function safeJsonParse(s, fallback) {
  if (s === null || s === undefined || s === "") return fallback;
  try { return JSON.parse(s); } catch { return fallback; }
}

    // ---------------------------
  // Supabase (v1 connect)
  // ---------------------------
  // ✅ ВАЖНО: заполни эти 2 значения из Supabase → Project Settings → API
  const SUPABASE_URL = "https://mmmduffgpvwjdpruzikw.supabase.co";      // например: https://xxxx.supabase.co
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tbWR1ZmZncHZ3amRwcnV6aWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwNzEwMzksImV4cCI6MjA4NDY0NzAzOX0.G3bV2tOaToFsMr9ejTRuXBHYZQvissIds3g_g7K0t7I"; // anon public key

  let sb = null;

  function getTelegramUserSafe() {
    try {
      return window.Telegram?.WebApp?.initDataUnsafe?.user || null;
    } catch (e) {
      return null;
    }
  }

  async function initSupabaseSession() {
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
    if (!window.supabase?.createClient) return null;

    if (!sb) {
      sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: false,
        },
      });
      window.sb = sb; // удобно для отладки в консоли
    }

    // 1) ensure we have a session (Anonymous Sign-in)
        const { data: sessData } = await sb.auth.getSession();
    if (!sessData?.session) {
      const { data: anonData, error: anonErr } = await sb.auth.signInAnonymously();

      if (anonErr) {
        console.error("[Supabase] Anonymous sign-in failed:", anonErr);

        const statusEl = document.getElementById("splash-status");
        if (statusEl) statusEl.textContent = "Supabase auth error: " + (anonErr.message || "unknown");

        // Не валим приложение — просто работаем без базы (пока не починим настройки)
        return sb;
      }

      // На всякий случай — лог успешного входа
      console.log("[Supabase] Anonymous session OK:", !!anonData?.session);
    }

    // 2) ensure users row exists (id == auth.uid())
    const { data: userData } = await sb.auth.getUser();
    const u = userData?.user;
    if (!u?.id) return sb;

    const tg = getTelegramUserSafe();
    const langGuess = tg?.language_code || (typeof getTelegramLang === "function" ? getTelegramLang() : null) || "ru";

    const payload = {
  id: u.id,
  telegram_user_id: tg?.id ? String(tg.id) : null,
  avatar_url: null,
  language_code: langGuess,
};

// ✅ НЕ перезатираем имя/фамилию в NULL на boot
if (tg?.first_name) payload.first_name = String(tg.first_name).trim();
if (tg?.last_name) payload.last_name = String(tg.last_name).trim();

// upsert by primary key id
await sb.from("users").upsert(payload, { onConflict: "id" });

// ✅ reset subject cache for this session (prevents poisoned null cache)
try { _subjectIdByKeyCache.clear(); } catch {}

// ✅ smoke test: write event (confirms auth + RLS + insert)
await sb.from("app_events").insert({
  user_id: u.id,
  event_type: "boot",
  payload: { has_tg: !!tg, ua: navigator.userAgent },
});

// ✅ Earned Credentials: hydrate local events store from Supabase (only if local empty)
try {
  const changed = await hydrateLocalEventsFromSupabase(sb, u.id);

  // Always recalc after hydration attempt:
  // - changed=true  -> we merged DB events
  // - changed=false -> still ensures daily job runs at least once per day
  try { runDailyCredentialJobs(); } catch {}

  // If we merged something new — update profile UI if it’s already on screen
  if (changed) {
    try { renderProfile(); } catch {}
    try { renderSubjectHub(); } catch {}
  }
} catch {}

    return sb;
  }
 
  function nowISO() {
    return new Date().toISOString();
  }
     // ---------------------------
  // Earned Credentials: hydrate LS.events from Supabase app_events
  // LS.events must be { seq:number, items:[{id,type,payload,ts,day}] }
  // ---------------------------
  async function hydrateLocalEventsFromSupabase(sbClient, userId) {
  if (!sbClient || !userId) return false;

  // Always keep strict format: { seq:number, items:[{id,type,payload,ts,day}] }
  const local = loadJsonLS(LS.events, { seq: 0, items: [] });
  const localItems = Array.isArray(local?.items) ? local.items : [];
  let seq = Number(local?.seq) || 0;

  // Build a fast "already have" set using db_created_at signature
  const have = new Set(
    localItems
      .map(e => e?.payload?._db_created_at ? `${e.type}|${e.payload._db_created_at}` : null)
      .filter(Boolean)
  );

  // Fetch last events from DB (we keep it simple & safe: take recent 5000)
  const { data, error } = await sbClient
    .from("app_events")
    .select("event_type,payload,created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: true })
    .limit(5000);

  if (error) throw error;

  let added = 0;

  (data || []).forEach((r) => {
    const dbCreatedAt = r.created_at || null;
    const sig = dbCreatedAt ? `${r.event_type}|${dbCreatedAt}` : null;

    // If we already merged this DB row before — skip
    if (sig && have.has(sig)) return;

    const ts = Date.parse(dbCreatedAt) || Date.now();

    const evt = {
      id: ++seq,
      type: r.event_type,
      payload: { ...(r.payload || {}), _db_created_at: dbCreatedAt },
      ts,
      day: dayKeyTashkent(ts),
    };

    localItems.push(evt);
    if (sig) have.add(sig);
    added += 1;
  });

  // keep last N events (avoid LS overflow)
  if (localItems.length > 2000) {
    const sliced = localItems.slice(-2000);
    // re-seq to keep ids compact and monotonic
    let s = 0;
    const re = sliced.map(e => ({ ...e, id: ++s }));
    saveJsonLS(LS.events, { seq: s, items: re });
  } else {
    saveJsonLS(LS.events, { seq, items: localItems });
  }

  return added > 0;
}

  // ---------------------------
  // Credentials: hydrate local events from Supabase (only if needed)
  // ---------------------------
  async function hydrateLocalEventsFromSupabaseIfNeeded(sbClient, userId) {
  // Keep ONE truthy hydrator to avoid format corruption
  try {
    await hydrateLocalEventsFromSupabase(sbClient, userId);
  } catch {}
}
   
  // ---------------------------
  // Storage keys
  // ---------------------------
    const LS = {
    state: "iclub_state_v1",
    profile: "iclub_profile_v1",
    practiceDraft: "iclub_practice_draft_v1",
    myRecs: "iclub_my_recs_v1",

    // Earned Credentials (v1.3 FINAL)
    events: "iclub_events_v1",
    credentials: "iclub_credentials_v1"
  };

  // ---------------------------
  // i18n
  // ---------------------------
  const t = (key, vars) => (window.i18n?.t ? window.i18n.t(key, vars) : key);

function applyStaticI18n() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
      const key = el.dataset.i18nPlaceholder;
      if (key) el.setAttribute("placeholder", t(key));
    });
  }

   function applyStaticI18n() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
      const key = el.dataset.i18nPlaceholder;
      if (key) el.setAttribute("placeholder", t(key));
    });
  }

  // =========================================================
  // Earned Credentials — Engine (v1.3 FINAL) + Event Mapping
  // Plain storage (local) + optional Supabase app_events mirror
  // =========================================================

  const TZ = "Asia/Tashkent";

  function loadJsonLS(key, fallback) {
    return safeJsonParse(localStorage.getItem(key), fallback);
  }
  function saveJsonLS(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  function pad2(n) { return String(n).padStart(2, "0"); }

  // Local “calendar day” key in Asia/Tashkent
  function dayKeyTashkent(ts = Date.now()) {
    try {
      const d = new Date(ts);
      const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: TZ,
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
      }).formatToParts(d);
      const y = parts.find(p => p.type === "year")?.value || "1970";
      const m = parts.find(p => p.type === "month")?.value || "01";
      const da = parts.find(p => p.type === "day")?.value || "01";
      return `${y}-${m}-${da}`;
    } catch {
      const d = new Date(ts);
      return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
    }
  }

  function getUserIdSafe() {
    try {
      return window.sb?.auth ? (window.sb.auth.getUser?.().then ? null : null) : null;
    } catch {}
    return null;
  }

    function eventsStore() {
    let s = loadJsonLS(LS.events, { seq: 0, items: [] });

    // accept old shapes:
    // 1) array of events
    // 2) { items: [...], hydrated_at: ... }
    if (Array.isArray(s)) {
      s = { seq: 0, items: s };
    } else if (s && !Array.isArray(s.items) && Array.isArray(s?.items?.items)) {
      // just in case of nested shapes
      s = { seq: 0, items: s.items.items };
    } else if (s && !Array.isArray(s.items) && Array.isArray(s?.items)) {
      s = { seq: 0, items: s.items };
    }

    if (!s || typeof s !== "object") s = { seq: 0, items: [] };
    if (!Array.isArray(s.items)) s.items = [];
    if (typeof s.seq !== "number") s.seq = 0;

    // ✅ normalize events (fix ts/day/id)
    let maxId = 0;
    for (let i = 0; i < s.items.length; i++) {
      const e = s.items[i] || {};
      // ts: allow number OR ISO string
      let ts = e.ts;
      if (typeof ts === "string") {
        const parsed = Date.parse(ts);
        ts = Number.isFinite(parsed) ? parsed : Date.now();
      } else if (typeof ts !== "number" || !Number.isFinite(ts)) {
        ts = Date.now();
      }

      // id
      let id = e.id;
      if (typeof id !== "number" || !Number.isFinite(id)) id = i + 1;

      // day
      const day = e.day || dayKeyTashkent(ts);

      s.items[i] = {
        id,
        type: e.type,
        payload: e.payload || {},
        ts,
        day
      };

      if (id > maxId) maxId = id;
    }

    // ensure seq >= max id
    if (maxId > s.seq) s.seq = maxId;

    // persist normalized store (important for next runs)
    try { saveJsonLS(LS.events, s); } catch {}

    return s;
  }

  function credentialsStore() {
    const base = {
      version: "v1.3",
      last_daily_eval_day: null,

      consistent_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, window_start: null, window_end: null, active_days_14d: 0, last_events: [] },
        // buffer counter required by contract (degradation buffer)
        degradation_counter_days: 0
      },

      focused_study_streak: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, current_subject_id: null, focused_sessions_in_row: 0, last_events: [] }
      },

      active_video_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, videos_decided: 0, videos_completed: 0, completion_rate: 0, last_events: [] },
        decided_by_lesson: {} // { [lesson_id]: { decided: true, completed: bool } }
      },

      practice_mastery_subject: {
        by_subject: {} // subject_id => { status, achieved_at, last_evaluated_at, evidence:{attempts_count,best,median,last_events}, percents:[] }
      },

      error_driven_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, cycles_count: 0, error_reduction: 0, last_events: [] },
        // minimal trace:
        // - last attempt A with errors per (subject_id + topic)
        last_attempt_a: {}, // key => { attempt_key, errors_count, ts, subject_id, topic }
        // - review opened markers for attempt A
        reviewed_attempts: {}, // attempt_key => { ts }
        cycles_count: 0
      },

      research_oriented_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, resource_opens_total: 0, distinct_return_days: 0, last_events: [] }
      },

      fair_play_participant: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, tours_participated: 0, has_critical_violation: false, last_events: [] },
        tours_participated: 0,
        has_critical_violation: false
      }
    };

    const s = loadJsonLS(LS.credentials, base);
    // Ensure missing keys for forward safety
    return Object.assign({}, base, s);
  }

  function saveCredentialsStore(s) {
    saveJsonLS(LS.credentials, s);
  }

  function pushLastEvents(list, eventId, limit = 5) {
    const arr = Array.isArray(list) ? list.slice() : [];
    if (eventId) arr.unshift(eventId);
    return arr.slice(0, limit);
  }

  async function mirrorEventToSupabase(type, payload) {
    try {
      if (!window.sb) return;
      const { data: userData } = await window.sb.auth.getUser();
      const u = userData?.user;
      if (!u?.id) return;
      await window.sb.from("app_events").insert({
        user_id: u.id,
        event_type: type,
        payload: payload || {}
      });
    } catch {
      // Silent: local storage is primary in v1 UI stage
    }
  }

  function trackEvent(type, payload = {}) {
    const store = eventsStore();
    const id = ++store.seq;
    const ts = Date.now();

    const item = {
      id,
      type,
      ts,
      day: dayKeyTashkent(ts),
      payload: payload || {}
    };

    store.items.push(item);

    // keep last N events (avoid LS overflow)
    if (store.items.length > 2000) store.items = store.items.slice(-2000);

    saveJsonLS(LS.events, store);

    // optional: mirror to Supabase app_events
    mirrorEventToSupabase(type, { ...payload, ts: new Date(ts).toISOString() });

    // realtime evaluation hooks
    evaluateRealtimeCredentials(item);

    return item;
  }

  function listEventsByType(types) {
    const st = eventsStore();
    const set = new Set(Array.isArray(types) ? types : [types]);
    return st.items.filter(e => set.has(e.type));
  }

  function getEventsInLastDays(days) {
    const st = eventsStore();
    const cutoff = Date.now() - Math.max(0, Number(days) || 0) * 24 * 60 * 60 * 1000;
    return st.items.filter(e => e.ts >= cutoff);
  }

  // ---------------------------
  // Credential evaluation
  // ---------------------------

  function evaluateConsistentLearnerDaily() {
    const c = credentialsStore();
    const todayDay = dayKeyTashkent(Date.now());

    // run once per “calendar day”
    if (c.last_daily_eval_day === todayDay) return c;

    const windowEvents = getEventsInLastDays(14);
    const activeTypes = new Set([
      "video_opened",
      "video_completed",
      "video_skipped",
      "practice_attempt_finished",
      "tour_attempt_finished",
      "resource_opened",
      "recommendation_opened"
    ]);

    const activeDays = new Set();
    windowEvents.forEach(e => {
      if (activeTypes.has(e.type)) activeDays.add(e.day);
    });

    const active_days_14d = activeDays.size;
    const exists_valid_14d_window = (active_days_14d >= 7);

    const hadEverActive = (c.consistent_learner.achieved_at != null) || (c.consistent_learner.status === "active");

    if (exists_valid_14d_window) {
      c.consistent_learner.status = "active";
      if (!c.consistent_learner.achieved_at) c.consistent_learner.achieved_at = Date.now();
      c.consistent_learner.degradation_counter_days = 0;
    } else {
      // buffer logic (no “instant death”)
      if (hadEverActive) {
        c.consistent_learner.degradation_counter_days = (Number(c.consistent_learner.degradation_counter_days) || 0) + 1;
        if (c.consistent_learner.degradation_counter_days >= 14) {
          c.consistent_learner.status = "inactive";
        } else {
          c.consistent_learner.status = "active"; // inside buffer
        }
      } else {
        // never earned: stays inactive until first valid window
        c.consistent_learner.status = "inactive";
        c.consistent_learner.degradation_counter_days = 0;
      }
    }

    c.consistent_learner.last_evaluated_at = Date.now();
    c.consistent_learner.evidence = {
      computed_at: Date.now(),
      window_start: Date.now() - 13 * 24 * 60 * 60 * 1000,
      window_end: Date.now(),
      active_days_14d,
      last_events: (c.consistent_learner.evidence?.last_events || []).slice(0, 5)
    };

    c.last_daily_eval_day = todayDay;
    saveCredentialsStore(c);
    return c;
  }

  function evaluateResearchOrientedDaily() {
    const c = credentialsStore();
    const ev = listEventsByType(["resource_opened", "recommendation_opened"]);
    const opens = ev.length;
    const days = new Set(ev.map(x => x.day));
    const distinct_return_days = days.size;

    const active = (opens >= 3 && distinct_return_days >= 2);

    const prev = c.research_oriented_learner.status;
    c.research_oriented_learner.status = active ? "active" : "inactive";
    if (active && !c.research_oriented_learner.achieved_at) c.research_oriented_learner.achieved_at = Date.now();
    c.research_oriented_learner.last_evaluated_at = Date.now();
    c.research_oriented_learner.evidence = {
      computed_at: Date.now(),
      resource_opens_total: opens,
      distinct_return_days,
      last_events: (c.research_oriented_learner.evidence?.last_events || []).slice(0, 5)
    };

    if (prev !== c.research_oriented_learner.status) saveCredentialsStore(c);
    else saveCredentialsStore(c);
    return c;
  }

  function median(arr) {
    const a = arr.slice().sort((x, y) => x - y);
    if (!a.length) return 0;
    const mid = Math.floor(a.length / 2);
    if (a.length % 2) return a[mid];
    return Math.round((a[mid - 1] + a[mid]) / 2);
  }

  function ensurePracticeSubjectBucket(c, subjectId) {
    const sid = String(subjectId || "");
    if (!sid) return null;
    if (!c.practice_mastery_subject.by_subject[sid]) {
      c.practice_mastery_subject.by_subject[sid] = {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, attempts_count: 0, best_percent: 0, median_percent: 0, last_events: [] },
        percents: []
      };
    }
    return c.practice_mastery_subject.by_subject[sid];
  }

  function evaluatePracticeMasteryRealtime(subjectId, percent, eventId) {
    const c = credentialsStore();
    const bucket = ensurePracticeSubjectBucket(c, subjectId);
    if (!bucket) return;

    const p = Math.max(0, Math.min(100, Number(percent) || 0));
    bucket.percents = Array.isArray(bucket.percents) ? bucket.percents : [];
    bucket.percents.push(p);

    // keep last 30 attempts for stats stability
    if (bucket.percents.length > 30) bucket.percents = bucket.percents.slice(-30);

    const attempts_count = bucket.percents.length;
    const best_percent = Math.max(...bucket.percents);
    const median_percent = median(bucket.percents);

    const active = (attempts_count >= 8 && best_percent >= 80 && median_percent >= 70);

    bucket.status = active ? "active" : bucket.status; // no loss (фиксируется на момент достижения)
    if (active && !bucket.achieved_at) bucket.achieved_at = Date.now();

    bucket.last_evaluated_at = Date.now();
    bucket.evidence = {
      computed_at: Date.now(),
      attempts_count,
      best_percent,
      median_percent,
      last_events: pushLastEvents(bucket.evidence?.last_events, eventId, 5)
    };

    saveCredentialsStore(c);
  }

  function evaluateActiveVideoLearnerRealtime(event) {
    const c = credentialsStore();
    const lessonId = event?.payload?.lesson_id ? String(event.payload.lesson_id) : "";
    if (!lessonId) return;

    const decided = c.active_video_learner.decided_by_lesson || {};
    const prev = decided[lessonId] || null;

    if (event.type === "video_skipped") {
      decided[lessonId] = { decided: true, completed: false };
    }
    if (event.type === "video_completed") {
      decided[lessonId] = { decided: true, completed: true };
    }

    c.active_video_learner.decided_by_lesson = decided;

    const all = Object.values(decided);
    const videos_decided = all.filter(x => x && x.decided).length;
    const videos_completed = all.filter(x => x && x.decided && x.completed).length;
    const completion_rate = videos_decided ? (videos_completed / videos_decided) : 0;

    const active = (videos_decided >= 10 && completion_rate >= 0.70);

    c.active_video_learner.status = active ? "active" : "inactive";
    if (active && !c.active_video_learner.achieved_at) c.active_video_learner.achieved_at = Date.now();

    c.active_video_learner.last_evaluated_at = Date.now();
    c.active_video_learner.evidence = {
      computed_at: Date.now(),
      videos_decided,
      videos_completed,
      completion_rate: Math.round(completion_rate * 1000) / 1000,
      last_events: pushLastEvents(c.active_video_learner.evidence?.last_events, event.id, 5)
    };

    saveCredentialsStore(c);
  }

  function evaluateFocusedStreakRealtime(event) {
    // valid sessions: video_completed / video_skipped / practice_attempt_finished / tour_attempt_finished
    // (video_skipped разрешён по документам проекта)
    if (!["video_completed", "video_skipped", "practice_attempt_finished", "tour_attempt_finished"].includes(event.type)) return;

    const c = credentialsStore();
    const subjectId = event?.payload?.subject_id ? String(event.payload.subject_id) : "";
    if (!subjectId) return;

    const ev = c.focused_study_streak.evidence || {};
    const current_subject_id = ev.current_subject_id ? String(ev.current_subject_id) : null;
    let counter = Number(ev.focused_sessions_in_row) || 0;

    if (current_subject_id && current_subject_id === subjectId) {
      counter += 1;
    } else {
      // subject switch kills streak + expires if was active
      if (c.focused_study_streak.status === "active") {
        c.focused_study_streak.status = "expired";
      } else if (c.focused_study_streak.status !== "expired") {
        // keep inactive/expired as-is, but we restart counter
      }
      counter = 1;
    }

    // earned
    if (counter >= 5) {
      c.focused_study_streak.status = "active";
      if (!c.focused_study_streak.achieved_at) c.focused_study_streak.achieved_at = Date.now();
    } else {
      // before earned: keep inactive; after earned: keep whatever (active/expired)
      if (!c.focused_study_streak.achieved_at && c.focused_study_streak.status !== "expired") {
        c.focused_study_streak.status = "inactive";
      }
    }

    c.focused_study_streak.last_evaluated_at = Date.now();
    c.focused_study_streak.evidence = {
      computed_at: Date.now(),
      current_subject_id: subjectId,
      focused_sessions_in_row: counter,
      last_events: pushLastEvents(ev.last_events, event.id, 5)
    };

    saveCredentialsStore(c);
  }

  function evaluateFairPlayRealtime(event) {
    const c = credentialsStore();

    if (event.type === "anti_cheat_event") {
      const severity = String(event?.payload?.severity || "").toLowerCase();
      if (severity === "critical") {
        c.fair_play_participant.status = "revoked";
        c.fair_play_participant.has_critical_violation = true;
        c.fair_play_participant.last_evaluated_at = Date.now();
        c.fair_play_participant.evidence = {
          computed_at: Date.now(),
          tours_participated: Number(c.fair_play_participant.tours_participated) || 0,
          has_critical_violation: true,
          last_events: pushLastEvents(c.fair_play_participant.evidence?.last_events, event.id, 5)
        };
        saveCredentialsStore(c);
      }
      return;
    }

    if (event.type === "tour_attempt_finished") {
      const isArchive = !!event?.payload?.is_archive;
      if (!isArchive) {
        c.fair_play_participant.tours_participated = (Number(c.fair_play_participant.tours_participated) || 0) + 1;
      }

      const tours_participated = Number(c.fair_play_participant.tours_participated) || 0;
      const has_critical_violation = !!c.fair_play_participant.has_critical_violation;

      if (has_critical_violation) {
        c.fair_play_participant.status = "revoked";
      } else if (tours_participated >= 1) {
        c.fair_play_participant.status = "active";
        if (!c.fair_play_participant.achieved_at) c.fair_play_participant.achieved_at = Date.now();
      } else {
        c.fair_play_participant.status = "inactive";
      }

      c.fair_play_participant.last_evaluated_at = Date.now();
      c.fair_play_participant.evidence = {
        computed_at: Date.now(),
        tours_participated,
        has_critical_violation,
        last_events: pushLastEvents(c.fair_play_participant.evidence?.last_events, event.id, 5)
      };

      saveCredentialsStore(c);
    }
  }

  function evaluateErrorDrivenDailyOrOnReview() {
    // Minimal implementation:
    // cycle = attempt A (has errors) -> review opened -> attempt B (fewer errors)
    // No time limits.
    const c = credentialsStore();

    // compute error_reduction from cycles only (simplified: each cycle has (a_errors, b_errors))
    // We store cycles_count in c.error_driven_learner.cycles_count and track reduction via last pair only for now.
    const cycles_count = Number(c.error_driven_learner.cycles_count) || 0;

    // If we have 3+ cycles we mark active, but requirement includes ≥30% reduction.
    // We approximate reduction using last captured baseline/current when present.
    const baseline = Number(c.error_driven_learner.evidence?.baseline_errors || 0) || 0;
    const current = Number(c.error_driven_learner.evidence?.current_errors || 0) || 0;
    const reduction = baseline > 0 ? ((baseline - current) / baseline) : 0;

    c.error_driven_learner.evidence = {
      ...(c.error_driven_learner.evidence || {}),
      computed_at: Date.now(),
      cycles_count,
      error_reduction: Math.max(0, Math.round(reduction * 1000) / 1000),
      last_events: (c.error_driven_learner.evidence?.last_events || []).slice(0, 5),
      baseline_errors: baseline,
      current_errors: current
    };

    if (cycles_count >= 3 && reduction >= 0.30) {
      c.error_driven_learner.status = "active";
      if (!c.error_driven_learner.achieved_at) c.error_driven_learner.achieved_at = Date.now();
    }

    c.error_driven_learner.last_evaluated_at = Date.now();
    saveCredentialsStore(c);
    return c;
  }

  function onPracticeReviewOpened(attemptKey, eventId) {
    const c = credentialsStore();
    const key = String(attemptKey || "");
    if (!key) return;
    c.error_driven_learner.reviewed_attempts = c.error_driven_learner.reviewed_attempts || {};
    c.error_driven_learner.reviewed_attempts[key] = { ts: Date.now() };
    c.error_driven_learner.evidence = {
      ...(c.error_driven_learner.evidence || {}),
      last_events: pushLastEvents(c.error_driven_learner.evidence?.last_events, eventId, 5)
    };
    saveCredentialsStore(c);
    evaluateErrorDrivenDailyOrOnReview();
  }

  function onPracticeAttemptFinishedForErrorDriven(subjectId, topicsErrorsMap, attemptKey, eventId) {
    // topicsErrorsMap: { [topic]: errorsCount }
    const c = credentialsStore();
    const sid = String(subjectId || "");
    if (!sid) return;

    c.error_driven_learner.last_attempt_a = c.error_driven_learner.last_attempt_a || {};
    c.error_driven_learner.reviewed_attempts = c.error_driven_learner.reviewed_attempts || {};

    Object.keys(topicsErrorsMap || {}).forEach(topic => {
      const key = `${sid}::${String(topic || "General")}`;
      const errors = Number(topicsErrorsMap[topic]) || 0;

      // If this attempt has errors, store as A baseline for that topic
      if (errors > 0) {
        c.error_driven_learner.last_attempt_a[key] = {
          attempt_key: String(attemptKey || ""),
          errors_count: errors,
          ts: Date.now(),
          subject_id: sid,
          topic: String(topic || "General")
        };
      } else {
        // errors == 0 can be “attempt B” candidate: check last A + review marker
        const prevA = c.error_driven_learner.last_attempt_a[key];
        if (!prevA || !prevA.attempt_key) return;

        const reviewed = c.error_driven_learner.reviewed_attempts[String(prevA.attempt_key || "")];
        if (!reviewed) return;

        const aErr = Number(prevA.errors_count) || 0;
        const bErr = errors;
        if (aErr <= 0) return;

        // “improvement” = bErr < aErr and reduction >= 30%
        const reduction = (aErr - bErr) / aErr;
        if (bErr < aErr && reduction >= 0.30) {
          c.error_driven_learner.cycles_count = (Number(c.error_driven_learner.cycles_count) || 0) + 1;

          c.error_driven_learner.evidence = {
            ...(c.error_driven_learner.evidence || {}),
            baseline_errors: aErr,
            current_errors: bErr,
            last_events: pushLastEvents(c.error_driven_learner.evidence?.last_events, eventId, 5)
          };

          // consume baseline so user cannot farm same A infinitely
          delete c.error_driven_learner.last_attempt_a[key];
        }
      }
    });

    saveCredentialsStore(c);
    evaluateErrorDrivenDailyOrOnReview();
  }

  function evaluateRealtimeCredentials(event) {
    // Consistent learner is daily; but we still want its evidence “last events”
    // We'll update evidence list opportunistically
    const c = credentialsStore();
    c.consistent_learner.evidence = c.consistent_learner.evidence || { last_events: [] };
    c.consistent_learner.evidence.last_events = pushLastEvents(c.consistent_learner.evidence.last_events, event.id, 5);
    saveCredentialsStore(c);

    // Focused streak: realtime
    evaluateFocusedStreakRealtime(event);

    // Active Video Learner: realtime on decided events
    if (event.type === "video_skipped" || event.type === "video_completed") {
      evaluateActiveVideoLearnerRealtime(event);
    }

    // Fair Play: realtime
    if (event.type === "tour_attempt_finished" || event.type === "anti_cheat_event") {
      evaluateFairPlayRealtime(event);
    }
  }

  function runDailyCredentialJobs() {
    evaluateConsistentLearnerDaily();
    evaluateResearchOrientedDaily();
    evaluateErrorDrivenDailyOrOnReview();
  }

  // =========================================================
  // End Earned Credentials Engine
  // =========================================================

  // ---------------------------
  // Telegram WebApp integration (safe)
  // ---------------------------

  // ---------------------------
  // Telegram WebApp integration (safe)
  // ---------------------------
  const tg = (window.Telegram && window.Telegram.WebApp) ? window.Telegram.WebApp : null;
  if (tg) {
    try {
      tg.ready();
      tg.expand();
    } catch {}
  }

  function getTelegramLang() {
    const code = tg?.initDataUnsafe?.user?.language_code;
    return window.i18n?.normalizeLang ? window.i18n.normalizeLang(code) : "ru";
  }

  function openExternal(url) {
    // Prefer Telegram openTelegramLink/openLink if available
    try {
      if (tg?.openTelegramLink && /^(https?:\/\/)?t\.me\//i.test(url)) {
        tg.openTelegramLink(url.replace(/^https?:\/\//i, ""));
        return;
      }
      if (tg?.openLink) {
        tg.openLink(url);
        return;
      }
    } catch {}
    window.open(url, "_blank", "noopener,noreferrer");
  }

  // ---------------------------
  // App state
  // ---------------------------
  const defaultState = {
  tab: "home", // home | courses | ratings | profile
  prevTab: "home",
  viewStack: ["home"], // global screens stack
  courses: {
    stack: ["all-subjects"],
    subjectKey: null,
    lessonId: null,
    entryTab: "home" 
  },
  profile: {
    stack: ["main"] // main | settings
  },
  quizLock: null
};

  let state = loadState();

  function loadState() {
    const saved = safeJsonParse(localStorage.getItem(LS.state), null);
    if (!saved) return structuredClone(defaultState);

    // soft merge
    const merged = {
      ...structuredClone(defaultState),
      ...saved,
      courses: { ...structuredClone(defaultState.courses), ...(saved.courses || {}) },
      profile: { ...structuredClone(defaultState.profile), ...(saved.profile || {}) }
    };
    // Ensure viewStack sane
    if (!Array.isArray(merged.viewStack) || merged.viewStack.length === 0) merged.viewStack = ["home"];
    if (!["home", "courses", "ratings", "profile"].includes(merged.tab)) merged.tab = "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.prevTab)) merged.prevTab = merged.tab || "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.courses.entryTab)) {
      merged.courses.entryTab = merged.prevTab || "home";
    }
     return merged;
  }

  function saveState() {
    localStorage.setItem(LS.state, JSON.stringify(state));
  }

  // ---------------------------
  // Profile (local demo)
  // later replace with Supabase
  // ---------------------------
  function loadProfile() {
    return safeJsonParse(localStorage.getItem(LS.profile), null);
  }
   function resetRegistrationSoft() {
  // 1) Очистка локального состояния
  localStorage.removeItem("profile");
  localStorage.removeItem("state");

  // если есть кастомные ключи — добавь сюда
  // localStorage.removeItem("user_subjects");

  // 2) Перезапуск в регистрацию
  showView("registration");
  bindRegistration();
}
   
  function saveProfile(profile) {
    localStorage.setItem(LS.profile, JSON.stringify(profile));
  }

   function togglePinnedSubject(profile, subjectKey) {
  if (!profile) return null;
  const p = structuredClone(profile);
  p.subjects = Array.isArray(p.subjects) ? p.subjects : [];

  const idx = p.subjects.findIndex(s => s.key === subjectKey);

  if (idx === -1) {
    // если предмет не был добавлен — добавляем как study+pinned
    p.subjects.push({ key: subjectKey, mode: "study", pinned: true });
    return p;
  }

  // уже есть — переключаем pinned
  p.subjects[idx].pinned = !p.subjects[idx].pinned;

  // Если выключили pinned и предмет был чисто учебным и "ничем не нужен" —
  // в v1 оставляем его (чтобы не терять режим/историю). Удаление сделаем позже, если потребуется.
  return p;
}

  // ---------------------------
  // Demo subjects (keys match index.html selects)
  // ---------------------------
  const SUBJECTS = [
    { key: "informatics", title: "Информатика", type: "main" },
    { key: "economics", title: "Экономика", type: "main" },
    { key: "biology", title: "Биология", type: "main" },
    { key: "chemistry", title: "Химия", type: "main" },
    { key: "mathematics", title: "Математика", type: "main" },

    { key: "english_a1", title: "English (A1)", type: "additional" },
    { key: "english_a2", title: "English (A2)", type: "additional" },
    { key: "english_b1", title: "English (B1)", type: "additional" },
    { key: "sat", title: "SAT", type: "additional" },
    { key: "ielts", title: "IELTS", type: "additional" }
  ];

  function subjectByKey(key) {
    return SUBJECTS.find(s => s.key === key) || null;
  }

     // ---------------------------
  // Availability rules (v1: local profile-based)
  // ---------------------------
  function isSchoolUser(profile) {
    return !!profile?.is_school_student;
  }

  function getUserSubject(profile, subjectKey) {
    return profile?.subjects?.find(s => s.key === subjectKey) || null;
  }

  function isMainSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "main";
  }

  function isAdditionalSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "additional";
  }

  function isCompetitiveForUser(profile, subjectKey) {
    return getUserSubject(profile, subjectKey)?.mode === "competitive";
  }

  // Tours eligibility (ACTIVE tours): school + main + competitive
  function canOpenActiveTours(profile, subjectKey) {
    if (!profile) return { ok: false, reason: "no_profile" };
    if (!isSchoolUser(profile)) return { ok: false, reason: "not_school" };
    if (!isMainSubjectKey(subjectKey)) return { ok: false, reason: "not_main" };
    if (!isCompetitiveForUser(profile, subjectKey)) return { ok: false, reason: "not_competitive" };
    return { ok: true, reason: "ok" };
  }

  function getToursDeniedText(reason) {
  if (reason === "not_main") return t("disabled_not_main") || "Туры доступны только для основных предметов.";
  if (reason === "not_school") return t("disabled_not_school") || "";
  if (reason === "not_competitive") return t("disabled_not_competitive") || "";
  return t("not_available") || "";
}

function toastToursDenied(reason) {
  const msg = getToursDeniedText(reason);
  showToast(msg || (t("tours_denied_title") || "Туры недоступны"));
}
     // ---------------------------
  // Tour schedule (v1: local stub, later from Supabase)
  // ---------------------------
  // Формат: YYYY-MM-DD (локальное время пользователя)
  const TOUR_SCHEDULE = [
    // Пример (позже заменим на реальные даты из базы/админки):
    // { subjectKey: "economics", tourNo: 1, start: "2026-02-01", end: "2026-02-07" },
  ];

  function parseLocalDateStart(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 0, 0, 0, 0).getTime();
  }

  function parseLocalDateEnd(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 23, 59, 59, 999).getTime();
  }

  function getActiveTourEntry(subjectKey) {
    const now = Date.now();
    const list = TOUR_SCHEDULE.filter(x => x.subjectKey === subjectKey);
    for (const e of list) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return e;
    }
    return null;
  }

  function hasAnyActiveTourNow() {
    const now = Date.now();
    for (const e of TOUR_SCHEDULE) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return true;
    }
    return false;
  }

  function canOpenArchiveNow() {
    // По правилам: архив открывается только когда активный тур завершён (то есть активных сейчас нет)
    return !hasAnyActiveTourNow();
  }

     // ---------------------------
  // Practice v1 (10Q: 3/5/2 + MCQ+INPUT + per-question timer + attempts history)
  // ---------------------------

  const PRACTICE_CONFIG = {
    total: 10,
    dist: { easy: 3, medium: 5, hard: 2 },
    // таймер по сложности (сек)
    timeByDifficulty: { easy: 45, medium: 60, hard: 90 },
    // максимум сохраняемых попыток
    keepLastAttempts: 5
  };

  // Мини-банк вопросов для практики (позже заменим на базу).
  // ВАЖНО: добавляй/расширяй — но структура должна быть стабильной.
  // type: "mcq" | "input"
  // inputKind: "numeric" | "letter"
  const PRACTICE_BANK = {
    economics: [
      {
        id: "eco_p_001",
        topic: "Basics",
        difficulty: "easy",
        type: "mcq",
        question: "Что такое альтернативная стоимость?",
        options: ["Стоимость производства", "Стоимость упущенной лучшей альтернативы", "Цена товара", "Налог на товар"],
        correctIndex: 1,
        explanation: "Альтернативная стоимость — ценность лучшей упущенной альтернативы при выборе."
      },
      {
        id: "eco_p_002",
        topic: "Elasticity",
        difficulty: "medium",
        type: "input",
        inputKind: "numeric",
        inputHint: "Введите число (например 1.5)",
        question: "Если %ΔQ = 10% и %ΔP = 5%, чему равна эластичность спроса по цене (по модулю)?",
        correctAnswer: "2",
        explanation: "Ed = |%ΔQ / %ΔP| = 10/5 = 2."
      },
      {
        id: "eco_p_003",
        topic: "Demand & Supply",
        difficulty: "hard",
        type: "input",
        inputKind: "letter",
        inputHint: "Введите 1 букву (не a/b/c/d)",
        question: "Какая буква обычно обозначает равновесную цену? (одна буква)",
        correctAnswer: "P",
        explanation: "Чаще всего цену обозначают P (price), равновесную — Pe."
      }
    ],
    mathematics: [
      {
        id: "math_p_001",
        topic: "Algebra",
        difficulty: "easy",
        type: "mcq",
        question: "Чему равно (x^2) * (x^3)?",
        options: ["x^5", "x^6", "x^9", "x^1"],
        correctIndex: 0,
        explanation: "При умножении степеней с одинаковым основанием показатели складываются: 2+3=5."
      },
      {
        id: "math_p_002",
        topic: "Functions",
        difficulty: "medium",
        type: "input",
        inputKind: "numeric",
        inputHint: "Введите число",
        question: "Если f(x)=2x+3, чему равно f(4)?",
        correctAnswer: "11",
        explanation: "2*4+3=11."
      }
    ],
    chemistry: [
      {
        id: "chem_p_001",
        topic: "Basics",
        difficulty: "easy",
        type: "mcq",
        question: "Какой заряд у протона?",
        options: ["-1", "0", "+1", "+2"],
        correctIndex: 2,
        explanation: "Протон имеет заряд +1."
      }
    ],
    biology: [
      {
        id: "bio_p_001",
        topic: "Cells",
        difficulty: "easy",
        type: "mcq",
        question: "Основная функция митохондрий?",
        options: ["Фотосинтез", "Синтез белка", "Производство АТФ", "Хранение ДНК"],
        correctIndex: 2,
        explanation: "Митохондрии — основной источник АТФ."
      }
    ],
    informatics: [
      {
        id: "inf_p_001",
        topic: "Algorithms",
        difficulty: "easy",
        type: "mcq",
        question: "Какой алгоритм обычно имеет сложность O(n log n)?",
        options: ["Binary search", "Merge sort", "Linear search", "Bubble sort (worst)"],
        correctIndex: 1,
        explanation: "Merge sort обычно O(n log n)."
      }
    ]
  };

// ---------------------------
// Reading map (v1 skeleton)
// Later we will fill from конкретных книг по предметам.
// Key idea: topic -> list of reading refs
// ---------------------------
const READING_MAP = {
  // economics: {
  //   "Unemployment": [
  //     { title: "AS Level Economics Coursebook", ref: "Ch 19", pages: "p. 210–225" }
  //   ]
  // }
};

function getReadingRefs(subjectKey, topic) {
  const s = READING_MAP?.[subjectKey] || null;
  if (!s) return [];
  const refs = s?.[topic] || [];
  return Array.isArray(refs) ? refs : [];
}
   
  function getPracticeBankForSubject(subjectKey) {
    return PRACTICE_BANK[subjectKey] || [];
  }

  function shuffle(arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function normalizeDifficulty(d) {
    const x = String(d || "").toLowerCase();
    if (x === "easy" || x === "medium" || x === "hard") return x;
    return "medium";
  }

function pickN(pool, n) {
  const s = shuffle(pool);
  return s.slice(0, Math.max(0, n));
}

// --- helpers: options parsing + answer normalization ---
function parseOptionsText(raw) {
  if (raw === null || raw === undefined) return null;
  if (Array.isArray(raw)) return raw.map(String);

  const s = String(raw).trim();
  if (!s) return null;

  // try JSON first
  try {
    const parsed = JSON.parse(s);
    if (Array.isArray(parsed)) return parsed.map(x => String(x));
  } catch {}

  // fallback: split lines / separators
  if (s.includes("\n")) return s.split("\n").map(x => x.trim()).filter(Boolean);
  if (s.includes("||")) return s.split("||").map(x => x.trim()).filter(Boolean);
  if (s.includes("|")) return s.split("|").map(x => x.trim()).filter(Boolean);

  return [s];
}

function isNumericLike(v) {
  const s = String(v ?? "").trim().replace(",", ".");
  return s !== "" && !Number.isNaN(Number(s));
}

// --- DB-first practice set builder ---
async function buildPracticeSet(subjectKey) {
  // If no Supabase — fallback to local bank (old behavior)
  if (!window.sb) return buildPracticeSetLocal(subjectKey);

  const uid = await getAuthUid();
  if (!uid) return buildPracticeSetLocal(subjectKey);

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: subjectKey });
    return buildPracticeSetLocal(subjectKey);
  }

  // Pull a pool of questions from DB for this subject
  // Берём запас, чтобы гарантировать 3/5/2 и добивки
  const { data, error } = await window.sb
    .from("questions")
    .select("id, topic, difficulty, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active")
    .eq("subject_id", subjectId)
    .eq("is_active", true)
    .limit(200);

  if (error) {
    await logDbErrorToEvents(uid, "practice_questions_select", error, { subject_id: subjectId, subject_key: subjectKey });
    return buildPracticeSetLocal(subjectKey);
  }

  const poolRaw = Array.isArray(data) ? data : [];
  if (!poolRaw.length) return buildPracticeSetLocal(subjectKey);

  const normalizeDiff = (d) => normalizeDifficulty(d || "easy");
  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  const pool = poolRaw.map(r => {
    const type = normalizeType(r.qtype);
    const opts = type === "mcq" ? (parseOptionsText(r.options_text) || []) : null;

    // correctIndex for MCQ:
    // support: "2" (index), "B" (A/B/C/D), or exact option text
    let correctIndex = 0;
    if (type === "mcq") {
      const ca = String(r.correct_answer ?? "").trim();
      const asInt = Number(ca);
      if (!Number.isNaN(asInt) && Number.isFinite(asInt)) {
        correctIndex = asInt;
      } else if (/^[A-D]$/i.test(ca)) {
        correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
      } else if (opts && opts.length) {
        const idx = opts.findIndex(x => String(x).trim().toLowerCase() === ca.toLowerCase());
        if (idx >= 0) correctIndex = idx;
      }
      if (!Number.isFinite(correctIndex) || correctIndex < 0) correctIndex = 0;
    }

    const correctAnswer = type === "input" ? String(r.correct_answer ?? "").trim() : "";

    return {
      id: Number(r.id),                // ✅ важно: numeric question_id
      topic: r.topic || "General",
      difficulty: normalizeDiff(r.difficulty),
      type,
      question: r.question_text || "",
      options: opts || [],
      correctIndex,
      correctAnswer,
      explanation: r.explanation || "",
      imageUrl: r.image_url || null,
      inputKind: type === "input" ? (isNumericLike(correctAnswer) ? "numeric" : "text") : null,
      inputHint: type === "input" ? (isNumericLike(correctAnswer) ? "Введите число" : "Введите ответ") : ""
    };
  }).filter(q => Number.isFinite(q.id));

  if (!pool.length) return buildPracticeSetLocal(subjectKey);

  // группируем по сложности
  const by = {
    easy: pool.filter(q => q.difficulty === "easy"),
    medium: pool.filter(q => q.difficulty === "medium"),
    hard: pool.filter(q => q.difficulty === "hard")
  };

  const set = [
    ...pickN(by.easy.length ? by.easy : pool, PRACTICE_CONFIG.dist.easy),
    ...pickN(by.medium.length ? by.medium : pool, PRACTICE_CONFIG.dist.medium),
    ...pickN(by.hard.length ? by.hard : pool, PRACTICE_CONFIG.dist.hard)
  ];

  // добивка до 10
  const need = PRACTICE_CONFIG.total - set.length;
  if (need > 0) {
    const used = new Set(set.map(x => x.id));
    const rest = pool.filter(x => !used.has(x.id));
    set.push(...pickN(rest.length ? rest : pool, need));
  }

  // “лесенка” сложности: easy -> medium -> hard
  const order = { easy: 1, medium: 2, hard: 3 };
  set.sort((a, b) => (order[a.difficulty] - order[b.difficulty]));

  return set.slice(0, PRACTICE_CONFIG.total);
}

// --- old local implementation (your previous buildPracticeSet) ---
// IMPORTANT: сюда вставь твой ПРЕДЫДУЩИЙ buildPracticeSet(...) целиком, только переименуй в buildPracticeSetLocal
function buildPracticeSetLocal(subjectKey) {
  const bank = getPracticeBankForSubject(subjectKey).map(q => ({ ...q, difficulty: normalizeDifficulty(q.difficulty) }));

  const by = {
    easy: bank.filter(q => q.difficulty === "easy"),
    medium: bank.filter(q => q.difficulty === "medium"),
    hard: bank.filter(q => q.difficulty === "hard")
  };

  if (bank.length === 0) {
    return Array.from({ length: PRACTICE_CONFIG.total }).map((_, i) => ({
      id: `fallback_${subjectKey}_${i + 1}`,
      topic: "General",
      difficulty: i < 3 ? "easy" : (i < 8 ? "medium" : "hard"),
      type: "mcq",
      question: `Вопрос ${i + 1} (demo)`,
      options: ["A", "B", "C", "D"],
      correctIndex: 0,
      explanation: "Демо-вопрос. Позже заменим на банк/базу."
    }));
  }

  const set = [
    ...pickN(by.easy.length ? by.easy : bank, PRACTICE_CONFIG.dist.easy),
    ...pickN(by.medium.length ? by.medium : bank, PRACTICE_CONFIG.dist.medium),
    ...pickN(by.hard.length ? by.hard : bank, PRACTICE_CONFIG.dist.hard)
  ];

  const need = PRACTICE_CONFIG.total - set.length;
  if (need > 0) {
    const used = new Set(set.map(x => x.id));
    const rest = bank.filter(x => !used.has(x.id));
    set.push(...pickN(rest.length ? rest : bank, need));
  }

  const order = { easy: 1, medium: 2, hard: 3 };
  set.sort((a, b) => (order[a.difficulty] - order[b.difficulty]));

  return set.slice(0, PRACTICE_CONFIG.total);
}

  function practiceStorageKey(subjectKey) {
    return `practice_history_v1:${subjectKey}`;
  }

  function loadPracticeHistory(subjectKey) {
    try {
      const raw = localStorage.getItem(practiceStorageKey(subjectKey));
      const parsed = raw ? JSON.parse(raw) : null;
      if (!parsed) return { best: null, last: [] };
      return {
        best: parsed.best || null,
        last: Array.isArray(parsed.last) ? parsed.last : []
      };
    } catch {
      return { best: null, last: [] };
    }
  }

  function savePracticeHistory(subjectKey, data) {
    try {
      localStorage.setItem(practiceStorageKey(subjectKey), JSON.stringify(data));
    } catch {}
  }

  function updatePracticeHistory(subjectKey, attempt) {
    const h = loadPracticeHistory(subjectKey);
    const last = [attempt, ...(h.last || [])].slice(0, PRACTICE_CONFIG.keepLastAttempts);

    let best = h.best;
    if (!best || (attempt.percent > best.percent) || (attempt.percent === best.percent && attempt.durationSec < best.durationSec)) {
      best = attempt;
    }

    savePracticeHistory(subjectKey, { best, last });
    return { best, last };
  }

  function formatDateTime(ts) {
    try {
      const d = new Date(ts);
      return d.toLocaleString();
    } catch {
      return "";
    }
  }

  function isValidInputAnswer(q, value) {
    const v = String(value ?? "").trim();
    if (!v) return false;

    if (q.inputKind === "numeric") {
      // допускаем число с точкой/запятой
      return /^-?\d+([.,]\d+)?$/.test(v);
    }

    if (q.inputKind === "letter") {
      // ровно 1 буква, запрещаем a/b/c/d (чтобы не путали с MCQ)
      if (!/^[A-Za-zА-Яа-я]$/.test(v)) return false;
      const low = v.toLowerCase();
      if (low === "a" || low === "b" || low === "c" || low === "d") return false;
      return true;
    }

    return true;
  }

   // ---------------------------
  // Regions / Districts
  // - Uses Supabase if available (regions/districts tables)
  // - Falls back to local demo map
  // ---------------------------
  const REGIONS = {
    "Tashkent": ["Chilonzor", "Yunusobod", "Mirzo Ulug‘bek", "Shaykhontohur", "Yakkasaroy"],
    "Samarkand": ["Samarkand city", "Urgut", "Kattakurgan", "Payariq"],
    "Fergana": ["Fergana city", "Margilan", "Kokand", "Quva"],
    "Andijan": ["Andijan city", "Asaka", "Shahrixon", "Xo‘jaobod"],
    "Bukhara": ["Bukhara city", "G‘ijduvon", "Kogon", "Vobkent"]
  };

  function fillSelectOptions(selectEl, options, placeholder) {
    if (!selectEl) return;

    selectEl.innerHTML = "";

    const ph = document.createElement("option");
    ph.value = "";
    ph.disabled = true;
    ph.selected = true;
    ph.textContent = placeholder;
    selectEl.appendChild(ph);

    options.forEach(v => {
      const o = document.createElement("option");
      o.value = String(v);
      o.textContent = String(v);
      selectEl.appendChild(o);
    });
  }

  function fillSelectOptionsKV(selectEl, options, placeholder) {
    // options: [{value, label}]
    if (!selectEl) return;

    selectEl.innerHTML = "";

    const ph = document.createElement("option");
    ph.value = "";
    ph.disabled = true;
    ph.selected = true;
    ph.textContent = placeholder;
    selectEl.appendChild(ph);

    options.forEach(it => {
      const o = document.createElement("option");
      o.value = String(it.value);
      o.textContent = String(it.label);
      selectEl.appendChild(o);
    });
  }

    function refreshRegionDistrictPlaceholders() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    // update placeholder texts (first option)
    if (regionEl.options?.length) {
      const opt0 = regionEl.options[0];
      if (opt0 && opt0.value === "") opt0.textContent = t("reg_select_region") || "Выберите регион…";
    }

    if (districtEl.options?.length) {
      const opt0 = districtEl.options[0];
      if (opt0 && opt0.value === "") {
        opt0.textContent = districtEl.disabled
          ? (t("reg_select_region_first") || "Сначала выберите регион…")
          : (t("reg_select_district") || "Выберите район…");
      }
    }
  }

  async function initRegionDistrictUI() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    // prevent double-binding
    if (regionEl.dataset.bound === "1") {
      refreshRegionDistrictPlaceholders();
      return;
    }
    regionEl.dataset.bound = "1";

    // initial state
    districtEl.disabled = true;
    regionEl.innerHTML = "";
    districtEl.innerHTML = "";

    // placeholders
    const regPh = document.createElement("option");
    regPh.value = "";
    regPh.disabled = true;
    regPh.selected = true;
    regPh.textContent = t("reg_select_region") || "Выберите регион…";
    regionEl.appendChild(regPh);

    const distPh = document.createElement("option");
    distPh.value = "";
    distPh.disabled = true;
    distPh.selected = true;
    distPh.textContent = t("reg_select_region_first") || "Сначала выберите регион…";
    districtEl.appendChild(distPh);

    // DB only
    if (!window.sb) {
      showToast("Supabase not ready");
      return;
    }

    const langCode = (window.i18n?.getLang ? window.i18n.getLang() : "ru");
    const nameField = langCode === "uz" ? "name_uz" : (langCode === "en" ? "name_en" : "name_ru");

    const { data: regions, error: rErr } = await window.sb
      .from("regions")
      .select(`id, name_ru, name_uz, name_en`)
      .order("name_ru", { ascending: true });

    if (rErr || !Array.isArray(regions) || regions.length === 0) {
      showToast("No regions in DB");
      return;
    }

    regions.forEach(r => {
      const o = document.createElement("option");
      o.value = String(r.id);
      o.textContent = String(r?.[nameField] || r?.name_ru || "").trim();
      regionEl.appendChild(o);
    });


    regionEl.addEventListener("change", async () => {
      const regionId = regionEl.value ? Number(regionEl.value) : null;

      districtEl.disabled = true;
      districtEl.innerHTML = "";

      const ph = document.createElement("option");
      ph.value = "";
      ph.disabled = true;
      ph.selected = true;
      ph.textContent = t("reg_loading_districts") || "Загрузка районов…";
      districtEl.appendChild(ph);

      if (!regionId) {
        refreshRegionDistrictPlaceholders();
        return;
      }

       const { data: dists, error: dErr } = await window.sb
        .from("districts")
        .select("id, region_id, name_ru, name_uz, name_en")
        .eq("region_id", regionId)
        .order("name_ru", { ascending: true });

      const rows = (!dErr && Array.isArray(dists)) ? dists : [];

      districtEl.innerHTML = "";
      const ph2 = document.createElement("option");
      ph2.value = "";
      ph2.disabled = true;
      ph2.selected = true;
      ph2.textContent = rows.length ? (t("reg_select_district") || "Выберите район…") : (t("reg_no_districts") || "Нет районов");
      districtEl.appendChild(ph2);

      if (!rows.length) {
        districtEl.disabled = true;
        return;
      }

      rows.forEach(d => {
        const o = document.createElement("option");
        o.value = String(d.id);
        o.textContent = String(d?.[nameField] || d?.name_ru || "").trim();
        districtEl.appendChild(o);
      });

      districtEl.disabled = false;
    });
  }

  // ---------------------------
  // UI: Views & Tabs
  // ---------------------------
  const VIEWS = [
    "splash",
    "registration",
    "home",
    "courses",
    "ratings",
    "profile",
    // Global screens
    "resources",
    "news",
    "notifications",
    "community",
    "about",
    "certificates",
    "archive"
  ];

  function showView(viewName) {
  VIEWS.forEach(v => {
    const el = $(`#view-${v}`);
    if (!el) return;
    el.classList.toggle("is-active", v === viewName);
  });

  updateTopbarForView(viewName);

  // ✅ FIX: не просто "вверх страницы", а "к началу активного view"
  const target = document.getElementById(`view-${viewName}`);
  if (!target) return;

  const jumpToTargetTop = () => {
    // 1) если скроллится main — сбрасываем его
    const mainEl = document.getElementById("main");
    if (mainEl) mainEl.scrollTop = 0;

    // 2) если скроллится документ — тоже сбрасываем
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;

    // 3) главное: принудительно ставим начало активного view в верх видимой области
    // (работает даже если браузер/вебвью "держит" странную позицию)
    try {
      target.scrollIntoView({ block: "start", inline: "nearest" });
    } catch (e) {
      // fallback
      target.scrollIntoView(true);
    }
  };

  // делаем несколько раз: сразу + после кадра + после 0ms,
  // потому что WebView иногда "переигрывает" скролл после рендера
  jumpToTargetTop();
  requestAnimationFrame(jumpToTargetTop);
  setTimeout(jumpToTargetTop, 0);
}

  function setTab(tabName) {
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    const prevTab = state.tab;
    if (prevTab && prevTab !== tabName) {
      state.prevTab = prevTab;
      if (tabName === "courses") state.courses.entryTab = prevTab;
    }
     state.tab = tabName;
    saveState();

    // Tabbar active
    $$(".tabbar .tab").forEach(btn => {
      btn.classList.toggle("is-active", btn.dataset.tab === tabName);
    });

    // Maintain global view stack: tab screen becomes "base"
    setGlobalBaseView(tabName);

    if (tabName === "courses") {
  renderCoursesStack();
}
if (tabName === "profile") {
  renderProfileStack();
}
if (tabName === "ratings") {
  // ✅ show loader immediately (before async boot/selects)
  try {
    const loadingEl = document.getElementById("ratings-loading");
    if (loadingEl) loadingEl.style.display = "flex";
  } catch {}

  renderRatings();
}
}

  function setGlobalBaseView(tabName) {
    // base view should be one of: home/courses/ratings/profile
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    state.viewStack = [tabName];
    saveState();
    showView(tabName);
  }

  function openGlobal(viewName) {
    // push to stack and show
    if (!VIEWS.includes(viewName)) return;

    // If user is in quiz lock, do not allow leaving
    if (state.quizLock === "tour") {
      showToast("Tour is in progress");
      return;
    }
    if (state.quizLock === "practice") {
      showToast("Pause practice to leave");
      return;
    }

    // base should exist
    if (!Array.isArray(state.viewStack) || state.viewStack.length === 0) {
      state.viewStack = [state.tab || "home"];
    }

       const top = state.viewStack[state.viewStack.length - 1];
    if (top === viewName) {

      // Earned Credentials: Research-Oriented — resource opened
      if (viewName === "resources") {
        try { trackEvent("resource_opened", { source: "global_resources" }); } catch {}
      }

      showView(viewName);
      return;
    }

        state.viewStack.push(viewName);
    saveState();

    // Earned Credentials: Research-Oriented — resource opened
    if (viewName === "resources") {
      try { trackEvent("resource_opened", { source: "global_resources" }); } catch {}
    }

    showView(viewName);
  }

  function canGlobalBack() {
    return Array.isArray(state.viewStack) && state.viewStack.length > 1;
  }

  function globalBack() {
    if (!canGlobalBack()) return;
    state.viewStack.pop();
    saveState();
    const top = state.viewStack[state.viewStack.length - 1];
    showView(top);
  }

  // ---------------------------
  // Topbar behavior
  // ---------------------------
  function updateTopbarForView(viewName) {
const topbarEl = $("#topbar");
const backBtn = $("#topbar-back");
const titleEl = $("#topbar-title");
const subEl = $("#topbar-subtitle");
const logoEl = $("#topbar-logo");
const notifBtn = $("#topbar-notifications");
const actionBtn = $("#topbar-action");

if (!backBtn || !titleEl || !subEl) return;

// ✅ Splash/Loading: topbar и tabbar не показываем вообще
const tabbarEl = $("#tabbar");

if (topbarEl) {
  if (viewName === "splash") {
    topbarEl.style.display = "none";
    if (tabbarEl) tabbarEl.style.display = "none";
    return;
  }
  topbarEl.style.display = ""; // вернуть дефолт (grid из CSS)
}

if (tabbarEl) tabbarEl.style.display = ""; // вернуть таббар после splash

// лого теперь не прячем
if (logoEl) logoEl.style.display = "block";

// notif по умолчанию скрыт (ВАЖНО: display, чтобы не резервировать место справа)
if (notifBtn) {
  notifBtn.style.display = "none";
  notifBtn.style.visibility = "hidden"; // ✅ важно: index.html имеет inline visibility:hidden
  notifBtn.dataset.action = "open-notifications";
}

// action по умолчанию скрыт (ВАЖНО: display, чтобы не резервировать место справа)
if (actionBtn) {
  actionBtn.style.display = "none";
  actionBtn.style.visibility = "hidden"; // ✅ index.html тоже имеет inline visibility:hidden
  actionBtn.dataset.action = "topbar-action";
  const icon = actionBtn.querySelector(".icon");
  if (icon) icon.textContent = "⋯";
}

    // Default
    titleEl.textContent = t("app_name");
    subEl.textContent = "Smarter together";
    backBtn.style.visibility = "hidden";

     // ✅ sync: если back скрыт — двигаем бренд на место кнопки (CSS .topbar.is-no-left уже есть)
   function syncTopbarLeftState() {
  if (!topbarEl || !backBtn) return;

  // ✅ 1) сначала снимаем "липкий" класс, чтобы back мог вернуться из display:none!important
  topbarEl.classList.remove("is-no-left");
  backBtn.style.display = ""; // вернём дефолтный display кнопки (inline-flex из CSS)

  // ✅ 2) решаем по ЯВНО установленному visibility (а не computedStyle, которое ломается из-за is-no-left)
  const shouldNoLeft = (backBtn.style.visibility === "hidden");

  topbarEl.classList.toggle("is-no-left", shouldNoLeft);
}

       if (viewName === "splash") {
     titleEl.textContent = t("app_name");
     syncTopbarLeftState();
     return;
   }

       if (viewName === "registration") {
  // ✅ Topbar как везде
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";

  // ✅ Back показываем: он закрывает апп (bindTopbar уже делает close на registration)
  backBtn.style.visibility = "visible";

  // ✅ На регистрации нижний таббар не показываем вообще
  if (tabbarEl) tabbarEl.style.display = "none";

  syncTopbarLeftState();
  return;
}

     // применяем для default-состояния
     syncTopbarLeftState();

    // Global screens (resources/news/...)
    if (["resources", "news", "notifications", "community", "about", "certificates", "archive"].includes(viewName)) {
  backBtn.style.visibility = canGlobalBack() ? "visible" : "hidden";

  // ✅ Рядом с лого всегда бренд как на Home/Profile
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";
  syncTopbarLeftState();
  return;
}

    if (viewName === "home") {
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";
  backBtn.style.visibility = "hidden";
  if (logoEl) logoEl.style.display = "block";

  if (notifBtn) {
  notifBtn.style.display = "inline-flex";
  notifBtn.style.visibility = "visible"; // ✅ иначе остаётся hidden из index.html
}

  syncTopbarLeftState();
  return;
}

    if (viewName === "ratings") {
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";
  backBtn.style.visibility = "hidden";
  syncTopbarLeftState();
  return;
}

    if (viewName === "profile") {
  const top = getProfileTopScreen();

  // В topbar всегда бренд
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";

  // Back показываем только в settings (и он будет работать через action="back")
  backBtn.style.visibility = (top === "settings") ? "visible" : "hidden";

  // Шестерёнка в topbar справа — только на главном экране профиля
  if (actionBtn) {
    if (top === "main") {
      actionBtn.style.display = "inline-flex";
      actionBtn.style.visibility = "visible";
      actionBtn.dataset.action = "profile-settings";
      const icon = actionBtn.querySelector(".icon");
      if (icon) icon.textContent = "⚙";
    } else {
      actionBtn.style.display = "none";
      actionBtn.style.visibility = "hidden";
    }
  }
   syncTopbarLeftState();
   return;
 }

       if (viewName === "courses") {
     const canGoBack = canCoursesBack();
     backBtn.style.visibility = (state.quizLock ? "hidden" : (canGoBack ? "visible" : "hidden"));

     // ✅ Рядом с лого всегда бренд как на Home/Profile
     titleEl.textContent = t("app_name");
     subEl.textContent = "Smarter together";
     syncTopbarLeftState();
     return;
   }
}

// ---------------------------
// Ratings (Leaderboard) — UI skeleton now, DB later
// ---------------------------
const ratingsState = {
  scope: "district", // district | region | republic
  q: "",
  subjectId: null,
  tourId: null, // null = All tours
  _booted: false,
  _loading: false,
  _token: 0
};

function getLeaderboardDataMock(scope) {
  // Позже заменим на Supabase: district/region/republic + subject/tour + competitive only
  const base = [
    { rank: 1, name: "Shakhzod Alimov", meta: "Tashkent International School", score: 980, time: "12:45", avatar: null },
    { rank: 2, name: "Nilufar Karimova", meta: "Presidential School", score: 975, time: "13:10", avatar: null },
    { rank: 3, name: "Jasur Akhmedov", meta: "Samarkand Lyceum #1", score: 962, time: "14:05", avatar: null },
    { rank: 4, name: "Bekzod Saitov", meta: "School 142, Tashkent", score: 958, time: "14:22", avatar: null },
    { rank: 5, name: "Madina Kenjayeva", meta: "Westminster Academy", score: 944, time: "15:10", avatar: null },
    { rank: 6, name: "Aziz Umarov", meta: "Bukhara State Lyceum", score: 940, time: "15:45", avatar: null },
    { rank: 7, name: "Lola Mansurova", meta: "School 50, Fergana", score: 938, time: "16:02", avatar: null }
  ];

  // Для ощущения “разных” вкладок — слегка двигаем очки
  const delta = (scope === "district") ? 0 : (scope === "region" ? -6 : -12);
  return base.map(x => ({ ...x, score: x.score + delta }));
}

function getMyRankMock(scope) {
  const p = loadProfile();
  const displayName = (p?.full_name || p?.name || "You").trim();
  const district = p?.district || "—";
  const region = p?.region || "—";
  const meta = [district, region].filter(Boolean).join(" • ");

  // Мок “моего” места и очков
  const rank = (scope === "district") ? 12 : (scope === "region" ? 28 : 64);
  const score = (scope === "district") ? 892 : (scope === "region" ? 861 : 820);
  const time = "18:30";

  return { rank, name: displayName, meta, score, time };
}

   function formatSecondsToMMSS(totalSeconds) {
  const s = Math.max(0, Number(totalSeconds) || 0);
  const mm = Math.floor(s / 60);
  const ss = s % 60;
  return `${String(mm).padStart(2,"0")}:${String(ss).padStart(2,"0")}`;
}

function getFullName(u) {
  const fn = (u?.first_name || "").trim();
  const ln = (u?.last_name || "").trim();
  const name = `${fn} ${ln}`.trim();
  return name || "—";
}

function buildUserMeta(u) {
  const parts = [];

  // class
  if (u?.class) {
    const c = String(u.class).trim();
    const suffix = t("class_suffix") || "";
    // если suffix задан — показываем "10 класс" / "10-sinf" / "10 grade"
    parts.push(suffix ? `${c} ${suffix}`.trim() : c);
  }

  // school
  if (u?.school) {
    let s = String(u.school).trim();
    if (s && !/^№/i.test(s)) s = `№${s}`;
    const sp = t("school_prefix") || "";
    parts.push(sp ? `${sp} ${s}`.trim() : s);
  }

  if (u?.district) parts.push(String(u.district).trim());
  if (u?.region) parts.push(String(u.region).trim());

  return parts.filter(Boolean).join(" • ");
}

function mapScopeToRankType(scope) {
  if (scope === "district") return "district";
  if (scope === "region") return "region";
  return "country"; // republic
}

async function getAuthUid() {
  try {
    if (!window.sb?.auth?.getUser) return null;
    const { data } = await window.sb.auth.getUser();
    return data?.user?.id || null;
  } catch {
    return null;
  }
}

// ✅ DB profile fetch (used by tours eligibility, etc.)
async function getUserProfile(uid) {
  try {
    // 1) local fallback (if your project has it)
    const lp = (typeof loadProfile === "function") ? loadProfile() : null;

    // if local profile exists and looks valid, return it immediately
    if (lp && typeof lp === "object") {
      // optional: if local profile has uid and matches, prefer it
      if (!lp.id || !uid || String(lp.id) === String(uid)) return lp;
    }

    // 2) DB fetch
    if (!window.sb || !uid) return lp || null;

    const { data, error } = await window.sb
      .from("users")
      .select("id, telegram_user_id, first_name, last_name, avatar_url, language_code, is_school_student, region, district, school, class, region_id, district_id")
      .eq("id", uid)
      .maybeSingle();

    if (error) return lp || null;
    return data || lp || null;
  } catch {
    return (typeof loadProfile === "function") ? (loadProfile() || null) : null;
  }
}

async function syncUserSubjectToSupabase(subjectKey, mode, isPinned) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    try { await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: subjectKey }); } catch {}
    return { ok: false, reason: "no_subject_id" };
  }

  const payload = {
  user_id: uid,
  subject_id: subjectId,
  mode: (mode === "competitive") ? "competitive" : "study",
  is_pinned: !!isPinned
};

// ✅ DB-guard: competitive subjects cannot be pinned (project rule)
if (payload.mode === "competitive" && payload.is_pinned) {
  payload.is_pinned = false;
}

  // 1) Prefer UPSERT (requires unique constraint on (user_id, subject_id))
  let { error } = await window.sb
    .from("user_subjects")
    .upsert(payload, { onConflict: "user_id,subject_id" });

  // 2) Fallback: UPDATE (if upsert fails for any reason)
  if (error) {
    const { error: updErr } = await window.sb
      .from("user_subjects")
      .update({ mode: payload.mode, is_pinned: payload.is_pinned })
      .eq("user_id", uid)
      .eq("subject_id", subjectId);

    if (!updErr) return { ok: true, uid, subjectId, method: "update" };

    try { await logDbErrorToEvents(uid, "user_subjects_save", updErr, { subject_id: subjectId, subject_key: subjectKey }); } catch {}
    return { ok: false, reason: "user_subjects_save_failed" };
  }

  return { ok: true, uid, subjectId, method: "upsert" };
}

// ---------------------------
// Stage B (DB-backed registration)
// - Save registration fields into public.users
// - Save selected subjects into public.user_subjects
// - Optional: hydrate local profile from DB if missing
// ---------------------------

function getTelegramUserSafe() {
  try {
    const tg = window.Telegram?.WebApp;
    return tg?.initDataUnsafe?.user || null;
  } catch {
    return null;
  }
}

async function saveRegistrationToSupabase(profile) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const tgUser = getTelegramUserSafe() || {};
  const avatar = tgUser?.photo_url || null;

   // 1) update users row
  const fullNameRaw = String(profile?.full_name || profile?.name || "").trim();
  const nameParts = fullNameRaw ? fullNameRaw.split(/\s+/).filter(Boolean) : [];
  const firstFromProfile = nameParts.length ? nameParts[0] : null;
  const lastFromProfile = (nameParts.length > 1) ? nameParts.slice(1).join(" ") : null;

  const usersPayload = {
    id: uid,
    telegram_user_id: (tgUser?.id != null) ? String(tgUser.id) : null,

    // ✅ если Telegram не дал first/last_name — берём из формы регистрации
    first_name: tgUser?.first_name || firstFromProfile || null,
    last_name: tgUser?.last_name || lastFromProfile || null,

    avatar_url: avatar,
    language_code: profile?.language || tgUser?.language_code || "ru",
    is_school_student: !!profile?.is_school_student,
    region: profile?.region || null,
    district: profile?.district || null,
    school: profile?.school || null,
    class: profile?.class || null
  };

  const { error: uErr } = await window.sb
    .from("users")
    .upsert(usersPayload, { onConflict: "id" });

  if (uErr) {
    try { trackEvent("registration_db_error", { where: "users_upsert", message: String(uErr?.message || uErr) }); } catch {}
    return { ok: false, reason: "users_upsert_failed" };
  }

    // 2) sync user_subjects rows
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const rowsRaw = [];

  for (const s of subjects) {
    const key = String(s?.key || "").trim();
    if (!key) continue;

    const subjectId = await getSubjectIdByKey(key);
    if (!subjectId) continue;

    const mode = (s?.mode === "competitive") ? "competitive" : "study";

    rowsRaw.push({
      user_id: uid,
      subject_id: subjectId,
      mode,
      // project rule: competitive subjects cannot be pinned
      is_pinned: (mode === "competitive") ? false : !!s?.pinned
    });
  }

  // ---- NORMALIZE rows: (1) de-duplicate by subject_id, (2) enforce competitive ≤ 2
  const dedupMap = new Map(); // subject_id -> row
  for (const r of rowsRaw) {
    if (!dedupMap.has(r.subject_id)) dedupMap.set(r.subject_id, r);
  }

  let rows = Array.from(dedupMap.values());

  // enforce competitive max 2 (downgrade extra to study, deterministic order)
  let compCount = 0;
  rows = rows.map(r => {
    if (r.mode === "competitive") {
      compCount += 1;
      if (compCount > 2) {
        return { ...r, mode: "study", is_pinned: !!r.is_pinned };
      }
    }
    return r;
  });

  if (rows.length) {
        // delete → insert (safe even without unique constraint)
    const { error: delErr } = await window.sb
      .from("user_subjects")
      .delete()
      .eq("user_id", uid);

    if (delErr) {
      try {
        trackEvent("registration_db_error", {
          where: "user_subjects_delete",
          message: String(delErr?.message || delErr)
        });
      } catch {}
      return { ok: false, reason: "user_subjects_delete_failed" };
    }

    const { error: insErr } = await window.sb
      .from("user_subjects")
      .insert(rows);

    if (insErr) {
      try {
        trackEvent("registration_db_error", {
          where: "user_subjects_insert",
          message: String(insErr?.message || insErr),
          rows_count: rows.length,
          comp_count: rows.filter(x => x.mode === "competitive").length
        });
      } catch {}
      return { ok: false, reason: "user_subjects_insert_failed" };
    }
  }

  // успех
  // after registration, force next profile open to re-sync from DB
  window.__profileDbSubjectsReady = false;

  return { ok: true, user_id: uid, user_subjects_rows: rows.length, subjects_saved: rows.length };
}

async function hydrateLocalProfileFromSupabaseIfMissing() {
  if (loadProfile()) return { ok: true, skipped: true, reason: "local_profile_exists" };
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const me = await getMyUserRow(uid);
  if (!me) return { ok: false, reason: "no_users_row" };

  // Load user_subjects with subject_key (FK relationship expected)
  let subjRows = [];
  try {
    const { data, error } = await window.sb
      .from("user_subjects")
      .select("mode,is_pinned, subjects(subject_key)")
      .eq("user_id", uid);

    if (!error && Array.isArray(data)) subjRows = data;
  } catch {}

  const subjects = subjRows
    .map(r => {
      const key = r?.subjects?.subject_key;
      if (!key) return null;
      return {
        key,
        mode: (r?.mode === "competitive") ? "competitive" : "study",
        pinned: !!r?.is_pinned
      };
    })
    .filter(Boolean);

  const fullName = [me.first_name, me.last_name].filter(Boolean).join(" ").trim();

  const profile = {
    created_at: nowISO(),
    full_name: fullName || "User",
    language: me.language_code || "ru",
    is_school_student: !!me.is_school_student,
    region: me.region || "",
    district: me.district || "",
    school: me.school || "",
    class: me.class || "",
    telegram: {
      id: null,
      username: null,
      first_name: me.first_name || null,
      last_name: me.last_name || null,
      photo_url: me.avatar_url || null
    },
    subjects
  };

  saveProfile(profile);
  return { ok: true, hydrated: true, subjects: subjects.length };
}

   async function syncUserSubjectsFromSupabaseIntoLocalProfile() {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  // Read user's subjects from DB (join subjects to get subject_key)
  const { data, error } = await window.sb
    .from("user_subjects")
    .select("subject_id, mode, is_pinned, subjects(subject_key)")
    .eq("user_id", uid);

  if (error) {
    try { await logDbErrorToEvents(uid, "user_subjects_select", error, {}); } catch {}
    return { ok: false, reason: "select_failed" };
  }

  const list = (Array.isArray(data) ? data : [])
    .map(r => ({
      key: r?.subjects?.subject_key || null,
      mode: r?.mode || "study",
      pinned: !!r?.is_pinned
    }))
    .filter(x => !!x.key);

  const profile = loadProfile();
  if (!profile) {
    // no local profile yet (registration may still be shown)
    return { ok: true, applied: false, count: list.length };
  }

  profile.subjects = list;
  saveProfile(profile);

  return { ok: true, applied: true, count: list.length };
}

// ---------------------------
// Practice → Supabase (DB-first)
// - Writes practice_attempts + practice_answers
// - On failure writes practice_db_error into app_events
// ---------------------------
const _subjectIdByKeyCache = new Map();

async function getSubjectIdByKey(subjectKey) {
  const key = String(subjectKey || "").trim();
  if (!key || !window.sb) return null;

  // IMPORTANT: if cache holds a real number, return it.
  // Do NOT cache null/undefined (it becomes a “poisoned cache”).
  if (_subjectIdByKeyCache.has(key)) {
    const cached = _subjectIdByKeyCache.get(key);
    if (cached !== null && cached !== undefined) return cached;
    // cached null → ignore and re-fetch
  }

  const { data, error } = await window.sb
    .from("subjects")
    .select("id,subject_key,is_active")
    .eq("subject_key", key)
    .maybeSingle();

  if (error) {
    // log the real reason (RLS / permissions / network)
    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "subject_lookup_select_error", error, { subject_key: key });
    } catch {}
    return null;
  }

  const id = data?.id ? Number(data.id) : null;

  // cache only when we have a real id
  if (id) _subjectIdByKeyCache.set(key, id);

  return id;
}

async function logDbErrorToEvents(uid, where, error, extraPayload = {}) {
  try {
    if (!window.sb || !uid) return;
    await window.sb.from("app_events").insert({
      user_id: uid,
      event_type: "practice_db_error",
      payload: {
        where: String(where || "unknown"),
        message: String(error?.message || error || "unknown"),
        code: error?.code || null,
        details: error?.details || null,
        hint: error?.hint || null,
        ...extraPayload
      }
    });
  } catch {}
}

   async function logUserSubjectHistory(row) {
  try {
    if (!window.sb) return { ok: false, reason: "no_sb" };

    const uid = row?.user_id || (await getAuthUid());
    if (!uid) return { ok: false, reason: "no_uid" };

    const payload = {
      user_id: uid,
      subject_id: Number(row?.subject_id),
      action: String(row?.action || "unknown"),
      from_mode: row?.from_mode ?? null,
      to_mode: row?.to_mode ?? null,
      from_pinned: (row?.from_pinned === undefined) ? null : !!row.from_pinned,
      to_pinned: (row?.to_pinned === undefined) ? null : !!row.to_pinned,
      source: row?.source ?? null,
      meta: row?.meta ?? null
    };

    const { error } = await window.sb.from("user_subjects_history").insert(payload);
    if (error) {
      // fallback: at least keep it in app_events
      try {
        await window.sb.from("app_events").insert({
          user_id: uid,
          event_type: "user_subjects_history_write_failed",
          payload: { message: String(error?.message || error), ...payload }
        });
      } catch {}
      return { ok: false, reason: "insert_failed" };
    }

    return { ok: true };
  } catch {
    return { ok: false, reason: "exception" };
  }
}

async function savePracticeAttemptToSupabase(attempt, quiz) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(quiz?.subjectKey);
  if (!subjectId) {
    await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: quiz?.subjectKey });
    return { ok: false, reason: "no_subject_id" };
  }

  // 1) insert attempt (WITHOUT .select() to avoid “select permission” pitfalls)
  const insertAttemptPayload = {
    user_id: uid,
    subject_id: subjectId,
    score: Number(attempt?.score) || 0,
    percent: Number(attempt?.percent) || 0,
    time_seconds: Number(attempt?.durationSec) || 0
  };

  const { error: insErr } = await window.sb
    .from("practice_attempts")
    .insert(insertAttemptPayload);

  if (insErr) {
    await logDbErrorToEvents(uid, "attempt_insert", insErr, { subject_id: subjectId });
    return { ok: false, reason: "attempt_insert_failed" };
  }

  // 2) fetch the just-inserted attempt id (latest for this user+subject)
  const { data: lastRow, error: selErr } = await window.sb
    .from("practice_attempts")
    .select("id,created_at")
    .eq("user_id", uid)
    .eq("subject_id", subjectId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (selErr || !lastRow?.id) {
    await logDbErrorToEvents(uid, "attempt_select_latest", selErr || { message: "no_attempt_row" }, { subject_id: subjectId });
    return { ok: false, reason: "attempt_select_failed" };
  }

  const attemptId = Number(lastRow.id);

  // 3) insert answers (best-effort)
  const details = Array.isArray(attempt?.details) ? attempt.details : [];
  const answers = Array.isArray(quiz?.answers) ? quiz.answers : [];

  const rows = details.map((d, i) => {
    const rawUA = answers[i];
    const userAnswer = (rawUA === null || rawUA === undefined) ? null : String(rawUA);

   return {
     attempt_id: attemptId,
     question_id: Number(d?.id),
     user_answer: userAnswer,
     is_correct: !!d?.isCorrect,
     time_spent: Math.max(0, Math.round(Number(d?.timeSpent) || 0))
   };
  }).filter(r => Number.isFinite(r.question_id));

  if (rows.length) {
    const { error: ansErr } = await window.sb
      .from("practice_answers")
      .insert(rows);

    if (ansErr) {
      await logDbErrorToEvents(uid, "answers_insert", ansErr, { attempt_id: attemptId, rows: rows.length });
      return { ok: false, reason: "answers_insert_failed", attemptId };
    }
  }

  return { ok: true, attemptId, subjectId };
}

   async function getPracticeDbMetricsBySubjectKey(subjectKey) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) return { ok: false, reason: "no_subject_id" };

  // Pull last 30 attempts to compute streak reliably
  const { data: rows, error } = await window.sb
    .from("practice_attempts")
    .select("percent,created_at")
    .eq("user_id", uid)
    .eq("subject_id", subjectId)
    .order("created_at", { ascending: false })
    .limit(30);

  if (error) {
    await logDbErrorToEvents(uid, "practice_metrics_select", error, { subject_id: subjectId });
    return { ok: false, reason: "select_failed", subjectId };
  }

  const attempts = Array.isArray(rows) ? rows : [];

  // Mastery: avg percent over last 10
  const last10 = attempts.slice(0, 10);
  const mastery = last10.length
    ? Math.round(last10.reduce((s, r) => s + (Number(r.percent) || 0), 0) / last10.length)
    : 0;

  // Focus streak: consecutive days with at least 1 attempt
  // Normalize to YYYY-MM-DD in UTC
  const days = [];
  for (const r of attempts) {
    const d = new Date(r.created_at);
    if (Number.isNaN(d.getTime())) continue;
    const y = d.getUTCFullYear();
    const m = String(d.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(d.getUTCDate()).padStart(2, "0");
    days.push(`${y}-${m}-${dd}`);
  }

  const uniqDays = Array.from(new Set(days)); // already in desc order due to attempts order
  let streak = 0;

  if (uniqDays.length) {
    // Compare day-by-day starting from most recent day
    const toDay = (s) => {
      const [y, m, d] = s.split("-").map(Number);
      return Date.UTC(y, m - 1, d) / 86400000;
    };

    let prev = toDay(uniqDays[0]);
    streak = 1;

    for (let i = 1; i < uniqDays.length; i++) {
      const cur = toDay(uniqDays[i]);
      if (prev - cur === 1) {
        streak += 1;
        prev = cur;
      } else {
        break;
      }
    }
  }

  return { ok: true, subjectId, mastery, streak };
}

async function getMyUserRow(uid) {
  if (!uid) return null;
  const { data, error } = await window.sb
    .from("users")
    .select("id,first_name,last_name,avatar_url,is_school_student,region,district,school,class")
    .eq("id", uid)
    .maybeSingle();
  if (error) return null;
  return data || null;
}

async function getMyCompetitiveSubjects(uid) {
  if (!uid) return [];
  const { data, error } = await window.sb
    .from("user_subjects")
    .select("subject_id,mode")
    .eq("user_id", uid)
    .eq("mode", "competitive");
  if (error) return [];
  return Array.isArray(data) ? data : [];
}

async function loadRatingsSubjectsForSelect() {
  // показываем все активные main subjects (competitive по смыслу)
  const { data, error } = await window.sb
    .from("subjects")
    .select("id,subject_key,title,type,is_active")
    .eq("is_active", true)
    .eq("type", "main")
    .order("title", { ascending: true });

  if (error) return [];
  return Array.isArray(data) ? data : [];
}

async function loadRatingsToursForSubject(subjectId) {
  if (!subjectId) return [];
  const { data, error } = await window.sb
    .from("tours")
    .select("id,tour_no,is_active,start_date,end_date")
    .eq("subject_id", subjectId)
    .order("tour_no", { ascending: true });

  if (error) return [];
  return Array.isArray(data) ? data : [];
}

function renderRatingsSelectOptions(selectEl, items, { placeholder = null } = {}) {
  if (!selectEl) return;
  selectEl.innerHTML = "";

  if (placeholder) {
    const opt = document.createElement("option");
    opt.value = "";
    opt.textContent = placeholder;
    selectEl.appendChild(opt);
  }

  items.forEach(it => {
    const opt = document.createElement("option");
    opt.value = String(it.value);
    opt.textContent = String(it.label);
    selectEl.appendChild(opt);
  });
}

async function ensureRatingsBoot() {
  if (ratingsState._booted) return;

  if (!window.sb) {
    // если Supabase ещё не поднялся — просто выйдем, UI покажет заглушку
    return;
  }

  const subjectSelect = document.getElementById("ratings-subject");
  const tourSelect = document.getElementById("ratings-tour");

  // 1) subjects
  const subjects = await loadRatingsSubjectsForSelect();
  const subjectItems = subjects.map(s => ({ value: s.id, label: s.title }));

  renderRatingsSelectOptions(subjectSelect, subjectItems, {
    placeholder: t("loading")
  });

  // 2) default subject:
  const uid = await getAuthUid();
  const myComp = await getMyCompetitiveSubjects(uid);

  // если участник — дефолт = его competitive предмет
  // если не участник — дефолт = первый из списка
  const defaultSubjectId = (myComp?.[0]?.subject_id) || (subjects?.[0]?.id) || null;
  ratingsState.subjectId = defaultSubjectId ? Number(defaultSubjectId) : null;

  // отрисуем subjects без placeholder
  renderRatingsSelectOptions(subjectSelect, subjectItems);
  if (ratingsState.subjectId && subjectSelect) subjectSelect.value = String(ratingsState.subjectId);

  // 3) tours for subject
  const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
  const tourItems = [
    { value: "__all__", label: t("ratings_all_tours") || "All tours" },
    ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}` }))
  ];
  renderRatingsSelectOptions(tourSelect, tourItems);

  // default = All tours
  ratingsState.tourId = null;
  if (tourSelect) tourSelect.value = "__all__";

  ratingsState._booted = true;
}

 async function renderRatings() {
  const listEl = $("#ratings-list");
  const loadingEl = $("#ratings-loading");

  const mybar = $("#ratings-mybar");
  const myRankEl = $("#ratings-mybar-rank");
  const myTotalEl = $("#ratings-mybar-total");
  const myScoreEl = $("#ratings-mybar-score");
  const myTimeEl = $("#ratings-mybar-time");
  const hintEl = $("#ratings-viewer-hint");

  if (!listEl) return;

  const q = String(ratingsState.q || "").trim().toLowerCase();

  const showLoading = () => { if (loadingEl) loadingEl.style.display = "flex"; };
  const hideLoading = () => { if (loadingEl) loadingEl.style.display = "none"; };

  // total participants (used for "out of N")
  let totalN = 0;

  const renderRowHTML = (row) => {

    const topClass =
      row.rank === 1 ? "is-top1" :
      (row.rank === 2 ? "is-top2" :
      (row.rank === 3 ? "is-top3" : ""));

        return `
      <div class="lb-row" style="display:grid;grid-template-columns:56px 1fr 64px 64px;gap:10px;align-items:center;">
        <div class="lb-rank" style="display:flex;justify-content:center;">
          <div class="lb-rank-badge ${topClass}">${row.rank}</div>
        </div>

        <div class="lb-student" style="min-width:0;">
          <div class="lb-student-text" style="min-width:0;">
            <div class="lb-name" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
              ${escapeHTML(row.name)}
            </div>
            <div class="lb-meta" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
              ${escapeHTML(row.meta || "")}
            </div>
          </div>
        </div>

        <div class="lb-score" style="text-align:right;font-variant-numeric:tabular-nums;">
          ${row.score}
        </div>
        <div class="lb-time" style="text-align:right;font-variant-numeric:tabular-nums;">
          ${escapeHTML(row.time)}
        </div>
      </div>
    `;
  };

  const renderSection = (title, rows, subText) => {
    if (!rows || !rows.length) return "";
    const sub = subText ? `<div class="lb-section-sub">${escapeHTML(subText)}</div>` : `<div class="lb-section-sub"></div>`;
    return `
      <div class="lb-section">
        <div class="lb-section-head">
          <div class="lb-section-title">${escapeHTML(title)}</div>
          ${sub}
        </div>
        ${rows.map(renderRowHTML).join("")}
      </div>
    `;
  };

  const dedupeByRank = (rows) => {
    const out = [];
    const seen = new Set();
    for (const r of rows || []) {
      const k = String(r.rank);
      if (!k || seen.has(k)) continue;
      seen.add(k);
      out.push(r);
    }
    return out;
  };

  // сегменты
  $$(".lb-segment .seg-btn").forEach(btn => {
    const active = btn.dataset.scope === ratingsState.scope;
    btn.classList.toggle("is-active", active);
    btn.setAttribute("aria-selected", active ? "true" : "false");
  });

  // если Supabase ещё не готов
  if (!window.sb) {
    listEl.innerHTML = `<div class="empty muted">${t("loading")}</div>`;
    if (mybar) mybar.style.display = "none";
    if (hintEl) hintEl.style.display = "none";
    hideLoading();
    return;
  }

  const token = ++ratingsState._token;

  // boot selects (once)
  await ensureRatingsBoot();

  // loading UI
  listEl.innerHTML = "";
  showLoading();
  if (mybar) mybar.style.display = "none";

  // user / participant
  const uid = await getAuthUid();
  const me = await getMyUserRow(uid);
  const myComp = await getMyCompetitiveSubjects(uid);
  const isParticipant = !!me?.is_school_student && (myComp?.length > 0);

  // hint
  if (hintEl) hintEl.style.display = isParticipant ? "none" : "block";

  // если у меня нет district/region — принудительно republic, иначе фильтры бессмысленны
  if ((ratingsState.scope === "district" && !me?.district) || (ratingsState.scope === "region" && !me?.region)) {
    ratingsState.scope = "republic";
    $$(".lb-segment .seg-btn").forEach(btn => {
      const active = btn.dataset.scope === ratingsState.scope;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-selected", active ? "true" : "false");
    });
  }

  // guards
  if (!ratingsState.subjectId) {
    hideLoading();
    listEl.innerHTML = `<div class="empty muted">No subjects.</div>`;
    return;
  }

  const scopeRankType = mapScopeToRankType(ratingsState.scope);

  // =========================
  // A) конкретный тур: ratings_cache
  // =========================
  if (ratingsState.tourId) {
    const tourId = Number(ratingsState.tourId);

    // 1) my row (for around + mybar)
    let myRow = null;
    if (isParticipant && uid) {
      const mr = await window.sb
        .from("ratings_cache")
        .select("rank_no,score,total_time")
        .eq("tour_id", tourId)
        .eq("rank_type", scopeRankType)
        .eq("user_id", uid)
        .maybeSingle();
      if (!mr?.error) myRow = mr?.data || null;
    }

    // 2) top 50
    const topRes = await window.sb
      .from("ratings_cache")
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .lte("rank_no", 10)
      .order("rank_no", { ascending: true });

         // total participants (max rank_no) for "out of N"
    const totalRes = await window.sb
      .from("ratings_cache")
      .select("rank_no")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .order("rank_no", { ascending: false })
      .limit(1);

    if (token !== ratingsState._token) return;

    if (topRes?.error) {
      hideLoading();
      listEl.innerHTML = `<div class="empty muted">Ошибка загрузки рейтинга.</div>`;
      return;
    }

    // 3) around me ±10
    let aroundData = [];
    if (isParticipant && myRow?.rank_no) {
      const myRank = Number(myRow.rank_no || 0);
      const lo = Math.max(1, myRank - 2);
      const hi = myRank + 2;

      const aroundRes = await window.sb
        .from("ratings_cache")
        .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
        .eq("tour_id", tourId)
        .eq("rank_type", scopeRankType)
        .gte("rank_no", lo)
        .lte("rank_no", hi)
        .order("rank_no", { ascending: true });

      if (token !== ratingsState._token) return;
      if (!aroundRes?.error && Array.isArray(aroundRes?.data)) aroundData = aroundRes.data;
    }

    // 4) bottom 20 (optional)
    let bottomData = [];
    const bottomRes = await window.sb
      .from("ratings_cache")
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .order("rank_no", { ascending: false })
      .limit(3);

    if (token !== ratingsState._token) return;
    if (!bottomRes?.error && Array.isArray(bottomRes?.data)) bottomData = bottomRes.data.slice().reverse();

    const mapDbToRow = (r) => {
      const u = r.users || {};
      return {
        rank: Number(r.rank_no || 0),
        name: getFullName(u),
        meta: buildUserMeta(u),
        score: Number(r.score || 0),
        total_time: Number(r.total_time || 0),
        time: formatSecondsToMMSS(r.total_time),
                // avatar removed from ratings UI
        user_id: r.user_id
      };
    };

    let topRows = (topRes.data || []).map(mapDbToRow);
    let aroundRows = (aroundData || []).map(mapDbToRow);
    let bottomRows = (bottomData || []).map(mapDbToRow);

        totalN = (totalRes?.data && totalRes.data.length) ? Number(totalRes.data[0].rank_no || 0) : 0;
         
     // Fallback: if cache is empty, compute leaderboard from tour_attempts for this tour
    const cacheEmpty = !topRows.length && !aroundRows.length && !bottomRows.length;

    if (cacheEmpty) {
      const { data: attData, error: attErr } = await window.sb
        .from("tour_attempts")
        .select("user_id,score,total_time,status,tour_id,users(first_name,last_name,school,class,region,district)")
        .eq("tour_id", tourId)
        .in("status", ["submitted", "time_expired"])
        .limit(5000);

      if (attErr) {
        listEl.innerHTML = `<div class="empty muted">Ошибка загрузки рейтинга.</div>`;
        hideLoading();
        return;
      }

      // scope filter by my profile (district/region)
      const scoped = (Array.isArray(attData) ? attData : []).filter(a => {
        const u = a.users || {};
        if (ratingsState.scope === "district") return !!me?.district && String(u.district || "") === String(me.district || "");
        if (ratingsState.scope === "region") return !!me?.region && String(u.region || "") === String(me.region || "");
        return true;
      });

      let rows = scoped.map(a => {
        const u = a.users || {};
        return {
          user_id: a.user_id,
          score: Number(a.score || 0),
          total_time: Number(a.total_time || 0),
          name: getFullName(u),
          meta: buildUserMeta(u),
          time: formatSecondsToMMSS(Number(a.total_time || 0))
        };
      });

      // search by name + meta
      if (q) {
        rows = rows.filter(x => {
          const blob = `${x.name || ""} ${x.meta || ""}`.toLowerCase();
          return blob.includes(q);
        });
      }

      // rank
      rows.sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        return a.total_time - b.total_time;
      });
      rows = rows.map((r, idx) => ({ ...r, rank: idx + 1 }));

      // sections: top10 / around±2 / bottom3 (no duplicates)
      let topRows2 = rows.slice(0, 10);
      let aroundRows2 = [];
      let bottomRows2 = rows.length > 13 ? rows.slice(-3) : [];

      if (isParticipant && uid) {
        const myIndex = rows.findIndex(r => String(r.user_id) === String(uid));
        if (myIndex >= 0) {
          const lo = Math.max(0, myIndex - 2);
          const hi = Math.min(rows.length, myIndex + 3);
          aroundRows2 = rows.slice(lo, hi);
        }
      }

      const topRanks = new Set(dedupeByRank(topRows2).map(r => String(r.rank)));
      aroundRows2 = (aroundRows2 || []).filter(r => !topRanks.has(String(r.rank)));

      const aroundRanks = new Set(dedupeByRank(aroundRows2).map(r => String(r.rank)));
      bottomRows2 = (bottomRows2 || []).filter(r => !topRanks.has(String(r.rank)) && !aroundRanks.has(String(r.rank)));

      const shouldShowBottom2 = bottomRows2.length && bottomRows2.some(r => r.rank > 10);

      listEl.innerHTML =
        renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows2), "") +
        (isParticipant ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows2), "±2") : "") +
        (shouldShowBottom2 ? renderSection(t("ratings_bottom") || "Bottom 3", dedupeByRank(bottomRows2), "") : "");

      // My rank: out of N
      if (isParticipant && mybar) {
        const myIndex2 = rows.findIndex(r => String(r.user_id) === String(uid));
        if (myIndex2 >= 0) {
          const mine = rows[myIndex2];
          myRankEl.textContent = String(mine.rank);
          const outOf = t("ratings_out_of") || "out of";
          if (myTotalEl) myTotalEl.textContent = `${outOf} ${rows.length}`;
          myScoreEl.textContent = `${String(mine.score)} pts`;
          myTimeEl.textContent = formatSecondsToMMSS(mine.total_time);
          mybar.style.display = "flex";
        } else {
          mybar.style.display = "none";
        }
      }

      hideLoading();
      return;
    }

         // remove duplicates across sections (Top -> Around -> Bottom)
    const topRanks = new Set(dedupeByRank(topRows).map(r => String(r.rank)));
    aroundRows = (aroundRows || []).filter(r => !topRanks.has(String(r.rank)));

    const aroundRanks = new Set(dedupeByRank(aroundRows).map(r => String(r.rank)));
    bottomRows = (bottomRows || []).filter(r => !topRanks.has(String(r.rank)) && !aroundRanks.has(String(r.rank)));

    // search inside
    if (q) {
      const f = (arr) => arr.filter(x =>
        String(x.name || "").toLowerCase().includes(q) ||
        String(x.meta || "").toLowerCase().includes(q)
      );
      topRows = f(topRows);
      aroundRows = f(aroundRows);
      bottomRows = f(bottomRows);
    }

    // bottom show only if ranks exceed top zone
    const shouldShowBottom = bottomRows.length && bottomRows.some(r => r.rank > 10);

    hideLoading();

    if (!topRows.length && !aroundRows.length && !bottomRows.length) {
      listEl.innerHTML = `<div class="empty muted">Ничего не найдено.</div>`;
    } else {
            listEl.innerHTML =
        renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows), "") +
        (isParticipant && myRow?.rank_no ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows), "±2") : "") +
        (shouldShowBottom ? renderSection(
  t("ratings_bottom") || "Bottom 3",
  dedupeByRank(bottomRows),
  totalN ? `${t("ratings_out_of") || "out of"} ${totalN}` : ""
) : "");
    }

        // mybar
    if (isParticipant && mybar && myRow) {
      myRankEl.textContent = String(myRow.rank_no ?? "—");

      const outOf = t("ratings_out_of") || "out of";
      // total участников в rating_cache проще всего взять по максимальному рангу из bottomData (если он есть)
      const totalN = (bottomData && bottomData.length)
        ? Number(bottomData[bottomData.length - 1].rank_no || 0)
        : 0;
      if (myTotalEl) myTotalEl.textContent = totalN ? `${outOf} ${totalN}` : "—";

      myScoreEl.textContent = `${String(myRow.score ?? "—")} pts`;
      myTimeEl.textContent = formatSecondsToMMSS(myRow.total_time);
      mybar.style.display = "flex";
    } else {
      if (mybar) mybar.style.display = "none";
    }

    return;
  }

  // =========================
  // B) All tours: tour_attempts aggregation
  // =========================
  const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
  const tourIds = tours.map(x => x.id).filter(Boolean);

  if (!tourIds.length) {
    hideLoading();
    listEl.innerHTML = `<div class="empty muted">Нет туров для этого предмета.</div>`;
    return;
  }

  const { data: attempts, error: attErr } = await window.sb
    .from("tour_attempts")
    .select("user_id,score,total_time,status,tour_id,users(first_name,last_name,school,class,region,district)")
    .in("tour_id", tourIds)
    .in("status", ["submitted", "time_expired"])
    .limit(5000);

  if (token !== ratingsState._token) return;

  if (attErr) {
    hideLoading();
    listEl.innerHTML = `<div class="empty muted">Ошибка загрузки рейтинга.</div>`;
    return;
  }

  // filter by scope using my profile (district/region)
  const filteredAttempts = (Array.isArray(attempts) ? attempts : []).filter(a => {
    const u = a.users || {};
    if (ratingsState.scope === "district") return !!me?.district && String(u.district || "") === String(me.district || "");
    if (ratingsState.scope === "region") return !!me?.region && String(u.region || "") === String(me.region || "");
    return true; // republic
  });

  // aggregate per user
  const agg = new Map();
  for (const a of filteredAttempts) {
    const u = a.users || {};
    const id = a.user_id;
    if (!id) continue;
    const prev = agg.get(id) || { user_id: id, score: 0, total_time: 0, users: u };
    prev.score += Number(a.score || 0);
    prev.total_time += Number(a.total_time || 0);
    prev.users = u;
    agg.set(id, prev);
  }

  let rowsAll = Array.from(agg.values()).map(r => {
    const u = r.users || {};
    return {
      user_id: r.user_id,
      name: getFullName(u),
      meta: buildUserMeta(u),
      score: Number(r.score || 0),
      total_time: Number(r.total_time || 0),
      time: formatSecondsToMMSS(r.total_time),
      avatar: u.avatar_url || null
    };
  });

  // search
  if (q) {
    rowsAll = rowsAll.filter(x =>
      String(x.name || "").toLowerCase().includes(q) ||
      String(x.meta || "").toLowerCase().includes(q)
    );
  }

  // sort + rank
  rowsAll.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.total_time - b.total_time;
  });
    rowsAll = rowsAll.map((r, idx) => ({ ...r, rank: idx + 1 }));

  // total participants for this view
  totalN = rowsAll.length;

  hideLoading();

  if (!rowsAll.length) {
    listEl.innerHTML = `<div class="empty muted">${q ? "Ничего не найдено." : "Нет участников."}</div>`;
    if (mybar) mybar.style.display = "none";
    return;
  }

  // sections
  if (q) {
    const view = rowsAll.slice(0, 200);
    listEl.innerHTML = renderSection("Results", view, `${view.length}`);
  } else {
    const topRows = rowsAll.slice(0, 10);

    let aroundRows = [];
    let myIndex = -1;
    if (isParticipant && uid) myIndex = rowsAll.findIndex(r => String(r.user_id) === String(uid));
    if (isParticipant && myIndex >= 0) {
      const lo = Math.max(0, myIndex - 2);
      const hi = Math.min(rowsAll.length, myIndex + 3);
      aroundRows = rowsAll.slice(lo, hi);
    }

    const bottomRows = rowsAll.length > 13 ? rowsAll.slice(-3) : [];
    const shouldShowBottom = bottomRows.length && bottomRows.some(r => r.rank > 10);
    const topRanks = new Set(dedupeByRank(topRows).map(r => String(r.rank)));
    aroundRows = (aroundRows || []).filter(r => !topRanks.has(String(r.rank)));

    const aroundRanks = new Set(dedupeByRank(aroundRows).map(r => String(r.rank)));
    const bottomClean = (bottomRows || []).filter(r => !topRanks.has(String(r.rank)) && !aroundRanks.has(String(r.rank)));
  
        listEl.innerHTML =
      renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows), "") +
      (isParticipant && myIndex >= 0 ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows), "±2") : "") +
      (shouldShowBottom ? renderSection(
        t("ratings_bottom") || "Bottom 3",
        dedupeByRank(bottomClean),
        totalN ? `${t("ratings_out_of") || "out of"} ${totalN}` : ""
         ) : "");
     }

    // My rank (only if participant)
  if (isParticipant && mybar) {
    const myIndex = rowsAll.findIndex(r => String(r.user_id) === String(uid));
    if (myIndex >= 0) {
      const mine = rowsAll[myIndex];
      myRankEl.textContent = String(mine.rank);

      const outOf = t("ratings_out_of") || "out of";
      if (myTotalEl) myTotalEl.textContent = totalN ? `${outOf} ${totalN}` : "—";

      myScoreEl.textContent = `${String(mine.score)} pts`;
      myTimeEl.textContent = formatSecondsToMMSS(mine.total_time);
      mybar.style.display = "flex";
    } else {
      mybar.style.display = "none";
    }
  } else {
    if (mybar) mybar.style.display = "none";
  }
}

   function openRatingsSearchModal() {
  const title = t("ratings_search_title") || "Search";
  const label = t("ratings_search_label") || "Name / School / Class";
  const hint = t("ratings_search_hint") || "Type any part of a name, school or class.";
  const btnReset = t("btn_reset") || "Reset";
  const btnApply = t("btn_apply") || "Apply";

  const current = String(ratingsState.q || "");

  const html = `
    <div class="modal-backdrop" data-modal-backdrop data-close="backdrop">
      <div class="modal">
        <div class="modal-title">${escapeHTML(title)}</div>

        <div class="modal-text" style="text-align:left">
          <div style="font-weight:900; margin-bottom:6px;">${escapeHTML(label)}</div>
          <input id="ratings-search-input" type="search" value="${escapeHTML(current)}"
            style="width:100%; border:1px solid rgba(15,23,42,.12); border-radius:14px; padding:12px 12px; font-weight:900; outline:none;" />
          <div style="margin-top:8px; font-size:12px; font-weight:800; color:rgba(15,23,42,.55);">
            ${escapeHTML(hint)}
          </div>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn" data-modal-action="reset">${escapeHTML(btnReset)}</button>
          <button type="button" class="btn primary" data-modal-action="apply">${escapeHTML(btnApply)}</button>
        </div>
      </div>
    </div>
  `;

  openModal(html);

  const input = document.getElementById("ratings-search-input");
  if (input) setTimeout(() => input.focus(), 50);

  const root = document.getElementById("modal-root");
  if (!root) return;

  root.querySelectorAll("[data-modal-action]").forEach(btn => {
    btn.addEventListener("click", () => {
      const act = btn.dataset.modalAction;

      if (act === "reset") {
        ratingsState.q = "";
        closeModal(true);
        renderRatings();
        return;
      }

      if (act === "apply") {
        const v = (input ? input.value : "");
        ratingsState.q = String(v || "").trim();
        closeModal(true);
        renderRatings();
        return;
      }

      closeModal(false);
    });
  });
}

function bindRatingsUI() {
  const listEl = $("#ratings-list");
  const subjectSelect = $("#ratings-subject");
  const tourSelect = $("#ratings-tour");

  if (subjectSelect) {
    subjectSelect.addEventListener("change", async () => {
      const v = subjectSelect.value;
      ratingsState.subjectId = v ? Number(v) : null;

      // tours reload
      if (window.sb && ratingsState.subjectId) {
        const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
        const tourItems = [
          { value: "__all__", label: t("ratings_all_tours") || "All tours" },
          ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}` }))
        ];
        renderRatingsSelectOptions(tourSelect, tourItems);
        if (tourSelect) tourSelect.value = "__all__";
        ratingsState.tourId = null;
      }

      renderRatings();
    });
  }

  if (tourSelect) {
    tourSelect.addEventListener("change", () => {
      const v = tourSelect.value;
      ratingsState.tourId = (v && v !== "__all__") ? Number(v) : null;
      renderRatings();
    });
  }

  // segmented tabs
  $$(".lb-segment .seg-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const scope = btn.dataset.scope;
      if (!scope) return;
      ratingsState.scope = scope;
      renderRatings();
    });
  });

    // optional: click on list rows later (open student profile) — пока пусто
  if (listEl) {
    listEl.addEventListener("click", (e) => {
      const row = e.target.closest(".lb-row");
      if (!row) return;
      // future: open profile modal
    });
  }
}
   
  // ---------------------------
  // Courses stack
  // ---------------------------
  const COURSES_SCREENS = [
    "all-subjects",
    "subject-hub",
    "lessons",
    "video",
    "practice-start",
    "practice-quiz",
    "practice-result",
    "practice-review",
    "practice-recs",
    "tours",
    "tour-rules",
    "tour-quiz",
    "tour-result",
    "tour-review",
    "books",
    "my-recs"
  ];

  function getCoursesTopScreen() {
    const s = state.courses.stack;
    return s && s.length ? s[s.length - 1] : "all-subjects";
  }

  function showCoursesScreen(screenName) {
    COURSES_SCREENS.forEach(sc => {
      const el = $(`#courses-${sc}`);
      if (!el) return;
      el.classList.toggle("is-active", sc === screenName);
    });
    updateTopbarForView("courses");
  }

  function pushCourses(screenName) {
    state.courses.stack.push(screenName);
    saveState();
    showCoursesScreen(screenName);
  }

  function replaceCourses(screenName) {
    state.courses.stack = [screenName];
    saveState();
    showCoursesScreen(screenName);
  }

  function popCourses() {
  if (state.quizLock) return;

  const top = getCoursesTopScreen();

  // ✅ Safety: если тур-экран оказался первым в стеке (stack=1),
  // то back должен вести в subject-hub, а не выкидывать в Home.
  const isTourFlowScreen = ["tours", "tour-rules", "tour-quiz", "tour-result", "tour-review"].includes(top);
  if (isTourFlowScreen && state.courses.stack.length <= 1) {
    state.courses.stack = ["subject-hub"];
    saveState();
    showCoursesScreen("subject-hub");
    renderSubjectHub();
    return;
  }

          if (state.courses.stack.length > 1) {
    state.courses.stack.pop();
    saveState();

    const next = getCoursesTopScreen();
    showCoursesScreen(next);

    // ✅ Ensure correct screen rendering after back
    if (next === "tours") {
      renderToursStart();          // ✅ вернёт корректный вид туров после выхода из правил
    } else if (next === "practice-start") {
      renderPracticeStart();
    } else if (next === "subject-hub") {
      renderSubjectHub();
    }

    return;
  }

  const targetTab = state.courses.entryTab || state.prevTab || "home";
  setTab(targetTab);
}

function canCoursesBack() {
  const top = getCoursesTopScreen();

  // ✅ special-case: "my-recs" может быть открыт из Profile (stack=1),
  // но back должен вести обратно в entryTab через popCourses()
  if (top === "my-recs") return true;

  // ✅ туры/экраны тура: даже если stack=1 — back показываем (уйдём в subject-hub)
  if (["tours", "tour-rules", "tour-quiz", "tour-result", "tour-review"].includes(top)) return true;

  // ✅ Subject Hub: даже если stack=1 — back должен быть доступен (уйдём в entryTab/prevTab/home)
  if (top === "subject-hub") return true; 

  return state.courses.stack.length > 1;
}

  function renderCoursesStack() {
    const top = getCoursesTopScreen();
    showCoursesScreen(top);
  }

   // ---------------------------
// Profile stack
// ---------------------------
const PROFILE_SCREENS = ["main", "settings"];

function getProfileTopScreen() {
  const s = state.profile?.stack;
  return (s && s.length) ? s[s.length - 1] : "main";
}

function showProfileScreen(screenName) {
  // ✅ Сначала скрываем ВСЕ проф-экраны (на всякий случай, даже если классы “сломались”)
  document.querySelectorAll("#view-profile .profile-screen").forEach(el => {
    el.hidden = true;
    el.style.display = "none";
    el.classList.remove("is-active");
  });

  // ✅ Затем показываем только нужный
  const target = document.getElementById(`profile-${screenName}`);
  if (target) {
    target.hidden = false;
    target.style.display = "block";
    target.classList.add("is-active");
  }

  updateTopbarForView("profile");
     // ✅ FIX: same scroll-restoration issue when switching inside profile stack
  const resetScroll = () => {
    try {
      window.scrollTo(0, 0);
      document.documentElement.scrollTop = 0;
      document.body.scrollTop = 0;
    } catch (e) {}
  };
  resetScroll();
  requestAnimationFrame(resetScroll);
  setTimeout(resetScroll, 0);
}

function pushProfile(screenName) {
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];
  state.profile.stack.push(screenName);
  saveState();
  showProfileScreen(screenName);
}

function replaceProfile(screenName) {
  // ✅ ДЕРЖИМ СТРУКТУРУ: profile.stack
  state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];

  // ✅ replace = один экран в стеке
  state.profile.stack = [screenName];

  saveState();
  showProfileScreen(screenName);

  // ✅ перерендер нужного экрана
  if (screenName === "main") renderProfileMain();
  if (screenName === "settings") renderProfileSettings();
}

function popProfile() {
  if (!state.profile?.stack || state.profile.stack.length <= 1) return;
  state.profile.stack.pop();
  saveState();
  showProfileScreen(getProfileTopScreen());
}

function openProfileSettings() {
  // ✅ заходим в Profile через setTab, чтобы корректно обновлялся prevTab
  if (state.tab !== "profile") setTab("profile");

  // ✅ гарантируем структуру стека
  state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];

  // ✅ фиксируем settings в stack, чтобы "back" делал popProfile()
  if (getProfileTopScreen() !== "settings") {
    pushProfile("settings");
  } else {
    showProfileScreen("settings");
  }

  renderProfileSettings();
  updateTopbarForView("profile");
}

function openProfileMain() {
  // ✅ заходим в Profile через setTab, чтобы корректно обновлялся prevTab
  if (state.tab !== "profile") setTab("profile");

  // ✅ единый источник истины: stack + showProfileScreen()
  replaceProfile("main");
  updateTopbarForView("profile");
}

   // ---------------------------
// Profile DB sync flags (for accurate counts)
// ---------------------------
window.__profileDbSubjectsReady = window.__profileDbSubjectsReady || false;
window.__profileDbSubjectsSyncing = window.__profileDbSubjectsSyncing || false;

async function ensureProfileSubjectsFromDbFresh() {
  if (!window.sb) return { ok: false, reason: "no_sb" };
  if (window.__profileDbSubjectsSyncing) return { ok: true, skipped: true, reason: "syncing" };

  window.__profileDbSubjectsSyncing = true;
  try {
    const res = await syncUserSubjectsFromSupabaseIntoLocalProfile();
    // even if no local profile exists, this means DB read is OK
    window.__profileDbSubjectsReady = true;
    return { ok: true, ...res };
  } catch (e) {
    return { ok: false, reason: "sync_failed" };
  } finally {
    window.__profileDbSubjectsSyncing = false;
  }
}

function renderProfileStack() {
  const top = getProfileTopScreen();
  showProfileScreen(top);
  if (top === "settings") renderProfileSettings();
  if (top === "main") renderProfileMain();
}

   function renderProfileSettings() {
  const profile = loadProfile();
  const list = document.getElementById("profile-competitive-list");
  const note = document.getElementById("settings-competitive-note");
  if (!list) return;

  list.innerHTML = "";

    if (!profile) {
    list.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
    return;
  }

  // Non-school users: competitive is disabled by product rules
  if (!profile.is_school_student) {
    if (note) note.textContent = t("disabled_not_school");
    list.innerHTML = `<div class="empty muted">${t("disabled_not_school")}</div>`;
    return;
  }

  const current = Array.isArray(profile.subjects) ? profile.subjects : [];
  const currentComp = current.filter(s => s.mode === "competitive").map(s => s.key);
  const compCount = currentComp.length;

  if (note) note.textContent = t("settings_competitive_note", { count: compCount });

 // ✅ Competitive settings: показываем ТОЛЬКО main-предметы (study/non-main скрываем полностью)
const mainSubjects = Array.isArray(SUBJECTS) ? SUBJECTS.filter(s => s.type === "main") : [];

mainSubjects.forEach(subj => {
  const isOn = currentComp.includes(subj.key);
  const limitReached = (compCount >= 2 && !isOn);

  const row = document.createElement("div");
  row.className =
    "settings-row" +
    (isOn ? " is-on" : "") +
    (limitReached ? " is-disabled" : "");

  row.innerHTML = `
  <div class="settings-row-left">
    <div style="font-weight:800">${escapeHTML(subj.title)}</div>
    <div class="muted small">${isOn ? "Competitive" : "Выключено"}</div>
  </div>
  <label class="switch">
    <input type="checkbox"
      ${isOn ? "checked" : ""}
      ${limitReached ? "disabled" : ""}>
    <span class="slider"></span>
  </label>
`;

  const input = row.querySelector('input[type="checkbox"]');

  input?.addEventListener("change", async () => {
    if (input.disabled) return;

    const fresh = loadProfile();
    if (!fresh) return;

    const subjects = Array.isArray(fresh.subjects) ? structuredClone(fresh.subjects) : [];
    const idx = subjects.findIndex(s => s.key === subj.key);

    if (idx === -1) subjects.push({ key: subj.key, mode: "study", pinned: false });

    const next = subjects.map(s => ({ ...s }));
    const was = next.find(s => s.key === subj.key);
        const turningOn = !isCompetitiveForUser(fresh, subj.key);
    const fromMode = turningOn ? "study" : "competitive";
    const toMode   = turningOn ? "competitive" : "study";

    if (turningOn) {
      const compNow = next.filter(s => s.mode === "competitive").length;
      if (compNow >= 2) {
        input.checked = false;
        await uiAlert({
          title: "Лимит Competitive",
          message: "Максимум 2 предмета в Competitive.\nСначала выключите другой предмет.",
          okText: "Понял"
        });
        return;
      }
      was.mode = "competitive";
      showToast("Предмет переведён в Competitive");
    } else {
      was.mode = "study";
      showToast("Предмет переведён в Study");
    }

    fresh.subjects = next;
    saveProfile(fresh);

    // ✅ DB sync (await) + history + re-sync local from DB
    input.disabled = true;
    try {
      const us = Array.isArray(fresh?.subjects) ? fresh.subjects.find(s => s.key === subj.key) : null;
      const mode = us?.mode || "study";
      const pinned = !!us?.pinned;

      try { trackEvent("user_subjects_save_started", { subject_key: subj.key, mode, is_pinned: pinned }); } catch {}
      const res = await syncUserSubjectToSupabase(subj.key, mode, pinned);
      try { trackEvent("user_subjects_save_result", { ok: !!res?.ok, reason: res?.reason || null, method: res?.method || null, subject_key: subj.key }); } catch {}

      if (res?.ok) {
        // write history
        try {
          await logUserSubjectHistory({
            user_id: res.uid,
            subject_id: res.subjectId,
            action: "mode_change",
            from_mode: fromMode,
            to_mode: toMode,
            source: "profile",
            meta: { subject_key: subj.key }
          });
        } catch {}

        // force fresh DB snapshot for counts
        window.__profileDbSubjectsReady = false;
        await ensureProfileSubjectsFromDbFresh();
      } else {
        // rollback UI on failure
        input.checked = !turningOn;
        showToast("Не удалось сохранить. Попробуйте ещё раз.");
      }
    } finally {
      input.disabled = false;
    }

    renderHome();
    if (state.tab === "courses") {
      renderAllSubjects();
      if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
    }

    renderProfileSettings();
  });

  list.appendChild(row);
});

      // --- Language segmented buttons ---
const langWrap = document.getElementById("profile-settings-language");
if (langWrap) {
  const currentLang = profile.language || "ru";

  langWrap.querySelectorAll(".lang-btn").forEach(btn => {
    const lang = btn.dataset.lang;
    btn.classList.toggle("is-active", lang === currentLang);

    btn.onclick = () => {
      const fresh = loadProfile();
      if (!fresh) return;

      const nextLang = String(btn.dataset.lang || "ru");
      if (nextLang === (fresh.language || "ru")) return;

      fresh.language = nextLang;
      saveProfile(fresh);

      window.i18n?.setLang(nextLang);
      applyStaticI18n?.();

      renderHome();
      if (state.tab === "courses") renderAllSubjects();
      renderProfileMain();
      renderProfileSettings();

      showToast(t("toast_lang_updated"));
    };
  });
}

    // --- Pinned list ---
  const pinnedToggleBtn = document.getElementById("profile-settings-pinned-toggle");
  if (pinnedToggleBtn) {
    const expanded = !!profile?.pinnedExpanded;
    pinnedToggleBtn.textContent = expanded ? t("settings_hide") : t("settings_show_all");

    pinnedToggleBtn.onclick = () => {
      const fresh = loadProfile();
      if (!fresh) return;
      fresh.pinnedExpanded = !fresh.pinnedExpanded;
      saveProfile(fresh);
      renderProfileSettings();
    };
  }

  const pinnedWrap = document.getElementById("profile-settings-pinned-list");
  if (pinnedWrap) {
    pinnedWrap.innerHTML = "";

    const expanded = !!profile?.pinnedExpanded;

    const userSubjects = Array.isArray(profile.subjects) ? profile.subjects : [];
   const pinnedSet = new Set(
     userSubjects
       .filter(s => !!s.pinned && s.mode === "study")
       .map(s => s.key)
      );

    // Study (Pinned) can show all subjects when expanded, otherwise only pinned
   const allSubjects = Array.isArray(SUBJECTS) ? SUBJECTS.slice() : [];

   const pinnedList = allSubjects.filter(s => pinnedSet.has(s.key));
   const otherList  = allSubjects.filter(s => !pinnedSet.has(s.key));

   const listToRender = expanded ? [...pinnedList, ...otherList] : pinnedList;

       if (!listToRender.length) {
         pinnedWrap.innerHTML = `<div class="empty muted">${t("settings_no_pinned")}</div>`;
         return;
       }

    listToRender.forEach(subj => {
      const isPinned = pinnedSet.has(subj.key);

      const row = document.createElement("div");
      row.className = "settings-row" + (isPinned ? " is-on" : "");

      row.innerHTML = `
  <div>
    <div style="font-weight:800">${escapeHTML(subj.title)}</div>
    <div class="muted small">${isPinned ? t("settings_pinned") : t("settings_not_pinned")}</div>
  </div>
  <label class="switch">
    <input type="checkbox" ${isPinned ? "checked" : ""}>
    <span class="slider"></span>
  </label>
`;

const input = row.querySelector('input[type="checkbox"]');

input?.addEventListener("change", () => {
  const fresh = loadProfile();
  if (!fresh) return;

  // ✅ UI-guard: cannot pin if mode=competitive (project rule)
  const curr = Array.isArray(fresh?.subjects) ? fresh.subjects.find(s => s.key === subj.key) : null;
  const currMode = curr?.mode || "study";
  const currPinned = !!curr?.pinned;

  // If user is trying to TURN ON pin while competitive → block & revert UI
  const wantsPin = !currPinned; // because we toggle
  if (wantsPin && currMode === "competitive") {
    // revert toggle UI to OFF
    try { input.checked = false; } catch {}
    showToast(t("toast_pin_competitive_forbidden") || "Нельзя закрепить предмет в режиме Competitive");
    return; // IMPORTANT: no local change, no DB write
  }

  const updated = togglePinnedSubject(fresh, subj.key);
  saveProfile(updated);

  // ✅ DB-backed user_subjects sync (non-blocking)
  (async () => {
    try {
      const us = Array.isArray(updated?.subjects) ? updated.subjects.find(s => s.key === subj.key) : null;
      const mode = us?.mode || "study";
      const pinned = !!us?.pinned;

      try {
        trackEvent("user_subjects_save_started", { subject_key: subj.key, mode, is_pinned: pinned });
      } catch {}

      const res = await syncUserSubjectToSupabase(subj.key, mode, pinned);

      try {
        trackEvent("user_subjects_save_result", {
          ok: !!res?.ok,
          reason: res?.reason || null,
          method: res?.method || null,
          subject_key: subj.key
        });
      } catch {}
    } catch {}
  })();

  renderHome();
  if (state.tab === "courses") renderAllSubjects();
  renderProfileMain();
  renderProfileSettings();

  showToast(isPinned ? t("toast_removed_pinned") : t("toast_added_pinned"));
});

      pinnedWrap.appendChild(row);
    });
  }
}

  function renderProfileMain() {
  const profile = loadProfile();
       function renderProfileMain() {
  const profile = loadProfile();

  // ✅ IMPORTANT: make profile counts DB-accurate
  // If DB is available and we haven't synced yet this session — sync first and re-render
  if (window.sb && profile && !window.__profileDbSubjectsReady) {
    // show lightweight loading state (no wrong numbers)
    const compElTmp = document.getElementById("profile-metric-competitive");
    const studyElTmp = document.getElementById("profile-metric-study");
    const slotsCountElTmp = document.getElementById("profile-competitive-slots-count");
    if (compElTmp) compElTmp.textContent = "…";
    if (studyElTmp) studyElTmp.textContent = "…";
    if (slotsCountElTmp) slotsCountElTmp.textContent = "…/2";

    ensureProfileSubjectsFromDbFresh().then(() => {
      // re-render profile screens with fresh DB state
      try { renderProfileMain(); } catch {}
      try { renderProfileSettings(); } catch {}
      try { renderHome(); } catch {}
    });

    return;
  }

  const nameEl = document.getElementById("profile-dash-name");
  const metaEl = document.getElementById("profile-dash-meta");
  const avatarEl = document.getElementById("profile-avatar");
  const avatarInitials = document.getElementById("profile-avatar-initials");
  const currentLevelEl = document.getElementById("profile-current-level");
  const slotsCountEl = document.getElementById("profile-competitive-slots-count");
  const slotsListEl = document.getElementById("profile-competitive-slots-list");
     
  const compEl = document.getElementById("profile-metric-competitive");
  const studyEl = document.getElementById("profile-metric-study");

  const bestEl = document.getElementById("profile-metric-best");
  const trendEl = document.getElementById("profile-metric-trend");
  const stabilityEl = document.getElementById("profile-metric-stability");
  const toursEl = document.getElementById("profile-metric-tours");

  const hintEl = document.getElementById("profile-dash-hint");
  const ratingsBtn = document.querySelector('[data-action="profile-open-ratings"]');

  if (!nameEl || !metaEl || !compEl || !studyEl || !bestEl || !trendEl || !stabilityEl || !toursEl) return;

    if (!profile) {
    nameEl.textContent = "Сначала регистрация";
    metaEl.textContent = "—";
    if (avatarEl) avatarEl.style.backgroundImage = "";
    if (avatarInitials) avatarInitials.textContent = "";
    if (currentLevelEl) currentLevelEl.textContent = "—";
    if (slotsCountEl) slotsCountEl.textContent = "0/2";
    if (slotsListEl) slotsListEl.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
       
    compEl.textContent = "0";
    studyEl.textContent = "0";

    bestEl.textContent = "—";
    trendEl.textContent = "—";
    stabilityEl.textContent = "—";
    toursEl.textContent = "—";

    if (ratingsBtn) ratingsBtn.disabled = true;

    if (hintEl) hintEl.textContent = "После регистрации профиль станет вашим дашбордом.";
    return;
  }


  const fullName = String(profile.full_name || "").trim();
  nameEl.textContent = fullName || "Профиль";

  if (avatarEl) {
    const photo = profile?.telegram?.photo_url || "";
    avatarEl.style.backgroundImage = photo ? `url("${photo}")` : "";
    if (avatarInitials) avatarInitials.textContent = photo ? "" : (fullName.split(" ").map(p => p[0]).slice(0, 2).join("").toUpperCase() || "IC");
  }

  const metaParts = [];
  if (profile.region) metaParts.push(profile.region);
  if (profile.district) metaParts.push(profile.district);
  if (profile.school) metaParts.push(`№${String(profile.school).replace(/^№/,"")}`);
  if (profile.class) metaParts.push(`${profile.class} класс`);
  metaEl.textContent = metaParts.join(" • ") || "—";

    const subjects = Array.isArray(profile.subjects) ? profile.subjects : [];
  const comp = subjects.filter(s => s.mode === "competitive");
  const study = subjects.filter(s => s.mode === "study");
  const pinned = subjects.filter(s => !!s.pinned);

  compEl.textContent = String(comp.length);
  studyEl.textContent = String(study.length);

  // --- Best / Trend / Stability (реальные данные из practice_history_v1:*) ---
  const keys = subjects.map(s => s.key).filter(Boolean);

  // Best (max percent)
  let best = null;
  const allAttempts = [];

  keys.forEach(k => {
    const h = loadPracticeHistory(k);
    if (h?.best) {
      if (!best || (Number(h.best.percent) > Number(best.percent))) best = h.best;
    }
    if (Array.isArray(h?.last)) allAttempts.push(...h.last.map(a => ({ ...a, _subjectKey: k })));
  });

  bestEl.textContent = best ? `${Math.round(Number(best.percent) || 0)}%` : "—";

  // Trend: avg(last 3) - avg(prev 3)
  allAttempts.sort((a, b) => (Number(b.ts) || 0) - (Number(a.ts) || 0));
  const last6 = allAttempts.slice(0, 6);
  if (last6.length >= 4) {
    const a3 = last6.slice(0, 3);
    const b3 = last6.slice(3, 6);

    const avg = arr => arr.reduce((s, x) => s + (Number(x.percent) || 0), 0) / Math.max(1, arr.length);
    const diff = Math.round(avg(a3) - avg(b3));

    trendEl.textContent = (diff === 0) ? "0%" : `${diff > 0 ? "+" : ""}${diff}%`;
  } else {
    trendEl.textContent = "—";
  }

  // Stability: уникальные дни с практикой за последние 7 дней
  const now = Date.now();
  const weekMs = 7 * 24 * 60 * 60 * 1000;
  const days = new Set();
  allAttempts.forEach(a => {
    const ts = Number(a.ts) || 0;
    if (!ts) return;
    if (now - ts > weekMs) return;
    const d = new Date(ts);
    const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
    days.add(key);
  });
    const activeDays = days.size;

  if (!allAttempts.length) {
    stabilityEl.textContent = t("profile_stability_no_data");
  } else {
    const pct = Math.round((activeDays / 7) * 100);
    stabilityEl.textContent = (pct > 0) ? `${pct}%` : t("profile_stability_no_activity");
  }

  // Tours: пока нет локальной истории туров в этом фронте — держим “—”
  toursEl.textContent = "—";
  
  if (currentLevelEl) {
    const bestPct = Number(best?.percent || 0);
    const level = bestPct >= 85 ? t("profile_level_advanced") : (bestPct >= 70 ? t("profile_level_intermediate") : (bestPct > 0 ? t("profile_level_beginner") : "—"));
    currentLevelEl.textContent = level;
  }

    if (slotsCountEl) slotsCountEl.textContent = `${comp.length}/2`;
  if (slotsListEl) {
    slotsListEl.innerHTML = "";

    // 1) Активные competitive слоты (0..2)
    comp.forEach(us => {
      const subj = subjectByKey(us.key);
      const row = document.createElement("div");
      row.className = "slot-card";
      row.innerHTML = `
        <div>
          <div class="slot-title">${escapeHTML(subj?.title || us.key)}</div>
          <div class="muted small">${t("profile_slot_hint")}</div>
        </div>
        <button type="button" class="btn mini" data-subject="${escapeHTML(us.key)}">${t("profile_view_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        state.courses.subjectKey = us.key;
        saveState();
        setTab("courses");
        replaceCourses("subject-hub");
        renderSubjectHub();
      });

      slotsListEl.appendChild(row);
    });

    // 2) Пустые слоты до 2 (Empty slot + JOIN)
    const emptyCount = Math.max(0, 2 - comp.length);
    for (let i = 0; i < emptyCount; i++) {
      const row = document.createElement("div");
      row.className = "slot-card is-empty";
      row.innerHTML = `
        <div>
          <div class="slot-empty-title">${t("profile_empty_slot")}</div>
          <div class="muted small">${t("reg_competitive_subject_hint")}</div>
        </div>
        <button type="button" class="btn join" data-action="profile-settings">${t("profile_join_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        setTab("profile");
        replaceProfile("settings");
      });

      slotsListEl.appendChild(row);
    }
  }
   
  // Disabled state: рейтинг/туры только школьникам
  if (ratingsBtn) {
    const isSchool = !!profile.is_school_student;
    ratingsBtn.disabled = !isSchool;
    if (!isSchool) ratingsBtn.title = t("disabled_not_school");
  }

  if (hintEl) {
    hintEl.textContent = pinned.length
      ? "Закреплённые предметы уже ускоряют доступ. Дальше — стабильность."
      : "Закрепите 1–3 предмета — и вы будете открывать нужное быстрее, чем Telegram.";
  }
      // Credentials (Profile: list + progress)
  try { renderProfileCredentialsUI(); } catch {}
 }

     // ---------------------------
  // Modal (for confirmations in Telegram WebApp)
  // ---------------------------
  let modalResolve = null;

  function closeModal(result = null) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = "";
    root.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    if (typeof modalResolve === "function") {
      const r = modalResolve;
      modalResolve = null;
      r(result);
    }
  }

  function openModal(html) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = html;
    root.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");

    // backdrop close (only if data-close="backdrop")
    const backdrop = root.querySelector("[data-modal-backdrop]");
    if (backdrop) {
      backdrop.addEventListener("click", (e) => {
        if (e.target === backdrop && backdrop.dataset.close === "backdrop") {
          closeModal(false);
        }
      });
    }

    // buttons
    root.querySelectorAll("[data-modal-action]").forEach(btn => {
      btn.addEventListener("click", () => {
        const act = btn.getAttribute("data-modal-action");
        if (act === "ok") closeModal(true);
        if (act === "cancel") closeModal(false);
      });
    });
  }

  function uiConfirm({ title, message, okText = "OK", cancelText = "Cancel" }) {
    return new Promise((resolve) => {
      modalResolve = resolve;

      const html = `
        <div class="modal-backdrop" data-modal-backdrop data-close="none">
          <div class="modal">
            <div class="modal-title">${escapeHTML(title || "")}</div>
            <div class="modal-text">${escapeHTML(message || "")}</div>
            <div class="modal-actions">
              <button type="button" class="btn" data-modal-action="cancel">${escapeHTML(cancelText)}</button>
              <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(okText)}</button>
            </div>
          </div>
        </div>
      `;

      openModal(html);
    });
  }

  function uiAlert({ title, message, okText = "OK" }) {
    return new Promise((resolve) => {
      modalResolve = resolve;

      const html = `
        <div class="modal-backdrop" data-modal-backdrop data-close="none">
          <div class="modal">
            <div class="modal-title">${escapeHTML(title || "")}</div>
            <div class="modal-text">${escapeHTML(message || "")}</div>
            <div class="modal-actions modal-actions-single">
              <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(okText)}</button>
            </div>
          </div>
        </div>
      `;

      openModal(html);
    });
  }

  // ---------------------------
  // Toast
  // ---------------------------
  let toastTimer = null;
  function showToast(message, ms = 2500) {
    const el = $("#toast");
    if (!el) return;
    el.textContent = message;
    el.classList.add("is-show");
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.remove("is-show"), ms);
  }

  // ---------------------------
  // Registration UI
  // ---------------------------
    function updateSchoolFieldsVisibility() {
    const select = $("#reg-is-school");
    const toggle = $("#reg-is-school-toggle");

    const isSchool = toggle ? !!toggle.checked : (select?.value === "yes");

    // keep hidden select in sync (legacy)
    if (select && toggle) {
      select.value = isSchool ? "yes" : "no";
    }

    // show/hide school fields
    const block = $("#reg-school-block");
    if (block) block.style.display = isSchool ? "grid" : "none";

    // ✅ dynamic subject card texts (competitive vs study)
    const labelEl = document.querySelector('[data-i18n="reg_competitive_subject_label"]');
    const hintEl  = document.querySelector('[data-i18n="reg_competitive_subject_hint"]');

    if (labelEl) {
      labelEl.textContent = isSchool ? t("reg_subject_label_competitive") : t("reg_subject_label_study");
    }
    if (hintEl) {
      hintEl.textContent = isSchool ? t("reg_subject_hint_competitive") : t("reg_subject_hint_study");
    }

    // update subject names in chips/selects too
    try { applyRegSubjectI18n(); } catch {}
           // show/hide subjects section for non-school users
    const subjectSection = $("#reg-subject-section");
    const nonStudentCard = $("#reg-nonstudent-subjects");

    if (subjectSection) subjectSection.classList.toggle("hidden", !isSchool);
    if (nonStudentCard) nonStudentCard.classList.toggle("hidden", isSchool);

    // when switching OFF school mode: clear selected subjects (avoid accidental saving)
    if (!isSchool) {
      const main1 = $("#reg-main-subject-1");
      const main2 = $("#reg-main-subject-2");
      const add1  = $("#reg-additional-subject");

      if (main1) main1.value = "";
      if (main2) main2.value = "";
      if (add1) add1.value = "";

      // clear chip UI
      const chipBtns = $$("#reg-subject-chips .chip-btn");
      chipBtns.forEach(b => b.classList.remove("is-active"));
    }

    // refresh submit readiness (if implemented)
    try { updateRegSubmitReady?.(); } catch {}
  }

     function applyRegSubjectI18n() {
    // chips
    const chipBtns = $$("#reg-subject-chips .chip-btn");
    chipBtns.forEach(btn => {
      const key = btn.dataset.subjectKey;
      if (!key) return;
      const k = "subj_" + key;
      const val = t(k);
      if (val && val !== k) btn.textContent = val;
    });

    // selects options (keep values, translate labels)
    const ids = ["reg-main-subject-1", "reg-main-subject-2", "reg-additional-subject"];
    ids.forEach(id => {
      const sel = document.getElementById(id);
      if (!sel) return;
      Array.from(sel.options).forEach(opt => {
        const v = (opt.value || "").trim();
        if (!v) {
          // placeholder / none
          if (id === "reg-additional-subject") opt.textContent = t("reg_choose_none");
          else opt.textContent = t("reg_choose_placeholder");
          return;
        }
        const k = "subj_" + v;
        const val = t(k);
        if (val && val !== k) opt.textContent = val;
      });
    });
  }

  function initRegSubjectChips() {
  const wrap = $("#reg-subject-chips");
  const main1 = $("#reg-main-subject-1");
  const main2 = $("#reg-main-subject-2");
  if (!wrap || !main1 || !main2) return;

  const summaryEl = $("#reg-subject-summary");
  const buttons = () => $$("#reg-subject-chips .chip-btn");

  const tt = (key, fallback) => {
    const v = t(key);
    return (v && v !== key) ? v : fallback;
  };

  const getSubjectLabel = (subjectKey) => {
    if (!subjectKey) return "";
    const k = "subj_" + subjectKey;
    const v = t(k);
    if (v && v !== k) return v;

    const btn = buttons().find(b => b.dataset.subjectKey === subjectKey);
    return btn ? btn.textContent.trim() : subjectKey;
  };

  const updateSummary = () => {
    if (!summaryEl) return;

    const a = (main1.value || "").trim();
    const b = (main2.value || "").trim();

    if (!a && !b) {
      summaryEl.textContent = tt("reg_subject_summary_none", "Выберите до 2 предметов");
      return;
    }

    const primaryTag = tt("reg_subject_primary_tag", "Основной");
    const secondaryTag = tt("reg_subject_secondary_tag", "Дополнительный");

    const rows = [];
    if (a) {
      rows.push(
        `<div class="reg-subject-line"><span class="reg-subject-tag">${escapeHTML(primaryTag)}</span><span class="reg-subject-val">${escapeHTML(getSubjectLabel(a))}</span></div>`
      );
    }
    if (b) {
      rows.push(
        `<div class="reg-subject-line"><span class="reg-subject-tag">${escapeHTML(secondaryTag)}</span><span class="reg-subject-val">${escapeHTML(getSubjectLabel(b))}</span></div>`
      );
    }
    summaryEl.innerHTML = rows.join("");
  };

  const syncChipsFromSelects = () => {
    const selected = [main1.value, main2.value].filter(Boolean);
    buttons().forEach(btn => {
      btn.classList.toggle("is-active", selected.includes(btn.dataset.subjectKey));
    });
    updateSummary();
  };

  const syncSelectsFromChips = () => {
    const selected = buttons().filter(b => b.classList.contains("is-active")).map(b => b.dataset.subjectKey);
    main1.value = selected[0] || "";
    main2.value = selected[1] || "";
    updateSummary();
  };

  wrap.addEventListener("click", (e) => {
    const btn = e.target.closest(".chip-btn");
    if (!btn) return;

    const current = buttons().filter(b => b.classList.contains("is-active"));

    if (btn.classList.contains("is-active")) {
      btn.classList.remove("is-active");
      syncSelectsFromChips();
      return;
    }

    if (current.length >= 2) {
      showToast(t("reg_subjects_limit"));
      return;
    }

    btn.classList.add("is-active");
    syncSelectsFromChips();
  });

  main1.addEventListener("change", syncChipsFromSelects);
  main2.addEventListener("change", syncChipsFromSelects);
  syncChipsFromSelects();
}
       // live language switch on registration
    const langSel = $("#reg-language");
    if (langSel) {
      langSel.addEventListener("change", () => {
        try { window.i18n?.setLang(langSel.value); } catch {}
        try { applyStaticI18n(); } catch {}
        try { updateSchoolFieldsVisibility(); } catch {}
        try { applyRegSubjectI18n(); } catch {}
        try { refreshRegionDistrictPlaceholders?.(); } catch {}
      });
    }

    // first paint (ensures no RU/EN mix)
    try { applyRegSubjectI18n(); } catch {}

   
  function isRegistered() {
    return !!loadProfile();
  }

  // ---------------------------
  // Home rendering (demo)
  // ---------------------------
  function renderHome() {
    const profile = loadProfile();
    const compWrap = $("#home-competitive-list");
    const pinnedWrap = $("#home-study-list");
    if (!compWrap || !pinnedWrap) return;

    compWrap.innerHTML = "";
    pinnedWrap.innerHTML = "";

    if (!profile) {
      compWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      pinnedWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      return;
    }

    const comp = profile.subjects?.filter(s => s.mode === "competitive") || [];
    const pinned = profile.subjects?.filter(s => !!s.pinned && s.mode === "study") || [];


    if (!comp.length) compWrap.innerHTML = `<div class="empty muted">${t("home_competitive_empty")}</div>`;
    if (!pinned.length) pinnedWrap.innerHTML = `<div class="empty muted">${t("home_pinned_empty")}</div>`;

    comp.forEach(s => compWrap.appendChild(homeCompetitiveCardEl(s)));
    pinned.slice(0, 4).forEach((s, idx) => pinnedWrap.appendChild(homePinnedTileEl(s, idx)));
  }

    function homeCompetitiveCardEl(userSubject) {
  const subj = subjectByKey(userSubject.key);
  const title = subj ? subj.title : userSubject.key;

  const el = document.createElement("div");
  el.className = "home-competitive-card";

  // ✅ нужно для CSS-картинок по предмету
  el.dataset.subject = String(userSubject.key || "").toLowerCase();

  el.innerHTML = `
    <div class="home-competitive-badge">ACTIVE</div>
    <div class="home-competitive-hero">
      <div class="home-competitive-hero-img" aria-hidden="true"></div>
    </div>
    <div class="home-competitive-body">
      <div class="home-competitive-module">MODULE 3</div>
      <div class="home-competitive-title">${escapeHTML(title)}</div>
      <div class="home-competitive-meta">
        <span>${t("home_course_completion")}</span>
        <span class="home-competitive-rank">${t("home_rank_label")}: 12th</span>
      </div>
      <div class="home-progress">
        <div class="home-progress-fill" style="width:65%"></div>
      </div>
    </div>
   `;

    const btn = document.createElement("button");
btn.type = "button";
btn.className = "btn primary home-competitive-btn";
btn.textContent = "Открыть предмет";
btn.addEventListener("click", (e) => {
  e.stopPropagation();

  // ✅ Home: сразу открываем Subject Hub (без промежуточных туров)
  state.courses.subjectKey = userSubject.key;
  saveState();
  setTab("courses");
  replaceCourses("subject-hub");
  renderSubjectHub();
});

  el.appendChild(btn);
  return el;
}

  function homePinnedTileEl(userSubject, index = 0) {
  const subj = subjectByKey(userSubject.key);
  const title = subj ? subj.title : userSubject.key;
  const lessonCounts = ["8/12", "15/20", "4/10", "2/15"];
  const lessons = lessonCounts[index % lessonCounts.length];

  const el = document.createElement("button");
  el.type = "button";
  el.className = "home-pinned-tile";
  el.innerHTML = `
    <div class="home-pinned-ico">📘</div>
    <div class="home-pinned-title">${escapeHTML(title)}</div>
    <div class="home-pinned-meta">${lessons} ${t("home_lessons_label")}</div>
  `;

  el.addEventListener("click", () => {
    state.courses.subjectKey = userSubject.key;
    saveState();
    setTab("courses");
    replaceCourses("subject-hub");
    renderSubjectHub();
});

  return el;
}

  // ---------------------------
  // Courses: All Subjects rendering
  // ---------------------------
  function setImgWithFallback(imgEl, candidates) {
  if (!imgEl) return;
  const list = (candidates || []).filter(Boolean);
  if (!list.length) return;

  let i = 0;
  const next = () => {
    i += 1;
    if (i < list.length) imgEl.src = list[i];
  };

  imgEl.onerror = () => next();
  imgEl.src = list[0];
}

function subjectIconCandidates(subjectKey) {
  const k = String(subjectKey || "").trim();

  // ✅ основной формат (у тебя main уже так загружены)
  const a = [
    `asset/${k}.png.png`,
    `asset/${k}.png`,
    `asset/${k}.PNG`,
  ];

  // ✅ спец-кейс: у тебя файл IELTS.png (с заглавными)
  if (k.toLowerCase() === "ielts") {
    a.push("asset/IELTS.png");
  }

  return a;
}

   function renderAllSubjects() {
  const grid = $("#subjects-grid");
  if (!grid) return;

  const profile = loadProfile();

  // Если нет профиля — каталогу нечего делать (но это не должно случаться)
  grid.innerHTML = "";
  if (!profile) {
    grid.innerHTML = `<div class="empty muted">Сначала регистрация.</div>`;
    return;
  }

  const userSubjects = Array.isArray(profile.subjects) ? profile.subjects : [];
  const competitiveCount = userSubjects.filter(s => s.mode === "competitive").length;

  const mainSubjects = SUBJECTS.filter(s => s.type === "main");
const additionalSubjects = SUBJECTS.filter(s => s.type !== "main");

       // ---- Main catalog filter (Competitive / Study) — chips under Courses title
state.courses = state.courses || {};

// миграция: если осталось "all" — считаем "study"
if (!state.courses.mainFilter || state.courses.mainFilter === "all") {
  state.courses.mainFilter = "study"; // competitive | study
  saveState();
}

const filtersWrap = $("#courses-filter-row");
if (filtersWrap) filtersWrap.innerHTML = "";

const renderMainFilterRow = () => {
  if (!filtersWrap) return;

  const row = document.createElement("div");
  row.className = "grid-section-filters";
  row.innerHTML = `
    <button type="button" class="chip ${state.courses.mainFilter === "competitive" ? "is-active" : ""}" data-main-filter="competitive">Competitive</button>
    <button type="button" class="chip ${state.courses.mainFilter === "study" ? "is-active" : ""}" data-main-filter="study">Study</button>
  `;

  row.querySelectorAll("[data-main-filter]").forEach(btn => {
    const v = btn.getAttribute("data-main-filter");
    btn.addEventListener("pointerup", (e) => {
      e.preventDefault();
      state.courses.mainFilter = v;
      saveState();
      renderAllSubjects();
    });
    btn.addEventListener("click", () => {
      state.courses.mainFilter = v;
      saveState();
      renderAllSubjects();
    });
  });

  filtersWrap.appendChild(row);
};

  const isPinnedKey = (key) => {
    const us = userSubjects.find(x => x.key === key) || null;
    return !!us?.pinned;
  };

  const isCompetitiveKey = (key) => {
    const us = userSubjects.find(x => x.key === key) || null;
    return (us?.mode || "study") === "competitive";
  };

  const sortPinnedFirst = (list) => {
    return list.slice().sort((a, b) => Number(isPinnedKey(b.key)) - Number(isPinnedKey(a.key)));
  };

const appendSectionTitle = (text) => {
  const el = document.createElement("div");
  el.className = "grid-section-title";
  el.textContent = text;
  grid.appendChild(el);
};

const appendSubjectCard = (s) => {
  const us = userSubjects.find(x => x.key === s.key) || null;
  const isPinned = !!us?.pinned;
  const mode = us?.mode || "study"; // default display
  const isComp = mode === "competitive";

  const card = document.createElement("div");
  card.className = "catalog-card";

  // Top clickable area: open hub (but does NOT change profile)
  const head = document.createElement("button");
  head.type = "button";
  head.className = "catalog-head";
  const imgKey = String(s.key || "").trim();
const imgPng2 = `asset/${imgKey}.png.png`;
const imgPng = `asset/${imgKey}.png`;

head.innerHTML = `
  <div class="catalog-row">
    <div class="catalog-left">
      <div class="catalog-ico" aria-hidden="true">
        <img class="catalog-ico-img" alt="" loading="lazy">
      </div>

      <div class="catalog-text">
        <div class="card-title-row">
          <div class="card-title" style="margin:0">${escapeHTML(s.title)}</div>
          ${isPinned ? `<span class="badge badge-pin badge-inline">Pinned</span>` : ``}
        </div>
      </div>
   </div>

   <div class="catalog-badges">
     ${s.type === "main" && isComp ? `<span class="badge badge-comp">Competitive</span>` : ``}
      </div>
  </div>
`;
// ✅ icon image with robust fallback (.png.png -> .png -> .PNG + IELTS special)
const imgEl = head.querySelector(".catalog-ico-img");
setImgWithFallback(imgEl, subjectIconCandidates(s.key));

    head.addEventListener("click", () => {
    // "Открыть" — без изменения профиля, как в контракте
    state.courses.subjectKey = s.key;
    saveState();
    pushCourses("subject-hub");
    renderSubjectHub();
  });

  card.appendChild(head); // ✅ вернуть заголовок с названием предмета

    // Footer row:
  // - Competitive tab: one action (detach competitive)
  // - Study tab: switch (pinned on Home)
  const footer = document.createElement("div");

  if (state.courses.mainFilter === "competitive") {
    footer.className = "catalog-actions one";

    const btnDetach = document.createElement("button");
    btnDetach.type = "button";
    btnDetach.className = "mini-btn ghost";
    btnDetach.textContent = t("btn_detach") || "Открепить";
        btnDetach.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();

      const ok = await uiConfirm({
        title: t("detach_comp_title") || "Снять Competitive?",
        message:
          (t("detach_comp_text") || "Вы действительно хотите снять Competitive с этого предмета?\n\nПоследствия:\n• прогресс и попытки по предмету будут обнулены\n• предмет перестанет участвовать в рейтингах\n\nВы сможете выбрать другой предмет в Competitive."),
        okText: t("detach_comp_ok") || "Снять",
        cancelText: t("cancel") || "Отмена"
      });

      if (!ok) return;

      const prof = loadProfile() || profile;
      const us = (prof.subjects || []).find(x => x.key === s.key) || null;
      if (!us) return;

      // 1) local: переводим в study + снимаем pin
      us.mode = "study";
      us.pinned = false;
      saveProfile(prof);

      // 2) DB: записываем mode/pinned
      try {
        const res = await syncUserSubjectToSupabase(s.key, "study", false);
        if (!res?.ok) {
          showToast("Не удалось сохранить в базе. Попробуйте ещё раз.");
          renderAllSubjects();
          return;
        }
      } catch {
        showToast("Ошибка сети. Попробуйте ещё раз.");
        renderAllSubjects();
        return;
      }

      // 3) DB: обнуляем достижения по предмету (практика/туры/кеш рейтинга)
      try {
        const uid = await getAuthUid();
        const subjectId = await getSubjectIdByKey(s.key);

        if (window.sb && uid && subjectId) {
          // practice
          try { await window.sb.from("practice_answers").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}
          try { await window.sb.from("practice_attempts").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}

          // tours
          try { await window.sb.from("tour_attempts").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}
          try { await window.sb.from("tour_progress").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}
          try { await window.sb.from("user_answers").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}

          // ratings cache
          try { await window.sb.from("ratings_cache").delete().eq("user_id", uid).eq("subject_id", subjectId); } catch {}
        }
      } catch {}

      showToast(t("detach_comp_done") || "Competitive снят. Прогресс обнулён.");
           try {
  const uid = await getAuthUid();
  const subjectId = await getSubjectIdByKey(s.key);
  if (uid && subjectId) {
    await logUserSubjectHistory({
      user_id: uid,
      subject_id: subjectId,
      action: "detach_competitive",
      from_mode: "competitive",
      to_mode: "study",
      source: "courses",
      meta: { subject_key: s.key }
    });
  }
} catch {}

      renderHome();
      renderAllSubjects();
      renderProfileSettings?.();
    });

    footer.appendChild(btnDetach);
  } else {
    footer.className = "catalog-toggle-row" + (isPinned ? " is-on" : "");

    const left = document.createElement("div");
    left.className = "catalog-toggle-left";

    const stateLine = document.createElement("div");
    stateLine.className = "catalog-toggle-state";
    stateLine.textContent = isPinned ? t("course_toggle_on") : t("course_toggle_off");

    left.appendChild(stateLine);

    const sw = document.createElement("label");
    sw.className = "switch";

    sw.innerHTML = `
      <input type="checkbox" ${isPinned ? "checked" : ""} aria-label="${t("course_toggle_aria") || "Show on Home"}">
      <span class="slider"></span>
    `;

    const input = sw.querySelector("input");

    // IMPORTANT: switch click must NOT open the subject card
    input.addEventListener("click", (e) => e.stopPropagation());

        input.addEventListener("change", async (e) => {
      e.stopPropagation();

      const prof = loadProfile() || profile;
      const updated = togglePinnedSubject(prof, s.key);
      saveProfile(updated);

      // new state
      const after = (updated?.subjects || []).find(x => x.key === s.key) || null;
      const nowPinned = !!after?.pinned;
      const mode = after?.mode || "study";

      // UI feedback instantly
      showToast(nowPinned ? t("toast_added_pinned") : t("toast_removed_pinned"));

      // ✅ DB sync (so pinned is реально сохранён в базе)
      try {
        const res = await syncUserSubjectToSupabase(s.key, mode, nowPinned);
        if (!res?.ok) {
          // если база отказала — откатываем локально и UI
          const prof2 = loadProfile() || updated;
          const us2 = (prof2.subjects || []).find(x => x.key === s.key) || null;
          if (us2) us2.pinned = !nowPinned;
          saveProfile(prof2);

          input.checked = !nowPinned;
          showToast("Не удалось сохранить в базе. Попробуйте ещё раз.");
        }
      } catch {
        // откат на всякий случай
        const prof2 = loadProfile() || updated;
        const us2 = (prof2.subjects || []).find(x => x.key === s.key) || null;
        if (us2) us2.pinned = !nowPinned;
        saveProfile(prof2);

        input.checked = !nowPinned;
        showToast("Ошибка сети. Попробуйте ещё раз.");
      }

      // refresh screens that use pinned
      renderHome();
      renderAllSubjects();
      renderProfileSettings?.();
    });

    footer.appendChild(left);
    footer.appendChild(sw);
  }

  card.appendChild(footer);
  grid.appendChild(card);
};

  // ---- MAIN section + filter row + pinned-first + filter mode
  // ✅ chips render once under "Courses"
renderMainFilterRow();

if (mainSubjects.length) {
  appendSectionTitle("Main (Cambridge)");

  let mainOut = mainSubjects.slice();
  if (state.courses.mainFilter === "competitive") {
    mainOut = mainOut.filter(s => isCompetitiveKey(s.key));
  } else if (state.courses.mainFilter === "study") {
    mainOut = mainOut.filter(s => !isCompetitiveKey(s.key));
  }
  mainOut = sortPinnedFirst(mainOut);

  mainOut.forEach(appendSubjectCard);
}


    // ---- ADDITIONAL section (always Study by spec), pinned-first
  // ✅ при Competitive additional не показываем
   if (state.courses.mainFilter !== "competitive" && additionalSubjects.length) {
     appendSectionTitle("Additional");
     const addOut = sortPinnedFirst(additionalSubjects);
     addOut.forEach(appendSubjectCard);
   }
}

  function openSubjectHub(subjectKey) {
    state.courses.subjectKey = subjectKey;
    saveState();
    pushCourses("subject-hub");
    renderSubjectHub();
  }

  // ---------------------------
  // Subject Hub rendering
  // ---------------------------
  function renderSubjectHub() {
  const profile = loadProfile();
  const subj = subjectByKey(state.courses.subjectKey);

  const titleEl = $("#subject-hub-title");
  const metaEl = $("#subject-hub-meta");

  const subjectKey = state.courses.subjectKey;
  const us = profile?.subjects?.find(x => x.key === subjectKey) || null;

  if (titleEl) titleEl.textContent = subj ? subj.title : "Subject";
  if (metaEl) {
    metaEl.textContent = us ? `${us.mode.toUpperCase()} • ${us.pinned ? "PINNED" : "NOT PINNED"}` : "NOT ADDED";
  }

  // ✅ Visual-only mode flag for CSS (Study vs Competitive)
  const hubRoot = $("#courses-subject-hub");
  if (hubRoot) {
    hubRoot.classList.toggle("is-study", us?.mode === "study");
    hubRoot.classList.toggle("is-competitive", us?.mode === "competitive");
  }
         // ---- Availability toggles in Subject Hub (Tours only when allowed) ----
    const toursBtn = document.querySelector('#courses-subject-hub [data-action="open-tours"]');
    const toursSub = toursBtn?.querySelector(".muted.small");

    if (toursBtn) {
      const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);

            // Additional subjects: tours do not exist by spec
      if (isAdditionalSubjectKey(state.courses.subjectKey)) {
        toursBtn.disabled = false;
        toursBtn.classList.add("is-disabled");
        if (toursSub) toursSub.textContent = getToursDeniedText("not_main");
      } else if (!eligibility.ok) {
        toursBtn.disabled = false;
        toursBtn.classList.add("is-disabled");
        if (toursSub) toursSub.textContent = getToursDeniedText(eligibility.reason);
      } else {
        toursBtn.disabled = false;
        toursBtn.classList.remove("is-disabled");
        if (toursSub) toursSub.textContent = t("tours_active_and_completed") || "Активные и прошедшие";
      }
    }

    updateTopbarForView("courses");
  }

  // ---------------------------
  // Lessons (demo)
  // ---------------------------
  function renderLessons() {
    const list = $("#lessons-list");
    const subj = subjectByKey(state.courses.subjectKey);
    if (!list) return;

    list.innerHTML = "";

    const demoLessons = [
      { id: "l1", title: "Lesson 1 — Intro", topic: "Basics" },
      { id: "l2", title: "Lesson 2 — Core", topic: "Core" },
      { id: "l3", title: "Lesson 3 — Practice", topic: "Application" }
    ];

    demoLessons.forEach(lesson => {
      const item = document.createElement("div");
      item.className = "list-item";
      item.innerHTML = `
        <div style="font-weight:800">${lesson.title}</div>
        <div class="muted small">${subj ? subj.title : ""} • ${lesson.topic}</div>
      `;
      item.addEventListener("click", () => {
        state.courses.lessonId = lesson.id;
        saveState();
        pushCourses("video");
        renderVideo(lesson);
      });
      list.appendChild(item);
    });
  }

  function renderVideo(lesson) {
    const tEl = $("#video-title");
    const mEl = $("#video-meta");
    if (tEl) tEl.textContent = lesson?.title || "Video";
    if (mEl) mEl.textContent = lesson?.topic || "";
    updateTopbarForView("courses");
  }

    // ---------------------------
  // Practice v1 — per spec:
  // 10 questions (3/5/2), MCQ + INPUT, per-question timer, pause/resume,
  // best + last 5 attempts, review + recommendations
  // ---------------------------

  function loadPracticeDraft() {
    return safeJsonParse(localStorage.getItem(LS.practiceDraft), null);
  }
  function savePracticeDraft(draft) {
    localStorage.setItem(LS.practiceDraft, JSON.stringify(draft));
  }
  function clearPracticeDraft() {
    localStorage.removeItem(LS.practiceDraft);
  }

   function loadMyRecs() {
  return safeJsonParse(localStorage.getItem(LS.myRecs), { bySubject: {} });
}

function saveMyRecs(data) {
  localStorage.setItem(LS.myRecs, JSON.stringify(data));
}

function addMyRecsFromAttempt(attempt) {
  const wrong = (attempt?.details || []).filter(d => !d.isCorrect);
  const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));
  if (!topics.length) return { added: 0, topics: [] };

  const store = loadMyRecs();
  store.bySubject = store.bySubject || {};
  const subjKey = attempt.subjectKey || "unknown";

  const existing = new Set((store.bySubject[subjKey] || []).map(x => x.topic));
  const nowTs = Date.now();

  const add = topics
    .filter(tp => !existing.has(tp))
    .map(tp => ({ topic: tp, ts: nowTs }));

  store.bySubject[subjKey] = [...add, ...(store.bySubject[subjKey] || [])].slice(0, 50);
  saveMyRecs(store);

  return { added: add.length, topics };
}

  function formatMMSS(sec) {
    const s = Math.max(0, Number(sec) || 0);
    const mm = Math.floor(s / 60);
    const ss = s % 60;
    return `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  }

  function normalizeNumericInput(v) {
    return String(v ?? "").trim().replace(",", ".");
  }

  function renderTrendBars({ wrapEl, deltaEl, attemptsNewestFirst, barClass, lastClass }) {
  if (!wrapEl) return;

  const list = Array.isArray(attemptsNewestFirst) ? attemptsNewestFirst : [];
  if (list.length < 2) {
    if (wrapEl) wrapEl.innerHTML = "";
    if (deltaEl) deltaEl.textContent = "";
    // hide container (parent card section)
    const root = wrapEl.closest(".practice-micro, .tours-micro");
    if (root) root.style.display = "none";
    return;
  }

  const root = wrapEl.closest(".practice-micro, .tours-micro");
  if (root) root.style.display = "block";

  // delta between newest and previous
  const a0 = Number(list[0]?.percent) || 0;
  const a1 = Number(list[1]?.percent) || 0;
  const d = a0 - a1;
  const sign = d > 0 ? "+" : d < 0 ? "−" : "";
  const abs = Math.abs(d);
  const txt = sign ? `${sign}${abs.toFixed(1)}%` : `0.0%`;

  if (deltaEl) {
    deltaEl.textContent = txt;
    deltaEl.classList.remove("is-pos", "is-neg");
    if (d > 0) deltaEl.classList.add("is-pos");
    if (d < 0) deltaEl.classList.add("is-neg");
  }

  // bars: oldest -> newest, up to 5
  const seq = list.slice(0, 5).slice().reverse(); // oldest-first
  wrapEl.innerHTML = "";

  seq.forEach((a, idx) => {
    const p = Math.max(0, Math.min(100, Number(a.percent) || 0));
    const h = 6 + Math.round((p / 100) * 16);

    const b = document.createElement("div");
    b.className = barClass + (idx === seq.length - 1 ? ` ${lastClass}` : "");
    b.style.height = `${h}px`;
    b.title = `${p}%`;
    wrapEl.appendChild(b);
  });
}
   
   // ---- Practice history render (inject into practice-start) ----
  function renderPracticeStart() {
    const subjectKey = state.courses.subjectKey;
    const subj = subjectByKey(subjectKey);

    // --- Subject title in hero card ---
    const titleEl = $("#practice-subject-title");
    if (titleEl) titleEl.textContent = subj?.title || subjectKey || "—";

    const h = loadPracticeHistory(subjectKey);
    const best = h?.best || null;
    const last = Array.isArray(h?.last) ? h.last : [];

    const bestScoreEl = $("#practice-best-score");
    const bestPctEl = $("#practice-best-percent");
    const bestTimeEl = $("#practice-best-time");

    const formatSecShort = (sec) => {
      const s = Number(sec);
      if (!Number.isFinite(s) || s < 0) return "—";
      if (s < 60) return `${s}${t("practice_time_sec_suffix")}`;
      const m = Math.floor(s / 60);
      const r = s % 60;
      return `${m}${t("practice_time_min_suffix")} ${r}${t("practice_time_sec_suffix")}`;
    };

    if (best) {
      if (bestScoreEl) bestScoreEl.textContent = `${best.score}/${best.total}`;
      if (bestPctEl) bestPctEl.textContent = `(${best.percent}%)`;
      if (bestTimeEl) bestTimeEl.textContent = formatSecShort(best.durationSec);
    } else {
      if (bestScoreEl) bestScoreEl.textContent = "—";
      if (bestPctEl) bestPctEl.textContent = "";
      if (bestTimeEl) bestTimeEl.textContent = "—";
    }

    // --- Last attempts table (up to 5) ---
    const tbody = $("#practice-last-tbody");
    const emptyEl = $("#practice-last-empty");
    if (tbody) tbody.innerHTML = "";

    const rows = last.slice(0, 5);
    
    if (!rows.length) {
      if (emptyEl) emptyEl.style.display = "block";
      return;
    }

    if (emptyEl) emptyEl.style.display = "none";

    const pctClass = (p) => {
      const n = Number(p);
      if (!Number.isFinite(n)) return "pct-med";
      if (n < 40) return "pct-low";
      if (n < 70) return "pct-med";
      return "pct-high";
    };

    rows.forEach(a => {
      const tr = document.createElement("tr");

      const dt = formatDateTime(a.ts);
      const dateMain = dt.split(",")[0] || dt;
      const dateSub = dt.includes(",") ? dt.split(",").slice(1).join(",").trim() : "";

      tr.innerHTML = `
        <td>
          <div class="practice-date">
            <div class="practice-date-main">${escapeHTML(dateMain)}</div>
            ${dateSub ? `<div class="practice-date-sub">${escapeHTML(dateSub)}</div>` : ""}
          </div>
        </td>
        <td>
          <div class="practice-score">
            <span class="practice-score-main">${escapeHTML(`${a.score}/${a.total}`)}</span>
            <span class="pct-badge ${pctClass(a.percent)}">${escapeHTML(`${a.percent}%`)}</span>
          </div>
        </td>
        <td class="practice-time">${escapeHTML(formatSecShort(a.durationSec))}</td>
      `;

      if (tbody) tbody.appendChild(tr);
    });
     // Trend (>=2 attempts): bars + delta like screenshot
      renderTrendBars({
        wrapEl: document.getElementById("practice-micro-bars"),
        deltaEl: document.getElementById("practice-micro-delta"),
        attemptsNewestFirst: last,         // last is newest-first
        barClass: "practice-micro-bar",
        lastClass: "is-last"
      });
  }
           // ---------------------------
  // Tours loading overlay helpers
  // ---------------------------
  function showToursLoading() {
    const el = document.getElementById("tours-loading");
    if (!el) return;
    el.classList.remove("hidden");
  }

  function hideToursLoading() {
    const el = document.getElementById("tours-loading");
    if (!el) return;
    el.classList.add("hidden");
  }

     async function renderToursStart() {
  showToursLoading();
  try {
    const profile = loadProfile?.() || null;
    const subjectKey = state.courses?.subjectKey || null;
    const subj = subjectByKey(subjectKey);

    // subject title
    const titleEl = document.getElementById("tours-subject-title");
    if (titleEl) titleEl.textContent = subj ? subj.title : "Subject";

    // --------------------------------------
// Active tour by DB dates (no selection)
// --------------------------------------
const tourLabelEl = document.getElementById("tours-tour-label");
const statusTitle = document.getElementById("tours-status-title");
const statusDesc = document.getElementById("tours-status-desc");
const openBtn = document.getElementById("tours-open-btn");

// ✅ local i18n helper: if translation missing, show fallback (not the key)
const tr = (key, fallback) => {
  const v = (typeof t === "function") ? t(key) : key;
  return (v && v !== key) ? v : fallback;
};

// eligibility stays exactly as you had
const eligibility = (typeof canOpenActiveTours === "function")
  ? canOpenActiveTours(profile, subjectKey)
  : { ok: true };

// resolve subject_id
let subjectId = null;

// 1) Try existing helper (if it works — great)
try {
  subjectId = await getSubjectIdByKey(subjectKey);
} catch {}

// 2) Fallback: resolve subjectId directly from DB by subject_key (most reliable)
if (!subjectId && window.sb && subjectKey) {
  try {
    const { data: srow, error: serr } = await window.sb
      .from("subjects")
      .select("id")
      .eq("subject_key", String(subjectKey))
      .maybeSingle();

    if (!serr && srow?.id) subjectId = srow.id;
  } catch {}
}

// load tours for this subject
const todayISO = new Date().toISOString().slice(0, 10);

// UI: show loading first to avoid 1-sec "wrong screen" flicker
if (statusTitle) statusTitle.textContent = tr("loading", "Загрузка…");
if (statusDesc) statusDesc.textContent = tr("loading_desc", "Получаем список туров…");
if (openBtn) openBtn.classList.add("hidden");

// NULL dates = no restriction (ok for test)
const isInWindow = (row) => {
  const sd = row?.start_date ? String(row.start_date) : null;
  const ed = row?.end_date ? String(row.end_date) : null;
  const afterStart = !sd || sd <= todayISO;
  const beforeEnd = !ed || ed >= todayISO;
  return afterStart && beforeEnd;
};

let dbTours = [];
let toursErr = null;

// 1) Prefer join by subject_key (so we don't зависим от subjectId)
if (window.sb && subjectKey) {
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id, subject_id, tour_no, start_date, end_date, is_active, subjects!inner(subject_key)")
      .eq("subjects.subject_key", String(subjectKey))
      .order("tour_no", { ascending: true });

    if (error) toursErr = error;
    if (!error && Array.isArray(data)) {
      dbTours = data;

      // backfill subjectId for any later logic that still wants it
      if (!subjectId && dbTours.length && dbTours[0]?.subject_id) {
        subjectId = dbTours[0].subject_id;
      }
    }
  } catch (e) {
    toursErr = e;
  }
}

// 2) Fallback: by subject_id (if join is blocked by policy)
if (!dbTours.length && window.sb && subjectId) {
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id, subject_id, tour_no, start_date, end_date, is_active")
      .eq("subject_id", subjectId)
      .order("tour_no", { ascending: true });

    if (error) toursErr = toursErr || error;
    if (!error && Array.isArray(data)) dbTours = data;
  } catch (e) {
    toursErr = toursErr || e;
  }
}

// pick active tour: is_active=true AND date window contains today
const activeTours = dbTours.filter(r => !!r.is_active && isInWindow(r));
const activeTour = activeTours.length ? activeTours[0] : null;

// save active tour context for start button / quiz
if (!state.courses) state.courses = {};
state.courses.activeTourId = activeTour?.id || null;
state.courses.activeTourNo = activeTour?.tour_no || null;

// label
if (tourLabelEl) {
  tourLabelEl.textContent = activeTour
    ? `${t("tours_tour_label")} ${activeTour.tour_no}`
    : (t("tours_unavailable_title") || "Туры пока недоступны");
}

   // Status + Open button (DB)
   if (!activeTour) {
     if (statusTitle) statusTitle.textContent = t("tours_unavailable_title") || "Туры пока недоступны";

     // если есть ошибка чтения туров — показываем человеческий текст (а не “как будто туров нет”)
     const baseDesc = t("tours_unavailable_desc") || "Даты и список туров появятся здесь после публикации.";
     const errHint = toursErr ? " (нет доступа к базе туров)" : "";
     if (statusDesc) statusDesc.textContent = baseDesc + errHint;

     if (openBtn) openBtn.classList.add("hidden");
      } else {
     const sd = activeTour.start_date ? String(activeTour.start_date) : null;
     const ed = activeTour.end_date ? String(activeTour.end_date) : null;
     const dateTxt = (sd || ed) ? `${sd || "—"} → ${ed || "—"}` : "";

     // default: show active info
     if (statusTitle) statusTitle.textContent = tr("tours_active_now", "Активный тур сейчас");
     if (statusDesc) statusDesc.textContent =
       `${tr("tours_tour_label", "Тур")} ${activeTour.tour_no}${dateTxt ? " • " + dateTxt : ""}`;

     // ✅ NEW: if already attempted — show it here and hide "Open tour"
     let alreadyAttempted = false;
     try {
       const uid = await getAuthUid();
       if (uid && typeof hasTourAttempt === "function" && activeTour?.id) {
         alreadyAttempted = await hasTourAttempt(uid, activeTour.id);
       }
     } catch {}

     if (alreadyAttempted) {
       if (statusTitle) statusTitle.textContent = tr("tour_unavailable_title", "Тур недоступен");
       if (statusDesc) statusDesc.textContent = tr(
         "tour_unavailable_already_attempted",
         "Вы уже завершили этот тур. Повторное прохождение недоступно."
       );

       if (openBtn) {
         openBtn.classList.add("hidden");
         openBtn.style.display = "none";
         openBtn.onclick = null;
       }
     } else {
       if (openBtn) {
         // ✅ show start button for active tour
         openBtn.classList.remove("hidden");
         openBtn.style.display = "";
         openBtn.disabled = false;

         // Button title (fallback if missing in i18n)
         openBtn.textContent = tr("tours_open_btn", "Открыть тур");

         // start flow
         openBtn.onclick = () => openTourRules();
       }
     }
   }
      try { await renderToursHistorySummary(subjectId); } catch {}
     
      saveState();
      } finally {
     hideToursLoading();
   }
  }

 // --------------------------------------
// Completed tours (DB summary by subject)
// Best = max percent, tie-break = min time
// --------------------------------------
async function renderToursHistorySummary(subjectId) {
  const bestScoreEl = document.getElementById("tours-best-score");
  const bestPctEl = document.getElementById("tours-best-percent");
  const bestTimeEl = document.getElementById("tours-best-time");

  const historyCard = document.getElementById("tours-history-card");
  const historyListEl = document.getElementById("tours-history-list");
  const historyEmptyEl = document.getElementById("tours-history-empty");
  const historySubEl = document.getElementById("tours-history-sub");

  const formatSecShort = (sec) => {
    const s = Number(sec);
    if (!Number.isFinite(s) || s < 0) return "—";
    if (s < 60) return `${s}${t("practice_time_sec_suffix")}`;
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${m}${t("practice_time_min_suffix")} ${r}${t("practice_time_sec_suffix")}`;
  };

  let attempts = [];
  try {
    const uid = await getAuthUid();
    if (window.sb && uid && subjectId) {
      const { data, error } = await window.sb
        .from("tour_attempts")
        .select("id, tour_id, score, percent, total_time, created_at, tours!inner(tour_no, subject_id)")
        .eq("user_id", uid)
        .eq("tours.subject_id", subjectId)
        .order("created_at", { ascending: false });

      if (!error && Array.isArray(data)) attempts = data;
    }
  } catch {}

  // Group best attempt per tour_no (although now it's usually 1 attempt)
  const byTour = new Map();
  for (const a of attempts) {
    const tourNo = Number(a?.tours?.tour_no);
    if (!Number.isFinite(tourNo)) continue;

    const prev = byTour.get(tourNo) || null;
    if (!prev) {
      byTour.set(tourNo, a);
      continue;
    }

    const ap = Number(a?.percent || 0);
    const pp = Number(prev?.percent || 0);
    const at = Number(a?.total_time || 1e9);
    const pt = Number(prev?.total_time || 1e9);

    if (ap > pp) byTour.set(tourNo, a);
    else if (ap === pp && at < pt) byTour.set(tourNo, a);
  }

  const rows = Array.from(byTour.entries())
    .sort((x, y) => x[0] - y[0])
    .map(([tourNo, a]) => ({ tourNo, a }));

  // Best across ALL completed tours for this subject
  let best = null;
  for (const { a } of rows) {
    if (!best) { best = a; continue; }
    const ap = Number(a?.percent || 0);
    const bp = Number(best?.percent || 0);
    const at = Number(a?.total_time || 1e9);
    const bt = Number(best?.total_time || 1e9);
    if (ap > bp) best = a;
    else if (ap === bp && at < bt) best = a;
  }

  // Fill BEST metrics (total questions in tour = 20)
  const TOTAL_TOUR_Q = 20;
  if (best) {
    const score = Number(best?.score ?? 0);
    const pct = Math.round(Number(best?.percent ?? 0));
    const time = Number(best?.total_time ?? 0);

    if (bestScoreEl) bestScoreEl.textContent = `${score}/${TOTAL_TOUR_Q}`;
    if (bestPctEl) bestPctEl.textContent = `(${pct}%)`;
    if (bestTimeEl) bestTimeEl.textContent = formatSecShort(time);
  } else {
    if (bestScoreEl) bestScoreEl.textContent = "—";
    if (bestPctEl) bestPctEl.textContent = "";
    if (bestTimeEl) bestTimeEl.textContent = "—";
  }

  // Render completed list
  if (historyCard) historyCard.style.display = "";
  if (historyListEl) historyListEl.innerHTML = "";

  if (!rows.length) {
    if (historyEmptyEl) historyEmptyEl.style.display = "";
    if (historySubEl) historySubEl.textContent = "";
  } else {
    if (historyEmptyEl) historyEmptyEl.style.display = "none";
    if (historySubEl) historySubEl.textContent =
      (typeof t === "function" && t("tours_completed_sub", { n: rows.length }) !== "tours_completed_sub")
        ? t("tours_completed_sub", { n: rows.length })
        : `Всего: ${rows.length}`;

    for (const { tourNo, a } of rows) {
      const score = Number(a?.score ?? 0);
      const pct = Math.round(Number(a?.percent ?? 0));
      const time = Number(a?.total_time ?? 0);

      const rowEl = document.createElement("div");
      rowEl.className = "tours-history-row";
      rowEl.innerHTML = `
        <div class="tours-history-left">
          <div class="tours-history-tour">${t("tours_tour_label")} ${tourNo}</div>
          <div class="tours-history-meta">${pct}%</div>
        </div>
        <div class="tours-history-right">
          <div class="tours-history-score">${score}/${TOTAL_TOUR_Q}</div>
          <div class="tours-history-time">${formatSecShort(time)}</div>
        </div>
      `;
      if (historyListEl) historyListEl.appendChild(rowEl);
    }
  }

  // Trend bars (based on completed tours list)
  try {
    const trendWrap = document.getElementById("tours-micro-bars");
    const trendDelta = document.getElementById("tours-micro-delta");
    const trendBox = document.getElementById("tours-trend");

    const trendAttemptsNewestFirst = rows
      .slice()
      .sort((a, b) => a.tourNo - b.tourNo)
      .map(x => ({ percent: Number(x.a?.percent ?? 0) }))
      .reverse();

    if (trendAttemptsNewestFirst.length >= 2) {
      if (trendBox) trendBox.style.display = "";
      renderTrendBars({
        wrapEl: trendWrap,
        deltaEl: trendDelta,
        attemptsNewestFirst: trendAttemptsNewestFirst,
        barClass: "tours-micro-bar",
        lastClass: "is-last"
      });
    } else {
      if (trendBox) trendBox.style.display = "none";
    }
  } catch {}
}

  // ---- Practice timer (per-question) ----
  function stopPracticeQuestionTimer() {
    if (state.quiz?.qTimerId) {
      clearInterval(state.quiz.qTimerId);
      state.quiz.qTimerId = null;
    }
  }

  function startPracticeQuestionTimer() {
    stopPracticeQuestionTimer();

    const timerEl = $("#practice-timer");
    if (timerEl) timerEl.textContent = formatMMSS(state.quiz.qTimeLeft);

    state.quiz.qTimerId = setInterval(() => {
      if (!state.quiz || state.quiz.paused) return;

      state.quiz.qTimeLeft -= 1;
      if (timerEl) timerEl.textContent = formatMMSS(state.quiz.qTimeLeft);

      if (state.quiz.qTimeLeft <= 0) {
        stopPracticeQuestionTimer();
        handlePracticeSubmit(true);
      }
    }, 1000);
  }

  // ---- Entry point from Subject Hub ----
  function openPracticeStart() {
  const subjectKey = state.courses.subjectKey;

  // Always open Practice Start screen first (premium UX)
  pushCourses("practice-start");
  renderPracticeStart();

  // If paused draft exists — show Resume button
  const draft = loadPracticeDraft();
  const resumeBtn = $("#practice-resume-btn");
  const restartBtn = $("#practice-restart-btn");

  const canResume = !!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz);

   if (resumeBtn) resumeBtn.style.display = canResume ? "block" : "none";
  if (restartBtn) restartBtn.textContent = canResume ? t("practice_restart") : t("practice_start");

  if (canResume) {
    showToast(t("practice_resume_prompt"));
  }
}

async function startPracticeNew() {
  const subjectKey = state.courses.subjectKey;

  // DB-first questions (may fallback to local automatically)
  const questions = await buildPracticeSet(subjectKey);

  state.quizLock = "practice";
  state.quiz = {
    mode: "practice",
    subjectKey,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,

    index: 0,
    questions,
    answers: Array.from({ length: questions.length }).map(() => null),
    correct: Array.from({ length: questions.length }).map(() => false),

    qTimeLeft: PRACTICE_CONFIG.timeByDifficulty[questions[0]?.difficulty] || 60,
    qTimerId: null
  };

  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
}

  // ---- Rendering question (MCQ or INPUT) ----
  function renderPracticeQuiz() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    if (!q) return;

    const qno = $("#practice-qno");
    const qtext = $("#practice-question");
    const wrap = $("#practice-options");
    const timerEl = $("#practice-timer");

    if (qno) qno.textContent = `${quiz.index + 1}/${PRACTICE_CONFIG.total}`;
    if (timerEl) timerEl.textContent = formatMMSS(quiz.qTimeLeft);
    if (qtext) qtext.textContent = q.question || "Вопрос…";
    if (!wrap) return;

    wrap.innerHTML = "";

    // Difficulty hint (small)
    const diff = document.createElement("div");
    diff.className = "muted small";
    diff.style.marginBottom = "8px";
    diff.textContent = `Сложность: ${q.difficulty}`;
    wrap.appendChild(diff);

    if (q.type === "mcq") {
      const selectedIndex = quiz.answers[quiz.index];

      (q.options || []).forEach((optText, idx) => {
        const row = document.createElement("label");
        row.className = "option";
        row.innerHTML = `
          <input type="radio" name="practice-opt" value="${idx}">
          <span>${escapeHTML(optText)}</span>
        `;
        const input = row.querySelector('input[type="radio"]');
        if (input && selectedIndex === idx) input.checked = true;

        input?.addEventListener("change", () => {
          quiz.answers[quiz.index] = idx;
          saveState();
          updatePracticeSubmitEnabled();
        });

        wrap.appendChild(row);
      });

      return;
    }

    // INPUT
    const box = document.createElement("div");
    box.className = "input-wrap";
    box.innerHTML = `
      <div class="muted small">${escapeHTML(q.inputHint || "")}</div>
      <input id="practice-input" class="text-input" type="text" placeholder="${escapeHTML(q.inputHint || "")}">
      <div id="practice-input-error" class="muted small" style="margin-top:6px; display:none;"></div>
    `;
    wrap.appendChild(box);

    const inputEl = $("#practice-input");
    const errEl = $("#practice-input-error");
    const prev = quiz.answers[quiz.index];
    if (inputEl && typeof prev === "string") inputEl.value = prev;

    inputEl?.addEventListener("input", () => {
      quiz.answers[quiz.index] = inputEl.value;
      saveState();
      updatePracticeSubmitEnabled();
      if (errEl) errEl.style.display = "none";
    });
     updatePracticeSubmitEnabled();
  }

   function updatePracticeSubmitEnabled() {
  const quiz = state.quiz;
  const btn = $("#practice-submit-btn");
  if (!btn || !quiz || quiz.mode !== "practice") return;

  const q = quiz.questions[quiz.index];
  const ua = quiz.answers[quiz.index];

  let ok = false;

  if (q.type === "mcq") {
    ok = (ua !== null && ua !== undefined);
  } else {
    ok = isValidInputAnswer(q, String(ua ?? "").trim());
  }

  btn.disabled = !ok;
}

  // ---- Pause / Submit / Finish ----
  function handlePracticePause() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    stopPracticeQuestionTimer();

    // mark paused time
    quiz.paused = true;
    quiz.pauseStartedAt = Date.now();

    // store snapshot to draft (so even refresh won't kill it)
    savePracticeDraft({
      status: "paused",
      subjectKey: quiz.subjectKey,
      pausedAt: Date.now(),
      quiz
    });

    // unlock UI navigation
    state.quizLock = null;
    state.quiz = null;
    saveState();

    showToast(t("practice_paused"));
    replaceCourses("subject-hub");
    renderSubjectHub();
  }

  function handlePracticeSubmit(isAutoTimeout = false) {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    const userAns = quiz.answers[quiz.index];

    // Validate: must have answer if manual submit
    if (!isAutoTimeout) {
      if (q.type === "mcq") {
        if (userAns === null || userAns === undefined) {
          showToast("Выберите вариант ответа");
          return;
        }
      } else {
        const val = String(userAns ?? "").trim();
        if (!isValidInputAnswer(q, val)) {
          const errEl = $("#practice-input-error");
          if (errEl) {
            errEl.textContent = "Проверьте формат ответа";
            errEl.style.display = "block";
          } else {
            showToast("Проверьте формат ответа");
          }
          return;
        }
      }
    }

    // Evaluate correctness
    let isCorrect = false;

    if (q.type === "mcq") {
      const idx = (userAns === null || userAns === undefined) ? null : Number(userAns);
      if (idx !== null && idx === Number(q.correctIndex)) isCorrect = true;
    } else {
      const raw = String(userAns ?? "").trim();
      if (raw) {
        if (q.inputKind === "numeric") {
          const u = normalizeNumericInput(raw);
          const c = normalizeNumericInput(q.correctAnswer);
          isCorrect = (u === c);
        } else {
          isCorrect = (raw.toLowerCase() === String(q.correctAnswer || "").trim().toLowerCase());
        }
      }
    }

    quiz.correct[quiz.index] = isCorrect;

    if (isAutoTimeout) {
      showToast(userAns ? t("toast_time_expired_answer_saved") : t("toast_time_expired_no_answer"));
    }

  // ---- time_spent per question (seconds) ----
  // We store: time_allowed - time_left at the moment of submit/timeout.
  const allowed = Number(PRACTICE_CONFIG.timeByDifficulty[q.difficulty]) || 60;
  const left = Number(quiz.qTimeLeft) || 0;

  if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
  quiz.timeSpent[quiz.index] = Math.max(0, Math.min(allowed, allowed - left));

  // Next question or finish
  stopPracticeQuestionTimer();

  const nextIndex = quiz.index + 1;

    if (nextIndex >= quiz.questions.length) {
      finishPractice();
      return;
    }

    quiz.index = nextIndex;
    const nextQ = quiz.questions[quiz.index];
    quiz.qTimeLeft = PRACTICE_CONFIG.timeByDifficulty[nextQ.difficulty] || 60;

    saveState();
    renderPracticeQuiz();
    startPracticeQuestionTimer();
  }

  function finishPractice() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    stopPracticeQuestionTimer();

    // duration excluding pauses
    const finishedAt = Date.now();
    const startedAt = quiz.startedAt || finishedAt;
    const durationMs = Math.max(0, finishedAt - startedAt - (quiz.pausedTotalMs || 0));
    const durationSec = Math.round(durationMs / 1000);

    const total = quiz.questions.length;
    const score = quiz.correct.filter(Boolean).length;
    const percent = Math.round((score / total) * 100);

    // Build details for review/recs
     if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
    const details = quiz.questions.map((q, i) => {
      const ua = quiz.answers[i];
      let correctDisplay = "";
      let userDisplay = "";

      if (q.type === "mcq") {
        correctDisplay = (q.options && q.options[q.correctIndex] != null) ? q.options[q.correctIndex] : String(q.correctIndex);
        userDisplay = (ua === null || ua === undefined)
          ? ""
          : ((q.options && q.options[Number(ua)] != null) ? q.options[Number(ua)] : String(ua));
      } else {
        correctDisplay = String(q.correctAnswer ?? "");
        userDisplay = String(ua ?? "").trim();
      }

   return {
     id: q.id,
     topic: q.topic || "General",
     difficulty: q.difficulty,
     type: q.type,
     question: q.question,
     userAnswer: userDisplay,
     correctAnswer: correctDisplay,
     isCorrect: !!quiz.correct[i],
     timeSpent: Number(quiz.timeSpent[i]) || 0,
     explanation: q.explanation || ""
   };
 });

    const attempt = {
      ts: finishedAt,
      subjectKey: quiz.subjectKey,
      score,
      total,
      percent,
      durationSec,
      details
    };

    // ---------------------------
    // Earned Credentials — events + realtime evaluation
    // ---------------------------
    const subject_id = normSubjectId(attempt.subjectKey);
    const attempt_key = String(attempt.ts || finishedAt);

    const ev = trackEvent("practice_attempt_finished", {
  subject_id,
  score: attempt.score,
  percent: attempt.percent,
  time_seconds: attempt.durationSec,
  attempt_key
});

// Keep last attempt in state for result/review/recs screens (DO NOT lose db info)
state.practiceLastAttempt = { ...(attempt || {}), db: (state.practiceLastAttempt && state.practiceLastAttempt.db) ? state.practiceLastAttempt.db : null };

// ✅ DB-first: save attempt + answers to Supabase (non-blocking UX)
(async () => {
  // DEBUG 1: we entered DB save branch
  try {
    trackEvent("practice_db_save_started", {
      subject_key: quiz?.subjectKey || null,
      attempt_key,
      score: attempt?.score ?? null,
      percent: attempt?.percent ?? null
    });
  } catch {}

  try {
    const res = await savePracticeAttemptToSupabase(attempt, quiz);

    // DEBUG 2: DB save result
    try {
      trackEvent("practice_db_save_result", {
        ok: !!res?.ok,
        reason: res?.reason || null,
        attempt_id: res?.attemptId ?? null,
        subject_id_db: res?.subjectId ?? null,
        subject_key: quiz?.subjectKey || null,
        attempt_key
      });
    } catch {}

    // merge db result into current attempt without overwriting the attempt object
    state.practiceLastAttempt = { ...(state.practiceLastAttempt || attempt || {}), db: res };

  } catch (e) {
    // DEBUG 3: crash (must show in app_events no matter what)
    try {
      trackEvent("practice_db_save_crash", {
        message: String(e?.message || e || "unknown"),
        subject_key: quiz?.subjectKey || null,
        attempt_key
      });
    } catch {}

    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "savePracticeAttemptToSupabase_crash", e, { attempt_key, subject_key: quiz?.subjectKey || null });
    } catch {}
  }
})();

    // Clear paused draft if any
    clearPracticeDraft();

    // Unlock
    state.quizLock = null;
    state.quiz = null;
    saveState();

    // Render result
    const meta = $("#practice-result-meta");

const wrong = attempt.details.filter(d => !d.isCorrect);
const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));

if (meta) {
  meta.textContent =
    `Score: ${attempt.score}/${attempt.total} (${attempt.percent}%) • ${attempt.durationSec}s` +
    ` • ${t("practice_errors")}: ${wrong.length}` +
    ` • ${t("practice_topics")}: ${topics.length}`;
}

      // Counters on buttons
   const reviewCountEl = $("#practice-review-count");
   if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

   const recsCountEl = $("#practice-recs-count");
   if (recsCountEl) recsCountEl.textContent = String(topics.length);

      // Show result screen (replace quiz screen to avoid "dead" back navigation)
   replaceCourses("practice-result");

      // Save best + last 5 (safe)
   let hx = null;
      try {
        hx = updatePracticeHistory(quiz.subjectKey, attempt);
      } catch (e) {
      try { trackEvent("practice_history_error", { message: String(e?.message || e || "unknown") }); } catch {}
      }

      // Optional: toast best update
      if (hx && hx.best && hx.best.ts === attempt.ts) {
        showToast("Новый лучший результат");
      }
   syncPracticeResultBadges();
  }

function renderPracticeReview() {
  const wrap = $("#practice-review-list");
  if (!wrap) return;

  const attempt = state.practiceLastAttempt;

  // Earned Credentials — review opened (for Error-Driven cycle)
  if (attempt && attempt.ts) {
    const subject_id = attempt.subjectKey ? String(attempt.subjectKey) : "";
    const attempt_key = String(attempt.ts);
    const ev = trackEvent("practice_review_opened", { subject_id, attempt_key });
    onPracticeReviewOpened(attempt_key, ev?.id);
  }

  // Helper: render from "details" array in one place
  const renderFromDetails = (details) => {
    if (!Array.isArray(details) || !details.length) {
      wrap.innerHTML = `<div class="empty muted">Нет данных для разбора. Сначала пройдите практику.</div>`;
      return;
    }

    // Group by topic
    const byTopic = new Map();
    details.forEach((d, idx) => {
      const topic = d.topic || "General";
      if (!byTopic.has(topic)) byTopic.set(topic, []);
      byTopic.get(topic).push({ ...d, _idx: idx });
    });

    // Sort topics: topics with more wrong first, then alphabetically
    const topics = Array.from(byTopic.keys()).sort((a, b) => {
      const wa = byTopic.get(a).filter(x => !x.isCorrect).length;
      const wb = byTopic.get(b).filter(x => !x.isCorrect).length;
      if (wb !== wa) return wb - wa;
      return String(a).localeCompare(String(b));
    });

    wrap.innerHTML = "";

    topics.forEach((topic, tIndex) => {
      const items = byTopic.get(topic);
      const wrongCount = items.filter(x => !x.isCorrect).length;
      const totalCount = items.length;

      const block = document.createElement("div");
      block.className = "card";
      block.style.marginBottom = "10px";

      const head = document.createElement("button");
      head.type = "button";
      head.className = "btn";
      head.style.width = "100%";
      head.style.display = "flex";
      head.style.justifyContent = "space-between";
      head.style.alignItems = "center";
      head.style.gap = "10px";
      head.style.padding = "12px 12px";
      head.style.borderRadius = "16px";

      const left = document.createElement("div");
      left.style.textAlign = "left";
      left.innerHTML = `
        <div style="font-weight:900">${escapeHTML(topic)}</div>
        <div class="muted small">Вопросов: ${totalCount} • Ошибок: ${wrongCount}</div>
      `;

      const right = document.createElement("div");
      right.className = "badge badge-pin";
      right.textContent = wrongCount ? `❌ ${wrongCount}` : `✅ 0`;

      head.appendChild(left);
      head.appendChild(right);

      const body = document.createElement("div");
      body.style.marginTop = "10px";
      body.style.display = (tIndex === 0) ? "block" : "none"; // первая тема раскрыта
      body.dataset.open = (tIndex === 0) ? "1" : "0";

      head.addEventListener("click", () => {
        const open = body.dataset.open === "1";
        body.dataset.open = open ? "0" : "1";
        body.style.display = open ? "none" : "block";
      });

      // Render questions inside topic
      items.forEach(d => {
        const row = document.createElement("div");
        row.className = "list-item";
        row.style.marginBottom = "10px";

        const status = d.isCorrect ? "✅" : "❌";
        const n = d._idx + 1;

        row.innerHTML = `
          <div style="font-weight:900">${status} ${n}. ${escapeHTML(d.difficulty)} • ${escapeHTML(d.type)}</div>
          <div class="muted small" style="margin-top:6px">${escapeHTML(d.question || "")}</div>

          <div class="muted small" style="margin-top:8px">
            Ваш ответ: <b>${escapeHTML(d.userAnswer || "—")}</b>
          </div>
          <div class="muted small">
            Правильно: <b>${escapeHTML(d.correctAnswer || "—")}</b>
          </div>

          ${d.explanation ? `<div class="muted small" style="margin-top:8px">${escapeHTML(d.explanation)}</div>` : ``}
        `;

        body.appendChild(row);
      });

      block.appendChild(head);
      block.appendChild(body);
      wrap.appendChild(block);
    });
  };

  // If we have DB attempt id -> DB-first review
  const dbAttemptId = attempt?.db?.ok ? Number(attempt?.db?.attemptId) : null;

  // First paint: loading
  wrap.innerHTML = `<div class="empty muted">Загружаем разбор из базы…</div>`;

  // DB-first flow (best-effort)
  (async () => {
    if (!window.sb || !dbAttemptId) {
      // fallback to local
      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
      return;
    }

    try {
      const uid = await getAuthUid();
      if (!uid) {
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      // 1) read answers for this attempt
      const { data: ansRows, error: ansErr } = await window.sb
        .from("practice_answers")
        .select("question_id,user_answer,is_correct,time_spent,created_at")
        .eq("attempt_id", dbAttemptId)
        .order("id", { ascending: true });

      if (ansErr) {
        try { trackEvent("practice_review_db_error", { where: "answers_select", attempt_id: dbAttemptId }); } catch {}
        await logDbErrorToEvents(uid, "practice_review_answers_select", ansErr, { attempt_id: dbAttemptId });
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      const ids = (ansRows || []).map(r => Number(r.question_id)).filter(n => Number.isFinite(n));
      if (!ids.length) {
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      // 2) read questions
      const { data: qRows, error: qErr } = await window.sb
        .from("questions")
        .select("id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url")
        .in("id", ids)
        .eq("is_active", true);

      if (qErr) {
        try { trackEvent("practice_review_db_error", { where: "questions_select", attempt_id: dbAttemptId }); } catch {}
        await logDbErrorToEvents(uid, "practice_review_questions_select", qErr, { attempt_id: dbAttemptId, ids: ids.length });
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      const qMap = new Map((qRows || []).map(q => [Number(q.id), q]));

      // 3) normalize into the same "details" shape UI expects
      const details = (ansRows || []).map((a) => {
        const q = qMap.get(Number(a.question_id)) || null;

        let type = "mcq";
        if (q?.qtype) type = String(q.qtype);

        let difficulty = q?.difficulty ? String(q.difficulty) : "easy";

        // options_text is stored as text (often JSON array string)
        let options = null;
        if (q && q.options_text) {
          try {
            const parsed = JSON.parse(q.options_text);
            if (Array.isArray(parsed)) options = parsed.map(x => String(x));
          } catch {}
        }

        // userAnswer: store as text, but for mcq your DB stores "0/1/2/3" or "A/B/C"
        const ua = (a.user_answer === null || a.user_answer === undefined) ? "" : String(a.user_answer);

        return {
          id: Number(a.question_id),
          topic: q?.topic || "General",
          subtopic: q?.subtopic || null,
          difficulty,
          type,
          question: q?.question_text || "",
          options,
          userAnswer: ua || "—",
          correctAnswer: (q?.correct_answer === null || q?.correct_answer === undefined) ? "—" : String(q.correct_answer),
          explanation: q?.explanation || "",
          isCorrect: !!a.is_correct,
          timeSpent: Number(a.time_spent) || 0
        };
      });

      // 4) render DB-first
      renderFromDetails(details);

    } catch (e) {
      // fallback
      try { trackEvent("practice_review_db_crash", { message: String(e?.message || e || "unknown"), attempt_id: dbAttemptId || null }); } catch {}
      try {
        const uid = await getAuthUid();
        await logDbErrorToEvents(uid, "practice_review_db_crash", e, { attempt_id: dbAttemptId || null });
      } catch {}

      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
    }
  })();
}

function syncPracticeResultBadges() {
  const attempt = state.practiceLastAttempt;
  if (!attempt || !Array.isArray(attempt.details)) return;

  const wrong = attempt.details.filter(d => !d.isCorrect);
  const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));

  const reviewCountEl = $("#practice-review-count");
  if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

  const recsCountEl = $("#practice-recs-count");
  if (recsCountEl) recsCountEl.textContent = String(topics.length);
}
 
  function renderPracticeRecs() {
    const wrap = $("#practice-recs-list");
    if (!wrap) return;

    const attempt = state.practiceLastAttempt;
    if (!attempt || !Array.isArray(attempt.details)) {
      wrap.innerHTML = `<div class="empty muted">Нет данных для рекомендаций. Сначала пройдите практику.</div>`;
      return;
    }

    // Topics from wrong answers
    const topics = attempt.details
      .filter(d => !d.isCorrect)
      .map(d => d.topic || "General");

    const uniq = Array.from(new Set(topics));

    // Save to "My recommendations" (v1: topics-only)
const res = addMyRecsFromAttempt(attempt);
if (!res.added) {
  // if there are no mistakes -> nothing to save
} else {
  showToast(t("practice_saved_to_my_recs"));
}
     
    if (!uniq.length) {
      wrap.innerHTML = `<div class="empty muted">Ошибок нет — рекомендации не требуются. Неприлично красиво.</div>`;
      return;
    }

    // v1: пока без привязки к книге/страницам — даём структурные “что читать”
    wrap.innerHTML = "";
    uniq.forEach(tp => {
      const item = document.createElement("div");
      item.className = "list-item";
      const refs = getReadingRefs(attempt.subjectKey, tp);

let refsHtml = "";
if (refs.length) {
  refsHtml = `
    <div class="muted small" style="margin-top:6px">
      ${refs.slice(0, 3).map(r =>
        `• ${escapeHTML(r.title || "")}${r.ref ? ` — ${escapeHTML(r.ref)}` : ""}${r.pages ? ` (${escapeHTML(r.pages)})` : ""}`
      ).join("<br>")}
    </div>
  `;
}

item.innerHTML = `
  <div style="font-weight:900">${escapeHTML(tp)}</div>
  <div class="muted small">Рекомендуем повторить теорию и примеры по теме “${escapeHTML(tp)}”.</div>
  ${refsHtml || `<div class="muted small" style="margin-top:6px">Источник: будет добавлен из книги по предмету.</div>`}
  <div style="margin-top:10px">
    <button type="button" class="btn" data-open-books="1">Открыть «Книги»</button>
  </div>
`;

const btn = item.querySelector('button[data-open-books="1"]');
btn?.addEventListener("click", (e) => {
  e.stopPropagation();
  pushCourses("books");
});
      wrap.appendChild(item);
    });
  }

function renderMyRecs() {
  const wrap = $("#my-recs-list");
  if (!wrap) return;

  const subjectKey = state.courses.subjectKey;
  const store = loadMyRecs();
  const list = store?.bySubject?.[subjectKey] || [];

  if (!list.length) {
    wrap.innerHTML = `<div class="empty muted">Пока пусто.</div>`;
    return;
  }

  wrap.innerHTML = "";
  list.forEach(item => {
    const el = document.createElement("div");
    el.className = "list-item";
    el.innerHTML = `
      <div style="font-weight:800">${escapeHTML(item.topic)}</div>
      <div class="muted small">Сохранено: ${escapeHTML(formatDateTime(item.ts))}</div>
    `;
    wrap.appendChild(el);
  });
}
   
    // ---------------------------
  // Tour (strict) — T1+T2+T3 (mock now, DB later)
  // ---------------------------
  const TOUR_CONFIG = {
  total: 20,
  dist: { easy: 6, medium: 9, hard: 5 },
  defaultQuestionTimeSec: 45, // ✅ фоллбек ТОЛЬКО если у вопроса нет своего лимита
  maxViolations: 2,
};

  let tourTick = null;

  function openTourRules() {
    pushCourses("tour-rules");
    const cb = $("#tour-rules-accept");
    if (cb) cb.checked = false;
  }

  // ---------- T3: Data contract ----------
  // UI expects rows in this shape:
  // { id, subject_key, tour_no, difficulty, question_text, options[], correct_index, explanation?, source? }
  function getTourQuestionsMock(subjectKey, tourNo) {
    // 20 вопросов: 6 easy / 9 medium / 5 hard (mock)
    const mk = (i, diff) => ({
      id: `mock_${subjectKey || "subject"}_${tourNo}_${i}`,
      subject_key: subjectKey || "subject",
      tour_no: tourNo || 1,
      difficulty: diff,
      question_text: `Which process occurs during the light-dependent stage of photosynthesis? (Q${i})`,
      options: [
        "Photolysis of water molecules",
        "Fixation of carbon dioxide",
        "Production of glucose",
        "Reduction of NADP to NADPH"
      ],
      correct_index: 0,
      explanation: "Light-dependent reactions include photolysis and formation of ATP/NADPH.",
      source: "Uzbekistan Academic Standards"
    });

    const items = [];
    let i = 1;

    for (let k = 0; k < TOUR_CONFIG.dist.easy; k++) items.push(mk(i++, "easy"));
    for (let k = 0; k < TOUR_CONFIG.dist.medium; k++) items.push(mk(i++, "medium"));
    for (let k = 0; k < TOUR_CONFIG.dist.hard; k++) items.push(mk(i++, "hard"));

    // маленькая перемешка (стабильная)
    return shuffleArrayStable(items, `${subjectKey || "s"}_${tourNo || 1}`);
  }

  function shuffleArrayStable(arr, seedStr) {
    const a = [...arr];
    let seed = 0;
    for (let i = 0; i < seedStr.length; i++) seed = (seed * 31 + seedStr.charCodeAt(i)) >>> 0;
    function rnd() {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return seed / 0xFFFFFFFF;
    }
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

   // ---------------------------
// Tours (DB-first via tour_questions)
// ---------------------------

async function loadActiveTourBySubjectAndNo(subjectId, tourNo) {
  if (!window.sb || !subjectId || !tourNo) return null;

  const { data, error } = await window.sb
    .from("tours")
    .select("id,subject_id,tour_no,start_date,end_date,is_active")
    .eq("subject_id", subjectId)
    .eq("tour_no", tourNo)
    .eq("is_active", true)
    .maybeSingle();

  if (error) return null;
  return data || null;
}

async function loadTourQuestionsDB(tourId) {
  if (!window.sb || !tourId) return null;

  const { data, error } = await window.sb
    .from("tour_questions")
    .select("order_no, question:questions(id,topic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active)")
    .eq("tour_id", tourId)
    .eq("is_active", true)
    .order("order_no", { ascending: true })
    .limit(200);

  if (error) return null;

  const rows = Array.isArray(data) ? data : [];
  const items = rows
    .map(r => r?.question || null)
    .filter(q => q && q.is_active);

  // normalize to Tour UI model (same spirit as practice builder)
  const normalizeDiff = (d) => normalizeDifficulty(d || "easy");
  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  return items.map(q => {
    const type = normalizeType(q.qtype);
    const opts = type === "mcq" ? (parseOptionsText(q.options_text) || []) : null;

    // correctIndex for mcq:
    // - if correct_answer is numeric index => use it
    // - else try match to option text (case-insensitive)
    let correctIndex = 0;
    if (type === "mcq") {
      const ca = String(q.correct_answer ?? "").trim();
      if (isNumericLike(ca)) {
        correctIndex = Math.max(0, Math.min(opts.length - 1, Number(String(ca).replace(",", "."))));
      } else if (opts.length) {
        const idx = opts.findIndex(o => String(o).trim().toLowerCase() === ca.toLowerCase());
        if (idx >= 0) correctIndex = idx;
      }
    }

    return {
      id: q.id,
      topic: q.topic || "General",
      difficulty: normalizeDiff(q.difficulty),
      type,
      question: q.question_text,
      options: opts,
      correctIndex,
      correctAnswer: String(q.correct_answer ?? ""),
      explanation: q.explanation || "",
      image_url: q.image_url || null
    };
  });
}

async function hasTourAttempt(uid, tourId) {
  if (!window.sb || !uid || !tourId) return false;
  const { data, error } = await window.sb
    .from("tour_attempts")
    .select("id")
    .eq("user_id", uid)
    .eq("tour_id", tourId)
    .limit(1);

  if (error) return false;
  return Array.isArray(data) && data.length > 0;
}

async function createTourAttempt(uid, tourId) {
  if (!window.sb || !uid || !tourId) return null;

  const { data, error } = await window.sb
    .from("tour_attempts")
    .insert([{ user_id: uid, tour_id: tourId, score: 0, percent: 0, total_time: 0, status: "submitted" }])
    .select("id")
    .single();

  if (error) return null;
  return data?.id ?? null;
}

async function upsertTourAnswer(attemptId, questionId, patch) {
  if (!window.sb || !attemptId || !questionId) return;

  // Upsert by (attempt_id, question_id) requires a unique constraint in DB.
  // If you don't have it yet, we fallback to insert-only and ignore duplicates.
  try {
    await window.sb
      .from("tour_answers")
      .upsert([{
        attempt_id: attemptId,
        question_id: questionId,
        user_answer: patch.user_answer ?? null,
        answered: !!patch.answered,
        is_correct: !!patch.is_correct,
        time_spent: Number(patch.time_spent || 0),
        finish_reason: patch.finish_reason ?? null
      }], { onConflict: "attempt_id,question_id" });
  } catch {
    try {
      await window.sb
        .from("tour_answers")
        .insert([{
          attempt_id: attemptId,
          question_id: questionId,
          user_answer: patch.user_answer ?? null,
          answered: !!patch.answered,
          is_correct: !!patch.is_correct,
          time_spent: Number(patch.time_spent || 0),
          finish_reason: patch.finish_reason ?? null
        }]);
    } catch {}
  }
}

async function updateTourAttempt(attemptId, patch) {
  if (!window.sb || !attemptId) return;
  try {
    await window.sb
      .from("tour_attempts")
      .update({
        score: Number(patch.score || 0),
        percent: Number(patch.percent || 0),
        total_time: Number(patch.total_time || 0),
        status: String(patch.status || "submitted")
      })
      .eq("id", attemptId);
  } catch {}
}

  function initTourSession({ subjectKey = null, tourNo = 1, tourId = null, attemptId = null, questions = [], isArchive = false } = {}) {
  state.tourContext = {
    isArchive,
    subjectKey,
    tourNo,
    tourId,        // ✅ DB tour id
    attemptId,     // ✅ DB attempt id (null for archive)
    questions,     // ✅ loaded from DB mapping tour_questions
    startedAt: Date.now(),
    qStartedAt: Date.now(),
    index: 0,
    correct: 0,
    answers: [],   // {qid, pickedIndex, userAnswer, isCorrect, spentSec}
    violations: 0,
    lastViolationAt: null,
    questionTimeLimit: TOUR_CONFIG.defaultQuestionTimeSec
  };

  // strict lock only for ACTIVE tour
  state.quizLock = isArchive ? null : "tour";
  saveState();
}

  async function openTourQuiz() {
  const accept = $("#tour-rules-accept");
  if (!accept || !accept.checked) {
    showToast(t("tour_rules_accept_required"));
    return;
  }

  const subjectKey = state.courses?.subjectKey || null;
  if (!subjectKey) {
    showToast("Subject not selected");
    return;
  }

  // 1) eligibility: only school students can participate (tours/ratings)
  const uid = await getAuthUid();
  const me = uid ? await getUserProfile(uid) : null;

  if (!me?.is_school_student) {
    await uiAlert({
      title: t("disabled_title") || "Недоступно",
      message: t("tour_disabled_nonstudent") || "Туры доступны только для школьников."
    });
    return;
  }

  // 2) resolve subject_id and active tour (tour_no=1 for now; later from UI selection)
  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    showToast("subject_id not found");
    return;
  }

  const tourNo = 1; // TODO: take selected tour from Tours List
  const tour = await loadActiveTourBySubjectAndNo(subjectId, tourNo);

  if (!tour?.id) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_no_active") || "Нет активного тура для этого предмета."
    });
    return;
  }

  // 3) one attempt rule
  const already = await hasTourAttempt(uid, tour.id);
  if (already) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_already_attempted") || "У вас уже была попытка в этом туре."
    });
    return;
  }

  // 4) load questions by mapping table tour_questions
  const questions = await loadTourQuestionsDB(tour.id);
  if (!questions || questions.length === 0) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_no_questions") || "Для тура не назначены вопросы."
    });
    return;
  }

  // 5) create attempt row
  const attemptId = await createTourAttempt(uid, tour.id);
  if (!attemptId) {
    showToast("Ошибка создания попытки");
    return;
  }

  // analytics: started
  try {
    trackEvent("tour_attempt_started", {
     ts: new Date().toISOString(),
     tour_id: String(tourId),
     subject_id: String(subjectId),
     subject_key: String(subjectKey || "")
   });
  } catch {}

  initTourSession({
    subjectKey,
    tourNo,
    tourId: tour.id,
    attemptId,
    questions,
    isArchive: false
  });

  pushCourses("tour-quiz");
  bindTourAntiCheatOnce();
  startTourTick();
  renderTourQuestion();
}

  function startTourTick() {
    stopTourTick();
    tourTick = setInterval(() => {
      renderTourHUD();

      // auto-finish if violations too many
      if (!state.tourContext?.isArchive && state.tourContext?.violations >= TOUR_CONFIG.maxViolations) {
        stopTourTick();
        finishTour({ reason: "violations" });
      }

      // auto-finish if question time exceeded and no answer chosen (optional behavior)
      const ctx = state.tourContext;
      if (ctx && !ctx.isArchive) {
        const qElapsed = Math.floor((Date.now() - ctx.qStartedAt) / 1000);
        if (qElapsed >= ctx.questionTimeLimit) {
          // if no selection yet, we keep button disabled; auto mark as wrong and go next
          if (!ctx.answers.some(a => a.index === ctx.index)) {
            submitTourAnswer({ pickedIndex: null, auto: true });
          }
        }
      }
    }, 250);
  }

  function stopTourTick() {
    if (tourTick) clearInterval(tourTick);
    tourTick = null;
  }

  // ---------- T2: Anti-cheat ----------
  let antiCheatBound = false;

  function bindTourAntiCheatOnce() {
    if (antiCheatBound) return;
    antiCheatBound = true;

    document.addEventListener("visibilitychange", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;
      if (document.visibilityState !== "visible") registerTourViolation("visibility");
    });

    window.addEventListener("blur", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;
      registerTourViolation("blur");
    });
  }

  function registerTourViolation(type) {
    const ctx = state.tourContext;
    if (!ctx || ctx.isArchive) return;

    // simple debounce: 1 violation per 2s
    const now = Date.now();
    if (ctx.lastViolationAt && (now - ctx.lastViolationAt) < 2000) return;

    ctx.violations += 1;
    ctx.lastViolationAt = now;
    saveState();

    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = "inline-flex";

    const warnPill = $("#tour-anti-cheat"); // legacy id might exist elsewhere
    if (warnPill) warnPill.style.display = "inline-flex";

    showToast(`Warning: session monitoring (${ctx.violations}/${TOUR_CONFIG.maxViolations})`);
  }

  // ---------- Render ----------
  function renderTourHUD() {
    const ctx = state.tourContext;
    if (!ctx) return;

    const total = TOUR_CONFIG.total;
    const qNo = Math.min(total, ctx.index + 1);

    const qof = $("#tour-qof");
    if (qof) qof.textContent = `Question ${qNo} of ${total}`;

    const pct = Math.round((qNo / total) * 100);
    const pctEl = $("#tour-progress-pct");
    if (pctEl) pctEl.textContent = `${pct}%`;

    const fill = $("#tour-progress-fill");
    if (fill) fill.style.width = `${pct}%`;

    const badge = $("#tour-badge");
    if (badge) {
      const subjLabel = String(ctx.subjectKey || "SUBJECT").toUpperCase();
      badge.textContent = `CAMBRIDGE ${subjLabel} • TOUR #${ctx.tourNo}`;
    }

    const overall = formatMsToMMSS(Date.now() - ctx.startedAt);
    const overallEl = $("#tour-overall-time");
    if (overallEl) overallEl.textContent = overall;

    const qElapsed = formatMsToMMSS(Date.now() - ctx.qStartedAt);
    const qEl = $("#tour-question-time");
    if (qEl) qEl.textContent = qElapsed;
     // ✅ last-10-seconds warning on question timer
try {
  const qRow = ctx.questions?.[ctx.index] || null;

  const limitSecRaw =
    qRow?.time_limit_seconds ??
    qRow?.timeLimitSec ??
    TOUR_CONFIG.defaultQuestionTimeSec ??
    45;

  const limitSec = Math.max(1, Number(limitSecRaw) || 45);
  const elapsedSec = Math.max(0, Math.floor((Date.now() - ctx.qStartedAt) / 1000));
  const remainSec = limitSec - elapsedSec;

  const qCard = (qEl && qEl.closest) ? qEl.closest(".tour-timer-card") : null;
  if (qCard) {
    if (remainSec <= 10) qCard.classList.add("danger");
    else qCard.classList.remove("danger");

    if (remainSec <= 5) qCard.classList.add("pulse");
    else qCard.classList.remove("pulse");
  }
} catch {}

    // warning visibility
    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = (!ctx.isArchive && ctx.violations > 0) ? "inline-flex" : "none";
  }

  function renderTourQuestion() {
  const ctx = state.tourContext;
  if (!ctx) return;

  const q = ctx.questions?.[ctx.index];
  if (!q) {
    finishTour({ reason: "done" });
    return;
  }

  ctx.qStartedAt = Date.now();
  // сбрасываем прошлый выбор при показе нового вопроса
  ctx._pickedIndex = null;
  saveState();

  // question text (fallback ids)
  const qEl =
    $("#tour-question") ||
    $("#quiz-question") ||
    $("#tour-question-text");

  if (qEl) {
  const qText =
    (q.question ?? q.question_text ?? q.questionText ?? q.text ?? q.prompt ?? q.title ?? "");
  qEl.textContent = String(qText || "");
}

  // question type normalize (mcq vs input)
  const qTypeRaw = String(q.qtype ?? q.type ?? q.question_type ?? "mcq").toLowerCase();
  const isMcq = (qTypeRaw === "mcq" || qTypeRaw === "choice" || qTypeRaw === "multiple_choice");

  // options wrap (fallback ids/classes)
  const wrap =
    $("#tour-options") ||
    $("#tour-options-wrap") ||
    $("#tour-options-list") ||
    document.querySelector(".tour-options");

  if (wrap) {
    wrap.innerHTML = "";

    if (!isMcq) {
  // input question UI (no HTML edits needed)
  const inputWrap = document.createElement("div");
  inputWrap.className = "input-wrap";

  inputWrap.innerHTML = `
    <label class="input-label">${escapeHTML(t("answer") || "Answer")}</label>
    <input id="tour-input" class="text-input" type="text" placeholder="${escapeHTML(t("type_answer") || "Type your answer")}">
  `;

  wrap.appendChild(inputWrap);

  const inputEl = inputWrap.querySelector("#tour-input");

  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
    nextBtn.disabled = true; // ⛔ пока пусто
    nextBtn.textContent = (ctx.index >= TOUR_CONFIG.total - 1)
      ? "Finish Tour →"
      : "Next Question →";
  }

  // ✅ активируем Next только когда есть ввод
  if (inputEl && nextBtn) {
    inputEl.addEventListener("input", () => {
      nextBtn.disabled = inputEl.value.trim().length === 0;
    });
  }

  renderTourHUD();
  return;
}

    // MCQ options
    const opts = Array.isArray(q.options) && q.options.length
      ? q.options
      : ["Option A", "Option B", "Option C", "Option D"];

    opts.forEach((opt, i) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "option";
      btn.dataset.action = "tour-pick";
      btn.dataset.index = String(i);

      btn.innerHTML = `
        <span class="dot" aria-hidden="true"></span>
        <span class="opt-text">${escapeHTML(opt)}</span>
      `;

      btn.onclick = (ev) => {
        try { ev.preventDefault(); ev.stopPropagation(); } catch {}

        const ctx2 = state.tourContext;
        if (!ctx2) return;

        (wrap.querySelectorAll(".option") || []).forEach(o => o.classList.remove("is-selected"));
        btn.classList.add("is-selected");

        const nextBtn =
          $("#tour-next-btn") ||
          $("#quiz-next-btn") ||
          document.querySelector('[data-action="tour-next"]');

        if (nextBtn) nextBtn.disabled = false;

        ctx2._pickedIndex = i;
        saveState();
      };

      wrap.appendChild(btn);
    });
  }

  // disable next until choose (MCQ only)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
  nextBtn.classList.remove("is-loading"); // <-- добавь
  nextBtn.disabled = true;
  nextBtn.textContent = (ctx.index >= TOUR_CONFIG.total - 1) ? "Finish Tour →" : "Next Question →";
}

  renderTourHUD();
}

    function submitTourAnswer({ pickedIndex, auto = false } = {}) {
    const ctx = state.tourContext;
    if (!ctx) return;

    const q = ctx.questions?.[ctx.index];
    if (!q) return;

    const spentSec = Math.max(0, Math.floor((Date.now() - ctx.qStartedAt) / 1000));

    // normalize correct index (supports both correctIndex and legacy correct_index)
    const correctIdx =
      (q.correctIndex !== undefined && q.correctIndex !== null) ? Number(q.correctIndex)
      : (q.correct_index !== undefined && q.correct_index !== null) ? Number(q.correct_index)
      : null;

        // normalize question type (DB uses qtype, older code may use type)
    const qType =
      (q?.qtype != null ? String(q.qtype) : (q?.type != null ? String(q.type) : "mcq"))
        .toLowerCase();
    const isMcq = (qType === "mcq" || qType === "multiple_choice");

    const pickedNum = (pickedIndex === null || pickedIndex === undefined) ? null : Number(pickedIndex);

    // input value (for non-mcq)
    const inputEl = document.getElementById("tour-input");
    const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

    // expected answer (for input questions)
    const expectedRaw =
      (q?.correct_answer != null ? q.correct_answer
        : (q?.correctAnswer != null ? q.correctAnswer
        : (q?.correct != null ? q.correct
        : (q?.answer != null ? q.answer : null))));

    const expected = (expectedRaw == null) ? "" : String(expectedRaw).trim();

    // correctness
    const isCorrect = isMcq
      ? ((pickedNum !== null && correctIdx !== null) ? (pickedNum === correctIdx) : false)
      : (expected ? (inputVal.toLowerCase() === expected.toLowerCase()) : false);

    ctx.answers = ctx.answers || [];
    ctx.answers.push({
      qid: q.id,
      pickedIndex: pickedNum,
      input: isMcq ? "" : inputVal,
      isCorrect,
      spentSec,
      index: ctx.index
    });

    if (isCorrect) ctx.correct += 1;

    // DB autosave (only for active tour) — fire-and-forget (no await inside non-async fn)
    try {
      const ctx2 = state.tourContext;
      if (ctx2?.attemptId && q?.id && !ctx2?.isArchive) {
        const spentSec2 = Math.max(0, Math.round((Date.now() - (ctx2.qStartedAt || Date.now())) / 1000));
        const pickedForDb = (pickedNum === null ? "" : String(pickedNum));

        // if someday you add input questions, this will safely read it (otherwise empty)
        const inputEl = document.getElementById("tour-input");
        const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

        const answerForDb = isMcq ? pickedForDb : inputVal;

        Promise
          .resolve(upsertTourAnswer(ctx2.attemptId, q.id, {
            user_answer: answerForDb,
            answered: true,
            is_correct: isCorrect,
            time_spent: spentSec2
          }))
          .catch(() => {});
      }
    } catch {}

    // next index
    ctx.index += 1;
    saveState();

    if (ctx.index >= TOUR_CONFIG.total) {
      finishTour({ reason: auto ? "auto_done" : "done" });
      return;
    }

    renderTourQuestion();
  }

   function getTourHistoryKey(subjectKey, tourNo) {
  return `tour_history:${subjectKey || "unknown"}:${tourNo || 1}`;
}

function loadTourHistoryLocal(subjectKey, tourNo) {
  try {
    const raw = localStorage.getItem(getTourHistoryKey(subjectKey, tourNo));
    const arr = raw ? JSON.parse(raw) : [];
    return Array.isArray(arr) ? arr : [];
  } catch {
    return [];
  }
}

function saveTourAttemptLocal(subjectKey, tourNo, attempt) {
  try {
    const key = getTourHistoryKey(subjectKey, tourNo);
    const arr = loadTourHistoryLocal(subjectKey, tourNo);
    arr.unshift(attempt);
    localStorage.setItem(key, JSON.stringify(arr.slice(0, 20)));
  } catch {}
}

  async function finishTour({ reason = "done" } = {}) {
    stopTourTick();

  // UI feedback: saving (prevents “app frozen” feeling)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
    nextBtn.disabled = true;
    nextBtn.classList.add("is-loading");
    nextBtn.textContent = (t("saving") || "Сохранение…");
  }

  const monitor = document.getElementById("tour-monitor");
  if (monitor) monitor.textContent = (t("saving") || "Сохранение…");

  const ctx = state.tourContext;

  // duration/score summary (used for local + DB)
  const durationSec = Math.max(0, Math.round((Date.now() - (ctx?.startedAt || Date.now())) / 1000));
  const total = TOUR_CONFIG.total;
  const score = Number(ctx?.correct || 0);
  const percent = total ? Math.round((score / total) * 100) : 0;

  // Save attempt locally (for stats/trend). Does not affect future DB integration.
  if (ctx?.subjectKey) {
    saveTourAttemptLocal(ctx.subjectKey, ctx.tourNo || 1, {
      ts: Date.now(),
      score,
      total,
      percent,
      durationSec
    });
  }

  // DB finalize (only active tours)
  try {
    if (ctx?.attemptId && !ctx?.isArchive) {
      await updateTourAttempt(ctx.attemptId, {
        score,
        percent,
        total_time: durationSec,
        status:
          (reason === "violations") ? "anti_cheat"
          : (reason === "time_expired") ? "time_expired"
          : "submitted"
      });
    }
  } catch {}

  // result meta
  const meta = $("#tour-result-meta");
  if (meta && ctx) {
    meta.textContent = `Score: ${ctx.correct}/${TOUR_CONFIG.total} • Violations: ${ctx.violations || 0}`;
  }

  if (ctx?.isArchive) {
    showToast("Архивный тур: вне рейтинга");
  } else if (reason === "violations") {
    showToast("Tour finished: session violations");
  }

  // Earned Credentials — tour finished
  try {
    const subject_id = normSubjectId(ctx?.subjectKey || state?.courses?.subjectKey);
    const tour_id = ctx?.tourId != null ? String(ctx.tourId) : "";
    const is_archive = !!ctx?.isArchive;

    trackEvent("tour_attempt_finished", {
     ts,
     status: "done",
     tour_id: String(tourId),
     is_archive: false,
     subject_id: String(subjectId),
     subject_key: String(subjectKey || "")
   });
  } catch {}

  // unlock
  state.quizLock = null;
  state.tourContext = null;
  saveState();

  pushCourses("tour-result");
}

  function formatMsToMMSS(ms) {
    const sec = Math.max(0, Math.floor(ms / 1000));
    const mm = Math.floor(sec / 60);
    const ss = sec % 60;
    return `${mm}:${String(ss).padStart(2, "0")}`;
  }

  // ---------------------------
// Global UI bindings
// ---------------------------
function bindTabbar() {
  let lastTapTs = 0;

  const handle = (btn) => {
    const tab = btn.dataset.tab;
    if (!tab) return;
    
     // ✅ До регистрации табы запрещены (и на registration таббар скрыт, но это страховка)
  const p0 = loadProfile();
  if (!p0) {
    showToast(t("complete_registration_first") || "Сначала завершите регистрацию.");
    showView("registration");
    return;
  }

    // ✅ Ratings доступен только школьникам
    if (tab === "ratings") {
      const p = loadProfile();
      if (!p || !p.is_school_student) {
        showToast(t("disabled_not_school"));
        return;
      }
    }

    if (state.quizLock === "tour") {
      showToast("Tour is in progress");
      return;
    }
    if (state.quizLock === "practice") {
      showToast("Pause practice to leave");
      return;
    }

    // ✅ Требование: кнопка нижнего таба “Courses” всегда открывает All Subjects
    if (tab === "courses") {
      setTab("courses");
      replaceCourses("all-subjects"); // сбрасывает stack + показывает all-subjects
      updateTopbarForView("courses");
      return;
    }

    setTab(tab);
  };

  $$(".tabbar .tab").forEach(btn => {
    // ✅ Mobile-friendly: pointerup работает стабильнее, чем click в WebView
        btn.addEventListener("pointerup", (e) => {
      const now = Date.now();
      if (now - lastTapTs < 250) return; // антидубль
      lastTapTs = now;

      e.preventDefault();
      handle(btn);

      // ✅ убираем “липкий” focus на мобилках
      try { btn.blur(); } catch {}
    });

    // ✅ Desktop fallback
    btn.addEventListener("click", () => {
      handle(btn);
      try { btn.blur(); } catch {}
    });
  });
}

  function bindTopbar() {
    const backBtn = $("#topbar-back");
    if (!backBtn) return;

    backBtn.addEventListener("click", (event) => {
  event.stopPropagation();
  if (state.quizLock) return;

  // ✅ Registration: назад = закрыть апп (возвращаться некуда)
  const regView = document.getElementById("view-registration");
  if (regView && regView.classList.contains("is-active")) {
    if (window.Telegram?.WebApp?.close) window.Telegram.WebApp.close();
    return;
  }

  const topView = state.viewStack?.[state.viewStack.length - 1];

  // If we are on global screen -> go back in global stack
  if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
    globalBack();
    return;
  }

      // ✅ Profile back MUST work even if state.tab accidentally isn't "profile"
const ps = document.getElementById("profile-settings");
const psActive = !!(ps && ps.classList.contains("is-active") && ps.hidden !== true);

// 1) Если реально открыт экран настроек профиля — возвращаем на main напрямую
if (psActive) {
  state.tab = "profile";
  replaceProfile("main");     // stack=["main"] + showProfileScreen("main")
  renderProfileMain();        // чтобы сразу перерисовать
  updateTopbarForView("profile");
  return;
}

// 2) Обычный сценарий профиля
if (state.tab === "profile") {
  popProfile();
  renderProfileStack();
  return;
}



      // If in courses -> pop courses stack
      if (state.tab === "courses") {
        popCourses();
        return;
      }
    });
  }

  function bindRegistration() {
    // ---------------------------
    // Registration language: default from Telegram user language_code
    // ---------------------------
    const langSel = $("#reg-language");
    if (langSel && !langSel.dataset.init) {
      const tgLang = window.Telegram?.WebApp?.initDataUnsafe?.user?.language_code || "";
      const defLang = window.i18n?.normalizeLang ? window.i18n.normalizeLang(tgLang || "ru") : "ru";

      langSel.value = defLang || "ru";
      langSel.dataset.init = "1";

      try { window.i18n?.setLang(langSel.value); } catch {}
      try { applyStaticI18n(); } catch {}
    }
    const isSchool = $("#reg-is-school");
    const isSchoolToggle = $("#reg-is-school-toggle");
    if (isSchool) isSchool.addEventListener("change", updateSchoolFieldsVisibility);
    if (isSchoolToggle) {
      isSchoolToggle.addEventListener("change", updateSchoolFieldsVisibility);
    }
     updateSchoolFieldsVisibility();

    initRegionDistrictUI();
    initRegSubjectChips(); 

    const form = $("#reg-form");
    if (!form) return;

    form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const submitBtn = form.querySelector('button[type="submit"]');
  if (submitBtn) submitBtn.disabled = true;

  try {
    const fullName = $("#reg-fullname")?.value?.trim() || "";
    const lang = $("#reg-language")?.value || "ru";

    let region = "";
    let district = "";

    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");

    if (regionEl && regionEl.value) {
      const regionOpt = regionEl.options[regionEl.selectedIndex];
      region = regionOpt ? regionOpt.textContent.trim() : "";
    }

    if (districtEl && districtEl.value) {
      const districtOpt = districtEl.options[districtEl.selectedIndex];
      district = districtOpt ? districtOpt.textContent.trim() : "";
    }

    const isSchoolStudent = ($("#reg-is-school-toggle")?.checked || $("#reg-is-school")?.value === "yes");
    const school = $("#reg-school")?.value?.trim() || "";
    const klass = $("#reg-class")?.value?.trim() || "";

    const main1 = $("#reg-main-subject-1")?.value || "";
    const main2 = $("#reg-main-subject-2")?.value || "";
    const add1 = $("#reg-additional-subject")?.value || "";

    // district required ONLY when select is enabled and has real options
    const districtRequired =
      !!districtEl &&
      !districtEl.disabled &&
      (districtEl.options?.length || 0) > 1;

    if (!fullName || !region || (districtRequired && !district) || (isSchoolStudent && !main1)) {
      showToast(t("fill_required_fields"));
      return;
    }

    const subjects = [];

    if (isSchoolStudent) {
      subjects.push({
        key: main1,
        mode: "competitive",
        pinned: false
      });

      if (main2 && main2 !== main1) {
        subjects.push({
          key: main2,
          mode: "competitive",
          pinned: false
        });
      }

      if (add1) {
        subjects.push({
          key: add1,
          mode: "study",
          pinned: true
        });
      }
    } else {
      // Non-school users: no subjects during registration.
      // They can study/practice all subjects without tours and manage subjects later in Profile.
    }

    if (subjects.filter(s => s.mode === "competitive").length > 2) {
      showToast(t("competitive_subjects_limit_2"));
      return;
    }

    const tgUser = tg?.initDataUnsafe?.user || {};
    const avatar = tgUser?.photo_url || "";

    const profile = {
      created_at: nowISO(),
      full_name: fullName,
      language: lang,
      is_school_student: isSchoolStudent,
      region,
      district,
      school: isSchoolStudent ? school : "",
      class: isSchoolStudent ? klass : "",
      telegram: {
        id: tgUser?.id || null,
        username: tgUser?.username || null,
        first_name: tgUser?.first_name || null,
        last_name: tgUser?.last_name || null,
        photo_url: avatar || null
      },
      subjects
    };

    // ✅ Stage B: DB-backed registration (users + user_subjects)
    try {
      trackEvent("registration_db_save_started", {
        is_school_student: !!profile.is_school_student,
        subjects_count: Array.isArray(profile.subjects) ? profile.subjects.length : 0
      });
    } catch {}

    const dbRes = await saveRegistrationToSupabase(profile);

    try {
      trackEvent("registration_db_save_result", {
        ok: !!dbRes?.ok,
        reason: dbRes?.reason || null,
        subjects_saved: dbRes?.subjects_saved ?? null
      });
    } catch {}

    if (!dbRes?.ok) {
      showToast("Не удалось сохранить регистрацию в базе. Попробуйте ещё раз.");
      return;
    }

        // keep local profile as UX fallback (DB is source of truth now)
    saveProfile(profile);

    // Уже сохранили в БД выше (dbRes). Повторно НЕ сохраняем, чтобы не ловить ошибки/дубли.
    try {
      trackEvent("registration_db_saved", {
        ok: true,
        reason: null,
        user_subjects_rows: dbRes?.user_subjects_rows ?? null
      });
    } catch {}

      window.i18n?.setLang(lang);
      applyStaticI18n();


    state.tab = "home";
    state.prevTab = "home";
    state.viewStack = ["home"];
    state.courses.stack = ["all-subjects"];
    state.courses.subjectKey = null;
    state.courses.lessonId = null;
    state.courses.entryTab = "home";
    state.quizLock = null;
    saveState();

    renderAllSubjects();
    renderHome();
    setTab("home");
  } finally {
       if (submitBtn) submitBtn.disabled = false;
     }
  });
}

  function bindActions() {
    document.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-action]");
      if (!btn) return;

      const action = btn.dataset.action;

            // ===== Profile local navigation (must work from anywhere) =====
      if (action === "profile-settings") {
       setTab("profile");
       openProfileSettings();   // ✅ push в стек + правильный рендер
       return;
      }
    
      if (action === "profile-settings-back") {
     // ✅ ведём себя как обычный back: из settings -> main профиля
     if (state.tab !== "profile") setTab("profile");
     openProfileMain();
     return;
   }


      // ---------- Global navigation actions (available everywhere) ----------
      if (action === "back") { // generic back
  if (state.quizLock) return;

  // ✅ FALLBACK: если видим settings профиля, но state.tab почему-то не "profile"
  const ps = document.getElementById("profile-settings");
  const psActive = ps && ps.classList.contains("is-active") && ps.hidden !== true;
  if (psActive) {
    // возвращаемся на main профиля предсказуемо
    state.tab = "profile";
    openProfileMain();
    return;
  }

  const topView = state.viewStack?.[state.viewStack.length - 1];
  if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
    globalBack();
    return;
  }
  if (state.tab === "courses") {
    popCourses();
    return;
  }
  if (state.tab === "profile") {
    if (getProfileTopScreen() !== "main") {
      popProfile();
      return;
    }
    setTab(state.prevTab || "home");
    return;
  }
  if (state.tab === "ratings") {
    setTab(state.prevTab || "home");
    return;
  }
  return;
}

      if (action === "go-home") { setTab("home"); return; }
      if (action === "go-profile") { setTab("profile"); return; }
      if (action === "open-ratings") { setTab("ratings"); return; }
      if (action === "ratings-info") { openRatingsSearchModal(); return; }

      if (action === "open-resources") { openGlobal("resources"); return; }
      if (action === "open-news") { openGlobal("news"); return; }
      if (action === "open-notifications") { openGlobal("notifications"); return; }
      if (action === "open-community") { openGlobal("community"); return; }
      if (action === "open-about") { openGlobal("about"); return; }
      if (action === "open-certificates") { openGlobal("certificates"); return; }
      if (action === "open-archive") {
  if (!canOpenArchiveNow()) {
    showToast("Архив откроется после завершения активного тура.");
    return;
  }
  openGlobal("archive");
  return;
}

         // All Subjects from anywhere (Home tile, etc.)
if (action === "open-all-subjects") {
  if (state.quizLock) return;
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

      // Community links
      if (action === "open-channel") {
        openExternal("https://t.me/iClubuzofficial");
        return;
      }
      if (action === "open-chat") {
        openExternal("https://t.me/+yp3GKhnohKQxOTdi");
        return;
      }

      // Resources hub: global books button (still placeholder)
      if (action === "open-books-global") {
        showToast("Books list: подключим через базу");
        return;
      }

       if (action === "open-my-recs-global") {
  // логика как из профиля
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast("Сначала выберите предметы в Courses.");
    return;
  }

  state.courses.subjectKey = pick;
  saveState();
  setTab("courses");

  // Earned Credentials: Research-Oriented — recommendation opened
    try { trackEvent("recommendation_opened", { source: "global_my_recs", subject_id: normSubjectId(pick) }); } catch {}

  replaceCourses("my-recs");
  renderMyRecs();
  return;
}
      // ---------- Tab-specific / Courses actions ----------
        if (action === "profile-certificates") { openGlobal("certificates"); return; }
        if (action === "profile-community") { openGlobal("community"); return; }
        if (action === "profile-about") { openGlobal("about"); return; }
        if (action === "profile-open-my-recs") {
  // открыть "Мои рекомендации" по первому разумному предмету
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast("Сначала выберите предметы в Courses.");
    return;
  }

  state.courses.subjectKey = pick;
  saveState();
  setTab("courses");

  // Earned Credentials: Research-Oriented — recommendation opened
  try { trackEvent("recommendation_opened", { source: "profile_my_recs", subject_id: normSubjectId(pick) }); } catch {}

  replaceCourses("my-recs");
  renderMyRecs();
  return;
}

if (action === "profile-open-courses") {
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

if (action === "profile-open-ratings") {
  setTab("ratings");
  return;
}

      // Courses actions
      if (action === "to-subject-hub") {
        replaceCourses("subject-hub");
        renderSubjectHub();
        return;
      }

      if (action === "open-all-subjects") {
        replaceCourses("all-subjects");
        renderAllSubjects();
        return;
      }

      if (action === "open-lessons") {
        pushCourses("lessons");
        renderLessons();
        return;
      }

      if (action === "open-practice") {
        openPracticeStart();
        return;
      }

      if (action === "practice-start") {
        startPracticeNew();
        return;
      }

       if (action === "practice-resume") {
  const subjectKey = state.courses.subjectKey;
  const draft = loadPracticeDraft();
  if (!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz)) {
    showToast(t("not_available"));
    return;
  }

  state.quizLock = "practice";
  state.quiz = draft.quiz;
  state.quiz.paused = false;
  state.quiz.pauseStartedAt = null;
  clearPracticeDraft();

  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
  return;
}

      if (action === "practice-pause") {
        handlePracticePause();
        return;
      }

      if (action === "practice-submit") {
        handlePracticeSubmit(false);
        return;
      }

      if (action === "practice-review") {
  pushCourses("practice-review");
  renderPracticeReview();
  return;
}

if (action === "practice-recommendations") {
  pushCourses("practice-recs");
  renderPracticeRecs();
  return;
}

      if (action === "practice-back-to-result") {
        // go to result without destroying stack
        // simplest: pop until practice-result
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "practice-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["practice-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }

      if (action === "practice-again") {
        clearPracticeDraft();
        startPracticeNew();
        return;
      }

           if (action === "open-tours") {
        // additional subjects: tours are not available
        if (isAdditionalSubjectKey(state.courses.subjectKey)) {
        toastToursDenied("not_main");
        return;
      }

        const profile = loadProfile();
        const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);
        if (!eligibility.ok) {
          toastToursDenied(eligibility.reason);
          return;
        }

        pushCourses("tours");
        renderToursStart(); // ✅ fill stats + hide trend when <2
        return;
      }


       if (action === "open-tour") {
        openTourRules();
        return;
      }

     if (action === "open-archive-tours") {
     if (!canOpenArchiveNow()) {
       showToast("Архив откроется после завершения активного тура.");
       return;
     }
  // пока архив — глобальный экран
     openGlobal("archive");
        return;
      }

      if (action === "tour-start") {
        openTourQuiz();
        return;
      }

// pick option
if (action === "tour-pick") {
  const ctx = state.tourContext;
  if (!ctx) return;

  const picked = Number(btn.dataset.index);
  // highlight
  $$("#tour-options .option").forEach(o => o.classList.remove("is-selected"));
  btn.classList.add("is-selected");

  // enable next
  const next = $("#tour-next-btn");
  if (next) next.disabled = false;

  // store temporarily (not final submit yet)
  ctx._pickedIndex = picked;
  saveState();
  return;
}

// next / finish
if (action === "tour-next" || action === "tour-submit") {
  const ctx = state.tourContext;
  if (!ctx) return;

  // UI: show "Saving..." also on Next (not only Finish)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
    nextBtn.classList.add("is-loading");
    nextBtn.disabled = true;
    nextBtn.textContent = (window.i18n?.t ? window.i18n.t("saving") : "Saving…");
  }

  const picked = (ctx._pickedIndex === null || ctx._pickedIndex === undefined) ? null : Number(ctx._pickedIndex);
  ctx._pickedIndex = null;
  saveState();

  submitTourAnswer({ pickedIndex: picked, auto: false });
  return;
}

      if (action === "tour-review") {
        pushCourses("tour-review");
        return;
      }

      if (action === "tour-back-to-result") {
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "tour-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["tour-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }

      if (action === "tour-certificate") {
        openGlobal("certificates");
        return;
      }

      if (action === "open-books") {
        pushCourses("books");
        return;
      }

      if (action === "open-my-recommendations") {
  const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : "";

 // Earned Credentials: Research-Oriented — recommendation opened
  try { trackEvent("recommendation_opened", { source: "subject_hub_my_recs", subject_id: normSubjectId(subject_id) }); } catch {}

  pushCourses("my-recs");
  renderMyRecs();
  return;
}

            if (action === "video-skip") {
        const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : (state?.activeSubjectKey ? String(state.activeSubjectKey) : "");
        const lesson_id = state?.courses?.lessonId ? String(state.courses.lessonId) : "";
        trackEvent("video_skipped", { subject_id, lesson_id });

        openPracticeStart();
        return;
      }

      if (action === "video-complete") {
        const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : (state?.activeSubjectKey ? String(state.activeSubjectKey) : "");
        const lesson_id = state?.courses?.lessonId ? String(state.courses.lessonId) : "";
        trackEvent("video_completed", { subject_id, lesson_id });

        openPracticeStart();
        return;
      }

      if (action === "resources-archive") {
  if (!canOpenArchiveNow()) {
    showToast("Архив откроется после завершения активного тура.");
    return;
  }
  openGlobal("archive");
  return;
}
    });

    // Tours list click (demo)
    const toursList = $("#tours-list");
    if (toursList) {
      toursList.addEventListener("click", () => {
        openTourRules();
      });
    }
  }

  // ---------------------------
  // Boot
  // ---------------------------
    // ---------------------------
  // Splash: wait for critical images
  // ---------------------------
  function preloadImages(urls, { timeoutMs = 6000 } = {}) {
    const unique = Array.from(new Set((urls || []).filter(Boolean)));

    const tasks = unique.map((url) => new Promise((resolve) => {
      const img = new Image();
      const done = () => resolve({ url, ok: true });

      img.onload = done;
      img.onerror = () => resolve({ url, ok: false });

      // ⚠️ чтобы не зависнуть навсегда на плохом файле
      const timer = setTimeout(() => resolve({ url, ok: false, timeout: true }), timeoutMs);

      img.onload = () => { clearTimeout(timer); done(); };
      img.onerror = () => { clearTimeout(timer); resolve({ url, ok: false }); };

      img.src = url;
    }));

    return Promise.all(tasks);
  }

  function preloadAppImages() {
    // ✅ критичные картинки, которые видны сразу
    const urls = [
      "logo.png",
      "asset/informatics.png.png",
      "asset/economics.png.png",
      "asset/biology.png.png",
      "asset/chemistry.png.png",
      "asset/mathematics.png.png",
    ];

    return preloadImages(urls, { timeoutMs: 6000 });
  }

     // ---------------------------
  // Debug: Registration reset helpers
  // ---------------------------
  function resetRegistrationSoft() {
    // Local-only reset (keeps Supabase auth session)
    try {
      localStorage.removeItem("profile");
      localStorage.removeItem("state");
       window.__profileDbSubjectsReady = false;

      // если у тебя есть другие ключи — добавим позже точечно
    } catch (e) {}

    showView("registration");
    bindRegistration();
  }

  async function resetRegistrationHard() {
    // Full reset: sign out + clear local storage + reload
    try {
      if (window.sb) {
        await window.sb.auth.signOut();
      }
    } catch (e) {}

    try {
      localStorage.clear();
    } catch (e) {}

    location.reload();
  }

  // expose to console
  window.resetRegistrationSoft = resetRegistrationSoft;
  window.resetRegistrationHard = resetRegistrationHard;

       async function boot() {
    // ✅ показать splash и скрыть topbar (updateTopbarForView("splash") сработает внутри showView)
    showView("splash");

    const profile = loadProfile();
    const lang = profile?.language || getTelegramLang() || "ru";
    window.i18n?.setLang(lang);
    applyStaticI18n();

    const statusEl = $("#splash-status");
    if (statusEl) statusEl.textContent = t("loading");

    // ✅ минимум показываем splash чуть-чуть, чтобы не “мигало”
    const minDelay = new Promise((r) => setTimeout(r, 250));

    // ✅ параллельно поднимаем Supabase-сессию (не блокируем UX)
    const supaReady = initSupabaseSession().catch(() => null);

        Promise.all([preloadAppImages(), minDelay, supaReady]).then(async () => {
      // Stage B: if local profile is missing, try hydrate from DB
      try { await hydrateLocalProfileFromSupabaseIfMissing(); } catch {}

// Stage B2: always sync user_subjects from DB → local profile (single source for UI)
try { await syncUserSubjectsFromSupabaseIntoLocalProfile(); } catch {}

      if (!isRegistered()) {
        showView("registration");
        bindRegistration();
        return;
      }

      renderAllSubjects();
      renderHome();

      // ✅ Требование: при полном запуске (reload/новый старт) всегда стартуем с Home
      // Сворачивание/возврат не трогаем — там не происходит reload.
      state.tab = "home";
      saveState();

      // ✅ Courses всегда начинает с All Subjects (когда пользователь туда зайдёт)
      state.courses = state.courses || {};
      state.courses.stack = ["all-subjects"];
      saveState();

      // Start at Home
      setTab("home");
    });
  }

   // ---------------------------
// Credentials UI (Profile + Subject Hub)
// ---------------------------
function getCredTitleKey(credKey) {
  switch (credKey) {
    case "consistent_learner": return "cred_consistent_learner";
    case "focused_study_streak": return "cred_focused_study_streak";
    case "active_video_learner": return "cred_active_video_learner";
    case "practice_mastery": return "cred_practice_mastery_subject";
    case "error_driven_learner": return "cred_error_driven_learner";
    case "research_oriented": return "cred_research_oriented_learner";
    case "fair_play": return "cred_fair_play_participant";
    default: return credKey;
  }
}

function formatCredStatus(status) {
  if (!status) return "";
  if (status === "active") return t("cred_status_active");
  if (status === "inactive") return t("cred_status_inactive");
  if (status === "expired") return t("cred_status_expired");
  if (status === "revoked") return t("cred_status_revoked");
  return String(status);
}

function formatDateShortSafe(ts) {
  if (!ts) return "";
  try {
    const d = new Date(ts);
    if (Number.isNaN(d.getTime())) return "";
    return d.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "2-digit" });
  } catch {
    return "";
  }
}

function readCredStoreSafe() {
  try {
    // функция должна уже существовать из прошлых патчей
    if (typeof getCredentialStore === "function") return getCredentialStore();
  } catch {}
  return null;
}

function getCredRecord(store, credKey) {
  if (!store) return null;

  // Ожидаемый слой хранения из документа: user_credentials[credential_key]
  // (Если у тебя структура слегка отличается — ниже есть fallback)
  if (store.user_credentials && store.user_credentials[credKey]) return store.user_credentials[credKey];

  // fallback: иногда кладут прямо в store.credentials
  if (store.credentials && store.credentials[credKey]) return store.credentials[credKey];

  return null;
}

function getCredEvidence(rec) {
  return rec?.evidence_snapshot || rec?.evidence || null;
}

function buildProgressLine(credKey, rec) {
  const ev = getCredEvidence(rec);
  if (!ev) return "";

  // Progress hints строго по документу (>=60%) — показываем только если уже есть метрики
  // Consistent: показывать когда active_days_14d >= 5
  if (credKey === "consistent_learner") {
    const x = Number(ev.active_days_14d ?? ev.active_days ?? NaN);
    if (!Number.isFinite(x)) return "";
    if (x >= 5 && x < 7) return t("cred_progress_consistent", { x: String(x) });
    return "";
  }

  // Focused: 3/5+
  if (credKey === "focused_study_streak") {
    const x = Number(ev.focused_sessions_in_row ?? ev.sessions_in_row ?? NaN);
    if (!Number.isFinite(x)) return "";
    if (x >= 3 && x < 5) return t("cred_progress_focused", { x: String(x) });
    return "";
  }

  // Practice: attempts_count>=5 как мягкий прогресс (без новых правил) — показываем только если есть счётчики
  if (credKey === "practice_mastery") {
    const attempts = Number(ev.attempts_count ?? NaN);
    if (!Number.isFinite(attempts)) return "";
    if (attempts >= 5 && attempts < 8) return t("cred_progress_practice_attempts", { x: String(attempts) });
    return "";
  }

  // Error-driven: cycles_count>=2
  if (credKey === "error_driven_learner") {
    const cycles = Number(ev.cycles_count ?? NaN);
    if (!Number.isFinite(cycles)) return "";
    if (cycles >= 2 && cycles < 3) return t("cred_progress_error_cycles", { x: String(cycles) });
    return "";
  }

  // Research: opens>=2
  if (credKey === "research_oriented") {
    const opens = Number(ev.resource_opens_total ?? ev.opens ?? NaN);
    const days = Number(ev.distinct_return_days ?? ev.return_days ?? NaN);
    if (!Number.isFinite(opens) || !Number.isFinite(days)) return "";
    // мягко: если opens>=2 или days>=1, показываем только когда близко к 60%
    if (opens >= 2 || days >= 1) return t("cred_progress_research", { x: String(opens), y: String(days) });
    return "";
  }

  return "";
}

function renderProfileCredentialsUI() {
  const grid = document.querySelector(".profile-credentials-grid");
  if (!grid) return;

  const store = readCredStoreSafe();
  const keys = [
    "consistent_learner",
    "focused_study_streak",
    "active_video_learner",
    "practice_mastery",
    "error_driven_learner",
    "research_oriented",
    "fair_play"
  ];

  // Собираем active credentials (как “список”)
  const actives = [];
  const progressLines = [];

  keys.forEach(k => {
    const rec = getCredRecord(store, k);
    if (!rec) return;

    const status = rec.status;
    const title = t(getCredTitleKey(k));
    const statusText = formatCredStatus(status);
    const achieved = formatDateShortSafe(rec.achieved_at);

    if (status === "active") {
      actives.push({ title, statusText, achieved });
    }

    const p = buildProgressLine(k, rec);
    if (p) progressLines.push(p);
  });

  // Рендер “список”
  grid.innerHTML = "";

  if (actives.length === 0) {
    const empty = document.createElement("div");
    empty.className = "card-sub";
    empty.textContent = t("cred_none_yet");
    grid.appendChild(empty);
  } else {
    actives.forEach(item => {
      const card = document.createElement("div");
      card.className = "credential-card";

      const titleEl = document.createElement("div");
      titleEl.className = "credential-title";
      titleEl.textContent = item.title;

      const metaEl = document.createElement("div");
      metaEl.className = "credential-meta";
      metaEl.textContent = item.achieved ? `${item.statusText} • ${item.achieved}` : item.statusText;

      card.appendChild(titleEl);
      card.appendChild(metaEl);
      grid.appendChild(card);
    });
  }

  // Рендер “прогресс” (inline)
  let progWrap = document.getElementById("profile-credentials-progress");
  if (!progWrap) {
    progWrap = document.createElement("div");
    progWrap.id = "profile-credentials-progress";
    progWrap.className = "cred-progress-list";
    grid.insertAdjacentElement("afterend", progWrap);
  }

  if (progressLines.length === 0) {
    progWrap.classList.add("hidden");
    progWrap.innerHTML = "";
  } else {
    progWrap.classList.remove("hidden");
    progWrap.innerHTML = progressLines.map(s => `<div class="cred-progress-item">${escapeHTML(s)}</div>`).join("");
  }
}

function renderSubjectHubCredentialsInline(subjectKey) {
  const wrap = document.getElementById("subject-hub-credential-hints");
  if (!wrap) return;

  // set labels from i18n (so RU/UZ/EN match)
  const kickerEl = wrap.querySelector(".panel-kicker");
  const focusedLabelEl = document.getElementById("hub-cred-focused-label");
  const practiceLabelEl = document.getElementById("hub-cred-practice-label");
  const focusedValEl = document.getElementById("hub-cred-focused-value");
  const practiceValEl = document.getElementById("hub-cred-practice-value");

  if (kickerEl) kickerEl.textContent = t("cred_kicker_progress");
  if (focusedLabelEl) focusedLabelEl.textContent = t("cred_label_focused");
  if (practiceLabelEl) practiceLabelEl.textContent = t("cred_label_practice");

  if (focusedValEl) focusedValEl.textContent = "—";
  if (practiceValEl) practiceValEl.textContent = "—";

    const store = readCredStoreSafe();
  if (!store) return;

  const subject_id = normSubjectId(subjectKey);

  const focusedRec = getCredRecord(store, "focused_study_streak");

  // ✅ Practice Mastery хранится ПО ПРЕДМЕТАМ: practice_mastery_subject.by_subject[subject_id]
  const practiceBucket =
    store?.practice_mastery_subject?.by_subject?.[subject_id] || null;

  const focusedEv = getCredEvidence(focusedRec);
  const practiceEv = getCredEvidence(practiceBucket);

  // Focused: показываем "4/5" только если серия по этому предмету и еще не достигла 5
  const focusedCount = Number(
    focusedEv?.focused_sessions_in_row ?? focusedEv?.sessions_in_row ?? 0
  );
  const focusedSubject = String(
    focusedEv?.current_subject_key ?? focusedEv?.current_subject_id ?? ""
  );

  const isFocusedSame =
    focusedSubject && (String(normSubjectId(focusedSubject)) === String(subject_id));

  if (focusedValEl && isFocusedSame && focusedCount > 0 && focusedCount < 5) {
    focusedValEl.textContent = `${focusedCount}/5`;
  }

  // Practice: аккуратно показываем best/median, если уже есть попытки
  const practiceAttempts = Number(practiceEv?.attempts_count ?? NaN);
  const practiceBest = Number(practiceEv?.best_percent ?? NaN);
  const practiceMedian = Number(practiceEv?.median_percent ?? NaN);

  if (practiceValEl && Number.isFinite(practiceAttempts) && practiceAttempts > 0) {
    const bestTxt = Number.isFinite(practiceBest) ? `${Math.round(practiceBest)}%` : "—";
    const medTxt = Number.isFinite(practiceMedian) ? `${Math.round(practiceMedian)}%` : "—";
    practiceValEl.textContent = `${bestTxt} • ${medTxt}`;
  }
}

  function bindUI() {
  bindTabbar();
  bindTopbar();
  bindActions();
  bindRatingsUI(); // ✅ Leaderboard controls
}

     // Earned Credentials — daily evaluation jobs (once per Tashkent day)
  try { runDailyCredentialJobs(); } catch {}

    // Init
  bindUI();
  boot();

})();
