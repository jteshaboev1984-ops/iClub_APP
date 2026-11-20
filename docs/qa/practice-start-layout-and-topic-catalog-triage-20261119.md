# #574 · Practice start regrouping + Topic catalog loading incident — 2026-11-19

Status: **isolated Draft UX candidate / topic load incident OPEN, not reproduced in user client**.
Scope: Mathematics, Economics, Chemistry, Biology, Informatics Practice. No release approval.

## 1. Owner-accepted main Practice order
The owner explicitly chose this exact vertical order, preserving the existing app, academic rules and access:
1. **Statistics first.** Keep the real subject, selected Tour metrics, best score/time, progress trend only when applicable, and truthful active/last/upcoming Tour status. Do not invent progress or active Tours.
2. **Tour / Topic switch.** Existing accessible two-category learning tabs, independent from the standalone History screen.
3. **Tour or Topic selection.** Preserve horizontally scrollable Tour chips / current lock gates. Topic mode retains the existing authenticated topic search and bounded catalog. **Owner update, 2026-11-19:** tapping an eligible Topic tile **starts Topic Practice immediately**, using the original protected start handler; no separate Topic Start button.
4. **Start / Resume action.** Tour mode retains existing Practice start/restart/paused-draft logic; Topic mode uses the topic tile itself as its **Start** action. The original **Resume** CTA is shown only when a paused attempt exists; it is not duplicated with an extra Start button. Existing session protections are unchanged.
5. **Recent attempts.** Tour's existing attempts table is after the action; Topic's existing owner-scoped summary/history goes after the action. Keep it accessible for Season 1 until signed new History parity is ready. The previously approved compact **History** link remains below both tab panels, opens the separate Courses-stack screen (PR #583), never embeds the long archive into Practice.

**Note:** The global Statistics overview is the existing **selected Tour** summary; do not imply it is a computed Topic mastery score. Preserve RU/UZ/EN, Academy OS visual tokens, 44px targets and single host Back.

Code ownership: separate child of approved source [#583](https://github.com/jteshaboev1984-ops/iClub_APP/pull/583) → #581 → #579. Changes preserve the original one-tap Topic Start flow and guarded original callback; the prior intermediate selected-topic + extra Start button candidate was superseded by the owner's explicit correction. Backend eligibility, score, attempt creation, access and period boundaries are unchanged.

## 2. Reported incident — “Practice topics failed to load”

**Owner observation (2026-11-19):** Current iClub app could not load available Practice topics. Exact subject, screen, timestamp, network response and browser console error are **not available**, so **do not mark the incident fixed or assume root cause**.

### Verified source path
- `practice-results-tabs.js` → open **By Topic** mode, expands `.practice-topic-choice-toggle`.
- `practice-topic-choice.js` `mount → load` invokes `window.sb.rpc('get_practice_available_topics_safe_v1',{p_subject_key:subjectKey})` after the topic choice panel is opened. Expects `data.ok===true` and a `topics` array. Error path shows generic “Could not load topics” and Retry.
- Live `public.get_practice_available_topics_safe_v1(text)` is present, `SECURITY DEFINER`, `EXECUTE` granted to `authenticated` and not `anon`. All five referenced subjects are active.
- **Live Supabase PostgreSQL 17.6, READ-ONLY**, authenticated role with a synthetic non-existent UUID, no history reads/edits, no learner data output: RPC returned `ok=true` with eligible-topic counts **mathematics 9, chemistry 41, biology 19, economics 11, informatics 37** on 2026-11-19. This verifies the live DB function + its candidate catalog for this test context **only**, NOT the user’s actual HTTP/JWT/browser session. No changes to Supabase.
- A bounded, aggregate search over `edge_logs/postgrest_logs` for this named RPC between **09:30 and 12:45 UTC 2026-11-19** returned no matching paths; log coverage/retention and path normalization cannot establish whether the user's request fired.

### Status, possible layers, and required follow-up (OPEN)
**NOT reproduced.** A functioning SQL RPC does not prove the live browser fetch works. Do not change SQL grants, RLS, protected answers or topic bank on speculation.

1. Open current deployed mobile Telegram WebApp/web Practice for each enabled subject, switch **By Topic**, expand topic selector. Record environment, approximate timestamp, subject key, anonymous/authenticated `role` (never copy token), expected and actual message.
2. Inspect DevTools Network **RPC path only** `/rest/v1/rpc/get_practice_available_topics_safe_v1`, HTTP status and sanitized error code/message (no JWT, question text, keys, user ID). Distinguish **request absent** (client mount/session/cache/JS), **401/403** (auth or grants), **404/PGRST202** (route/schema-cache), **429/5xx** (availability), **200 + ok=false/[]** (candidate filtering), and timeout/offline.
3. Verify registered anonymous Supabase client session refresh and correct subject key on tab open/re-entry and after switching subjects; check late results do not overwrite another subject. Test Retry actually repeats the request and reports a safe failure to the learner.
4. Reproduce using an isolated Chromium UI shell plus signed JWT → PostgREST against PostgreSQL 17 fixture, then compare with **actual deployed** source SHA and authenticated mobile/desktop browser capture before approving any fix. If proven client issue, create narrowly scoped follow-up in Practice; if server issue, propose read-only prerequisite/source patch with PG17 and permission verification.
5. Confirm only an **eligible fetched Topic tile click** starts Topic Practice (once while start is in flight), Resume appears only for an existing paused attempt, and a catalog error/Retry never starts an attempt or exposes locked questions. Keep verified Tour Practice functional if Topic service fails.

**Definition of done:** user-observed failure reproduced with sanitized HTTP/console trace OR concretely disproved on the same deployed version/session; root cause and independent fix validated with exact SHA, RU/UZ/EN, mobile and desktop, subject switching, auth/error/retry and access controls. Until then status **OPEN / not root-caused**.

## 3. Release and lineage limits
- Source and browser acceptance are distinct from live release; current hosted Season2 Tour1 dates are undated/draft and new Season2 period RPC is not installed.
- Preserve historic Season1 results, Tour attempts, certified/ranked outcomes, private banks, session owners. No deletion, regrade, scores/mastery/entitlement changes.
- Do not modify `main`, production Vercel, live Supabase SQL, Tour dates, topic content, bank, or rate plans without separate owner GO.
- Record exact child PR HEAD and CI outcomes in canonical #574 when they are available. Integrate via owner review of #583 / UX531, not by merging directly to main.

## 4. Architect visual acceptance / integration checkpoint (2026-11-19)

**Visual layout accepted:** Architect accepted both Tour/Topic screen compositions as design previews. This **does not** authorize merge to main, Vercel production deployment or live SQL migration. Topic tile **direct one-tap launch** remains the selected behavior; no second Topic Start button.

**Source adjustment after acceptance:** The current-Tour statistics banner previously included a second `К практике` shortcut above the mode switch. This duplicated Tour Start and violated the accepted block order. The isolated integration candidate removes only that shortcut, leaving genuine Tour status/subject statistics in the overview and original Tour Start/Resume after Tour selection. The existing Topic one-tap launch and paused-attempt Resume remain untouched.

### Read-only historical fallback candidate (no live deployment)
Current live Supabase has **Season1 closed** with verified subject Tour1 starts, while **Season2 is draft/undated**. The staged Season2 progress RPC is **not installed** in production. If a new History viewer relied exclusively on `period_active===true` for S2, existing Season1 users would see an unavailable screen, hiding accessible old results even though underlying history remains intact.

The proposed change extends **the same staged read-only** `supabase/candidates/practice_season2_progress_safe_v1.sql` with a `history_snapshot` field **only while S2 is dormant**. Snapshot includes a genuine owner-scoped Season1 aggregate and the separate *pre-Season1* bucket. It uses only authenticated `auth.uid()`, subject-specific verified Tour1 date, finalized Topic sessions, last 20 sanitized result metadata per category, and ordinary Practice attempts excluding labs. It does not return question text, answers, explanations, keys or personal identifiers. Status of Season1 is taken from `seasons.status` so a **closed** season displays **“Завершённый сезон”**, never falsely **“Текущий сезон”**. Once S2 begins, existing S2 progress/History behavior is unchanged.

**Safety contract:** The top-level S2 `period_active=false` and `period_starts_at` remains absent when dormant, so existing Practice Tour performance selectors **must not be reset to Season1 boundaries**. The nested `history_snapshot` is used only by `practice-history-screen.js`. Its legacy bucket is a disclosure inside the oldest season, not fictitious Season 0; no extra swipe choices. This is a bounded preview, not cursor pagination/full history.

**Acceptance tests proposed in the isolated child:** exact-source PG17 `supabase/tests/practice_season2_progress_safe_isolated.sql` validates S1/legacy separation and cross-owner/other-subject isolation; signed JWT/PostgREST verifies S2 unchanged; Chromium `scripts/practice-history-standalone-chromium.cjs` tests dormant-S2 closed-S1 status in RU/UZ/EN × 320/375/430/1440. The separate owner-order Chromium checks no duplicate Tour shortcut. **Only claim PASS after exact-HEAD CI completes.**

**Still HOLD:** S2 SQL candidate requires separate owner authorization for production installation and main integration; no installed History snapshot exists today. The real user's Topic catalog loading failure remains **OPEN / unknown client-specific HTTP/JWT cause** and is not fixed by this history work. Full older records >20 per lane still need a separate owner-scoped cursor API before claiming complete archives.

## 5. 2026-11-20 · Source-confirmed catalog client gaps and staged diagnostics

**Hosted reality (read-only):** Vercel project `i-club-app` latest production deployment `dpl_E46SFZcpjUtjywxGmhYNSfTDkfMb` is **READY** on GitHub `main` SHA `74e291b0fba989084387a6fe137871db07f10fbd`. The accepted Practice UI and this incident candidate remain unpublished **Drafts**. Vercel's Git deployment source file-tree API returned 404 (not available for this deployment); this is **not evidence of missing files**. GitHub `main` is the SHA-corresponding source reference, but no actual authenticated user-browser network request has been captured.

Live Supabase `get_practice_available_topics_safe_v1(text)` `pg_get_functiondef` MD5 `565cd971127d5389a5850b92ad439efa`: authenticated EXECUTE=true, anon EXECUTE=false. Server returns `ok:true`, `subject_key:trim(p_subject_key)`, and `topics` array after eligible pool/question filtering. A bounded last-24h read-only edge-log query showed **zero visible paths containing `get_practice_available_topics_safe_v1`**. It cannot establish that requests were never sent: the user's session/time, edge logging and coverage remain unknown.

**Concrete source defects, not yet the root cause of the user report:** existing `practice-topic-choice.js` collapsed all catalog errors (HTTP auth/route/connection/response) into the same unqualified “Could not load topics”; it did not verify `data.subject_key` before showing clickable topic tiles, unlike its separate Topic History fetch. This prevents effective incident diagnosis and leaves a response-mismatch data-integrity gap. These source deficiencies are independently reproducible without assuming the original user problem.

**Isolated Draft candidate:** extend only `practice-topic-choice.js`, its minimal stylesheet and testing. On failure, retain original RU/UZ/EN message + explicit Retry and add a small bounded identifier (`CLIENT_NOT_READY`, `HTTP_401`, `HTTP_404`, `SUBJECT_MISMATCH`, `INVALID_RESPONSE`, `UNAVAILABLE`, or constrained PostgREST code). Raw `error.message`, response JSON, URLs, network headers, question text, user IDs, JWTs and tokens must **never** be written to DOM, logs, GitHub or screenshots. Successful Retry clears the code; it never calls `onStart`. A successful response must echo the requested subject key **exactly**. A wrong-key response is refused and creates zero topic tiles. The existing `mountSerial` guard rejects old promises after switching subjects; the Chromium matrix now verifies that behavior. No additional RPC, auto-sign-in, auto-retry, storage, telemetry or migration.

**QA**: browser fixture exercises failed-client initialization, actual-shaped 401/403/404 status, wrong-subject response, malformed catalog, nonpublic error text, explicit Retry, no accidental start, stale delayed response after remount, RU/UZ/EN at 320/375/430/1440. The existing Practice owner-order and old Topic-choice QA run alongside. Their UI mocks are **synthetic**; they do **not** demonstrate real deployed end-to-end auth or prove the original reported incident resolved.

**Incident status stays OPEN / not root-caused**. The new safe code allows the architect to report e.g. “HTTP_401” or “CLIENT_NOT_READY” from the actual app after a separately approved release, without sharing bearer tokens or user details. Until that release, old production still shows the generic error and the correct next independent evidence remains the real, sanitized network status or browser event from that deployed SHA. No Supabase live grants/RLS/user tables/production release changed.
