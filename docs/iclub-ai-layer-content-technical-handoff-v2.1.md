# iClub AI Layer v2.1 — Technical Content Handoff Contract
**Date:** 2026-10-13 · **Owner policy:** THIS CHAT BUILDS THE AI TECHNOLOGY ONLY. Cards, question banks, textbook summaries and editorial lessons are made and approved in a separate conversation/workstream.

## Guaranteed product behavior (Master Plan decisions 2A, 3A, 12A, 30A, 33B, 38C, 40A, 42A)

**Published, authorized topic:** current learner, current screen and active subject; editorially approved **specific topic + language + feature + version**; live source/rights proof and safety gates pass; permitted rollout cohort; NEW Global AI is enabled. Then the unified panel becomes available automatically **without a new Vercel build for each topic**.

**Unready topic:** do not guess, generate a substitute answer, borrow another subject, expose an answer key or charge any allowance. Show a calm localized status:
- RU — **В разработке**. «AI-помощь по этой теме пока в разработке.»
- UZ — **Ishlab chiqilmoqda**. «Bu mavzu bo‘yicha AI yordami hali tayyorlanmoqda.»
- EN — **In development**. “AI help for this topic is in development.”

Offer «Общая помощь iClub AI» / «iClub AI umumiy yordami» / “General iClub AI help” **only if** the General Help feature passes its own independent global/subject/cohort/source permissions. Never display the name of a code route, provider, quota weight, a dummy lesson or internal readiness jargon to the learner.

**Active protected assessment:** hide AI UI entirely and deny backend calls (no status message shown over the test). **New AI globally disabled:** display neutral “temporarily unavailable”, never invent that an unpublished lesson is ready. **Revocation or content conflict:** immediately refuse new admission and prevent delivery of an in-flight answer.

## Inter-workstream technical metadata, NOT lesson content

When the separate editorial pipeline has completed a subject topic/language, a **future authorized publisher** must make an atomic, reviewed release update corresponding to this metadata shape (no JSON/lesson authoring needed in this AI development chat):

| Field | Meaning |
|---|---|
| `surface_code` | The exact supported UI area: lesson / practice / tour_archive / home / profile / global |
| `subject_key` | Current governed subject, e.g. biology / chemistry / economics / informatics; GENERAL is separately governed |
| `feature_code` | The precise AI function, not “the whole subject is ready” |
| `topic_key` | Canonical verified topic/skill or exact allowed question reference; must be server-owned, not guessed by client |
| `locale` | RU, UZ or EN as independent releases |
| `source_id`, `source_version`, `source_hash` | Proof of exact approved source, version and integrity; **no source body stored in release metadata** |
| 8 named boolean gates | Content approval; rights; verified source version; correctness; negative tests; exam protection; locale verification; accessibility |
| `publication_state` | `draft`, `approved` or `suspended`, initially `draft` |
| `feature_enabled` | Defaults false; requires a separate authorized release decision |
| `approved_at`, `approved_by`, `publication_revision` | Review trace and version change for immediate revoke and stale-reply blocking |

**Important:** the mere insertion of a card/source never flips a topic to ready. A release needs *all* independent QA gates AND an authorized approval; content editorial approval does not grant public/beta authorization. The owner separately approves rollout mode/cohort. Once a controlled release channel is approved, subsequently published **topic rows** may become available automatically in that channel after live checks.

## What the AI development chat delivered (all QA branch only)

1. `qa/sql_drafts/iclub_ai_topic_release_gate_v21_UNAPPLIED.sql` — new **scratch-only** private topic release registry and service-only read RPC: `get_iclub_ai_topic_release_service_v21`. Primary key includes surface, subject, function, topic, and language; absent/draft/suspended/conflicted states return `in_development`, global kill switch denies all. It stores **no answers, lesson texts, prompts, learner data or payment state**. The SQL contains an independent local scratch guard. It is **not applied**, not in `supabase/migrations`, and no content publisher/writer RPC has been created.
2. `qa/ai-layer-v21-content-handoff-gate.cjs` — content-free server-only availability adapter. Each request uses authenticated, expiring, revision-bound server context; current subject and rollout permission; source proof with live rights/hash/version; protected exam check; current release row; **trusted server clock** and fresh checks after async operations. It returns available / in_development / unavailable / hidden and the localized UI copy. Missing content is never chargeable.
3. `qa/ai-layer-v21-content-handoff-gate.test.cjs` — **32** behavior tests: missing content, new publication immediately available, hot suspension, language isolation, subject/screen isolation, protected exam, no hidden provider/billing, owner cohort, active subject, source rights/hash/version, fast revocation, invalid/expired session, General Help only when ready, no browser time spoof, localization.
4. `qa/sql_drafts/iclub_ai_topic_release_local_pg.psql` — synthetic scratch publication -> ready -> revoke -> disabled flow, all inside an explicit rollback transaction; **prepared, NOT EXECUTED on real PostgreSQL**.
5. `qa/ai-layer-v21-content-handoff-sql.test.cjs` — **13** static SQL tests (source only). Total **45/45** content-handoff tests passed in isolated GitHub-source JS/V8 execution. This does NOT certify native Node, Edge deployment or SQL execution.
6. `qa/run-ai-layer-v21-postgres-local.sh` can run `ICLUB_PGTEST_SUITE=release` on a **new empty local scratch** database, in addition to meter/math/practice. The unified `qa/run-ai-layer-v21-offline.cjs` includes the 2 new test files (20 suites total).

## Integration boundary before real users

The server must adapt `getPublishedRelease` to the actual service-only topic-readiness RPC and `getLiveSourceProof` to an independently verified **current** versioned source; neither may trust client readiness. A future *separately reviewed* authorized publisher must populate/update the private release table; no publication write path has been deployed yet.

Implement before any Preview/beta: JWT ownership and server-minted context on all relevant screens, release/cohort permission separate from content, per-locale source checks, safe immediate invalidation, user-facing panel status, atomic quota+provider safety and no double charges, local PG tests, full offline Node and browser acceptance. Avoid rebuilding Vercel for every editorial content addition; a single feature deployment followed by tightly governed server-side publication is the target.

**Existing Mathematics Exam Prep Tutor continues independently**, including its beta entitlements and original usage. This handoff cannot edit progress, question banks, cards, Tours, Practice, localStorage or production Supabase.

**Production changes / Supabase writes / Vercel builds for this deliverable: ZERO.**
