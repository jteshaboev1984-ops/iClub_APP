from pathlib import Path
import re

path = Path("app.js")
s = path.read_text(encoding="utf-8")

def find_function_bounds(src, name):
    m = re.search(r'async\s+function\s+' + re.escape(name) + r'\s*\(|function\s+' + re.escape(name) + r'\s*\(', src)
    if not m:
        raise SystemExit(f"ERROR: function {name} not found")
    start = m.start()
    brace = src.find("{", m.end())
    if brace < 0:
        raise SystemExit(f"ERROR: opening brace not found for {name}")
    depth = 0
    i = brace
    in_str = None
    esc = False
    while i < len(src):
        ch = src[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == in_str:
                in_str = None
        else:
            if ch in ("'", '"', "`"):
                in_str = ch
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return start, i + 1
        i += 1
    raise SystemExit(f"ERROR: closing brace not found for {name}")

def replace_function(src, name, new_code):
    a, b = find_function_bounds(src, name)
    return src[:a] + new_code.strip() + "\n" + src[b:]

helpers = r'''
async function getSeasonOneId() {
  try {
    if (!window.sb) return null;

    const { data, error } = await window.sb
      .from("seasons")
      .select("id")
      .eq("season_no", 1)
      .maybeSingle();

    if (error || !data?.id) return null;
    return Number(data.id) || null;
  } catch {
    return null;
  }
}

async function getCurrentSeasonId() {
  try {
    if (!window.sb) return null;

    const { data, error } = await window.sb
      .from("seasons")
      .select("id,season_no,status")
      .eq("status", "current")
      .order("season_no", { ascending: false })
      .limit(1);

    if (!error && Array.isArray(data) && data[0]?.id) {
      return Number(data[0].id) || null;
    }
  } catch {}

  return await getSeasonOneId();
}

async function getTourSeasonIdByTourId(tourId) {
  try {
    if (!window.sb || !tourId) return null;

    const { data, error } = await window.sb
      .from("tours")
      .select("season_id")
      .eq("id", tourId)
      .maybeSingle();

    if (error || !data?.season_id) return null;
    return Number(data.season_id) || null;
  } catch {
    return null;
  }
}

async function resolveTourSeasonId({ seasonId = null, tourId = null, subjectId = null, subjectKey = "", tourNo = null } = {}) {
  const direct = Number(seasonId || 0);
  if (Number.isFinite(direct) && direct > 0) return direct;

  const byTour = await getTourSeasonIdByTourId(tourId);
  if (byTour) return byTour;

  try {
    if (!subjectId && subjectKey && typeof getSubjectIdByKey === "function") {
      subjectId = await getSubjectIdByKey(subjectKey);
    }

    if (window.sb && subjectId && tourNo) {
      const { data, error } = await window.sb
        .from("tours")
        .select("season_id,start_date,end_date,id")
        .eq("subject_id", Number(subjectId))
        .eq("tour_no", Number(tourNo))
        .order("start_date", { ascending: false })
        .limit(1);

      if (!error && Array.isArray(data) && data[0]?.season_id) {
        return Number(data[0].season_id) || null;
      }
    }
  } catch {}

  return await getCurrentSeasonId();
}

function tourRecommendationKeyV1(seasonId, tourNo, topic, subtopic) {
  return [
    Number(seasonId || 0),
    Number(tourNo || 0),
    String(topic || "").trim(),
    subtopic ? String(subtopic).trim() : ""
  ].join("::");
}
'''

if "async function getSeasonOneId()" not in s:
    anchor = re.search(r'function\s+safeJsonParse\s*\([^)]*\)\s*\{[\s\S]*?\n\}', s)
    if not anchor:
        raise SystemExit("ERROR: safeJsonParse anchor not found")
    s = s[:anchor.end()] + "\n\n" + helpers.strip() + "\n" + s[anchor.end():]

# loadActiveTourBySubjectAndNo must carry season_id forward
s = s.replace(
    '.select("id,subject_id,tour_no,start_date,end_date,is_active")',
    '.select("id,subject_id,tour_no,start_date,end_date,is_active,season_id")',
    1
)

# initTourSession carries seasonId in runtime context
s = s.replace(
    'function initTourSession({ subjectKey = null, tourNo = 1, tourId = null, attemptId = null, questions = [], isArchive = false, tourEndDate = null } = {}) {',
    'function initTourSession({ subjectKey = null, tourNo = 1, tourId = null, seasonId = null, attemptId = null, questions = [], isArchive = false, tourEndDate = null } = {}) {',
    1
)

s = s.replace(
    '    tourId,        // ✅ DB tour id\n    attemptId,     // ✅ DB attempt id (null for archive)',
    '    tourId,        // ✅ DB tour id\n    seasonId,      // ✅ DB season id\n    attemptId,     // ✅ DB attempt id (null for archive)',
    1
)

s = s.replace(
    '    tourId: tour.id,\n    attemptId,',
    '    tourId: tour.id,\n    seasonId: tour?.season_id || null,\n    attemptId,',
    1
)

new_save_tour_recs = r'''
async function saveTourRecsToDB(subjectKey, tourNo, recs, seasonIdArg = null) {
  try {
    if (!window.sb) return false;

    const uid = await getAuthUid();
    if (!uid) return false;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return false;

    const seasonId = await resolveTourSeasonId({
      seasonId: seasonIdArg,
      tourId: state?.tourContext?.tourId || state?.courses?.activeTourId || null,
      subjectId,
      subjectKey,
      tourNo
    });

    const normalized = (Array.isArray(recs) ? recs : [])
      .map(r => {
        const bookIdRaw = r?.book_id ?? r?.bookId ?? null;
        const bookId = Number(bookIdRaw || 0) > 0 ? Number(bookIdRaw) : null;
        const bookReference = String(
          r?.book_reference ||
          r?.bookReference ||
          r?.book_ref ||
          r?.bookRef ||
          ""
        ).trim() || null;

        return {
          season_id: seasonId || null,
          source_type: "tour",
          topic: String(r?.topic || "").trim(),
          subtopic: r?.subtopic ? String(r.subtopic).trim() : null,
          tour_no: Number(tourNo || r?.tourNo || r?.tour_no || 0) || null,
          book_id: bookId,
          book_reference: bookReference
        };
      })
      .filter(r => r.topic && r.tour_no);

    if (!normalized.length) return false;

    const key = (r) => tourRecommendationKeyV1(
      r.season_id || seasonId || 0,
      r.tour_no,
      r.topic,
      r.subtopic
    );

    const uniqMap = new Map();
    normalized.forEach(r => {
      const k = key(r);
      const prev = uniqMap.get(k);

      if (!prev || (!prev.book_reference && r.book_reference) || (!prev.book_id && r.book_id)) {
        uniqMap.set(k, { ...prev, ...r });
      }
    });

    const items = Array.from(uniqMap.values());
    const topics = Array.from(new Set(items.map(r => r.topic).filter(Boolean)));

    let query = window.sb
      .from("recommendations")
      .select("id, season_id, topic, subtopic, tour_no, book_id, book_reference")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "tour")
      .eq("tour_no", Number(tourNo));

    if (seasonId) query = query.eq("season_id", seasonId);
    else query = query.is("season_id", null);

    const { data: existing, error: selErr } = await query;

    if (selErr) {
      logClientError("tour_recs_existing_select_error", selErr);
      return false;
    }

    let mapRows = [];
    try {
      const { data: mData, error: mErr } = await window.sb
        .from("topic_book_map")
        .select("topic, subtopic, book_id, book_reference, priority, is_active")
        .eq("subject_id", subjectId)
        .eq("is_active", true)
        .in("topic", topics)
        .order("priority", { ascending: true });

      if (!mErr && Array.isArray(mData)) mapRows = mData;
    } catch {}

    const norm = (v) => String(v || "").trim();
    const normSub = (v) => {
      const st = norm(v);
      return st ? st : null;
    };

    const bestFor = (item) => {
      const topic = norm(item.topic);
      const subtopic = normSub(item.subtopic);
      const directRef = norm(item.book_reference) || null;

      const exactByDirectRef = directRef
        ? mapRows.find(x =>
            norm(x.book_reference) === directRef &&
            norm(x.topic) === topic &&
            normSub(x.subtopic) === subtopic
          )
        : null;

      const exact = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === subtopic
      );

      const byTopic = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === null
      );

      const anyByDirectRef = directRef
        ? mapRows.find(x => norm(x.book_reference) === directRef)
        : null;

      const picked = exactByDirectRef || exact || byTopic || anyByDirectRef || null;

      return {
        book_id: item.book_id || picked?.book_id || null,
        book_reference: directRef || picked?.book_reference || null
      };
    };

    const existingByKey = new Map(
      (Array.isArray(existing) ? existing : []).map(x => [key(x), x])
    );

    for (const item of items) {
      const row = existingByKey.get(key(item));
      if (!row?.id) continue;

      const best = bestFor(item);
      const patch = {};

      if (!row.book_reference && best.book_reference) patch.book_reference = best.book_reference;
      if (!row.book_id && best.book_id) patch.book_id = best.book_id;
      if (!row.season_id && seasonId) patch.season_id = seasonId;

      if (Object.keys(patch).length) {
        const { error: updErr } = await window.sb
          .from("recommendations")
          .update(patch)
          .eq("id", row.id);

        if (updErr) logClientError("tour_recs_update_refs_error", updErr);
      }
    }

    const toInsert = items
      .filter(r => !existingByKey.has(key(r)))
      .map(r => {
        const best = bestFor(r);
        return {
          user_id: uid,
          subject_id: subjectId,
          season_id: seasonId || null,
          source_type: "tour",
          tour_no: r.tour_no,
          topic: r.topic,
          subtopic: r.subtopic,
          book_id: best.book_id || null,
          book_reference: best.book_reference || null
        };
      });

    if (!toInsert.length) return true;

    const { error: insErr } = await window.sb
      .from("recommendations")
      .insert(toInsert);

    if (insErr) {
      logClientError("tour_recs_insert_error", insErr);
      return false;
    }

    return true;
  } catch (e) {
    logClientError("tour_recs_insert_exception", e);
    return false;
  }
}
'''
s = replace_function(s, "saveTourRecsToDB", new_save_tour_recs)

new_add_tour_recs = r'''
function addMyTourRecsFromTourAttempt(ctx) {
  try {
    const subjectKey = String(ctx?.subjectKey || "").trim();
    const tourNo = Number(ctx?.tourNo || 0);
    const seasonId = Number(ctx?.seasonId || ctx?.season_id || state?.tourContext?.seasonId || 0) || 0;

    if (!subjectKey || !tourNo) return { added: 0, recs: [] };

    const wrong = (Array.isArray(ctx?.answers) ? ctx.answers : [])
      .filter(a => a && a.isCorrect === false)
      .map(a => {
        const q = ctx?.questions?.[Number(a.index)] || null;
        return {
          topic: String(q?.topic || "General").trim(),
          subtopic: q?.subtopic ? String(q.subtopic).trim() : null,
          book_id: q?.book_id || q?.bookId || null,
          book_reference: String(q?.book_reference || q?.bookReference || q?.book_ref || q?.bookRef || "").trim() || null
        };
      })
      .filter(x => x.topic);

    if (!wrong.length) return { added: 0, recs: [] };

    const uniqMap = new Map();
    wrong.forEach(r => {
      const k = tourRecommendationKeyV1(seasonId, tourNo, r.topic, r.subtopic);
      const prev = uniqMap.get(k);

      if (!prev || (!prev.book_reference && r.book_reference) || (!prev.book_id && r.book_id)) {
        uniqMap.set(k, { ...prev, ...r });
      }
    });

    const uniq = Array.from(uniqMap.values());
    const store = loadMyTourRecs();
    store.bySubject = store.bySubject || {};

    const existing = new Set(
      (store.bySubject[subjectKey] || []).map(x =>
        tourRecommendationKeyV1(
          x?.seasonId || x?.season_id || 0,
          x?.tourNo || 0,
          x?.topic || "",
          x?.subtopic || ""
        )
      )
    );

    const nowTs = Date.now();

    const added = uniq
      .filter(r => !existing.has(tourRecommendationKeyV1(seasonId, tourNo, r.topic, r.subtopic)))
      .map(r => ({
        source_type: "tour",
        seasonId: seasonId || null,
        topic: r.topic,
        subtopic: r.subtopic,
        tourNo,
        book_id: r.book_id || null,
        book_reference: r.book_reference || null,
        ts: nowTs
      }));

    if (!added.length) return { added: 0, recs: [] };

    store.bySubject[subjectKey] = [
      ...added,
      ...(store.bySubject[subjectKey] || [])
    ].slice(0, 100);

    saveMyTourRecs(store);

    saveTourRecsToDB(subjectKey, tourNo, added, seasonId || null).catch(() => {});

    return { added: added.length, recs: added };
  } catch {
    return { added: 0, recs: [] };
  }
}
'''
s = replace_function(s, "addMyTourRecsFromTourAttempt", new_add_tour_recs)

if "function canIssueFinalCertificateNow" in s or "async function canIssueFinalCertificateNow" in s:
    new_can_issue = r'''
async function canIssueFinalCertificateNow(subjectKey, seasonIdArg = null) {
  try {
    if (!window.sb) return false;

    const sid = await getSubjectIdByKey(subjectKey);
    if (!sid) return false;

    const seasonId = seasonIdArg || await getCurrentSeasonId();

    let q = window.sb
      .from("tours")
      .select("tour_no,end_date,is_active,season_id")
      .eq("subject_id", sid)
      .gte("tour_no", 1)
      .lte("tour_no", 7);

    if (seasonId) q = q.eq("season_id", seasonId);

    const { data, error } = await q;

    if (error || !Array.isArray(data) || !data.length) return false;

    const uniqTours = new Set(
      data
        .map(x => Number(x.tour_no))
        .filter(n => Number.isFinite(n) && n >= 1 && n <= 7)
    );

    const todayISO = new Date().toISOString().slice(0, 10);
    const allFinished =
      uniqTours.size === 7 &&
      data.every(x => {
        const endDate = x?.end_date ? String(x.end_date).trim() : "";
        return !!endDate && endDate < todayISO;
      });

    return !!allFinished;
  } catch {
    return false;
  }
}
'''
    s = replace_function(s, "canIssueFinalCertificateNow", new_can_issue)

path.write_text(s, encoding="utf-8")
print("DONE: app.js patched for Season 1 foundation safety")
