# iClub AI Layer — P5/P6 multi-subject readiness and source governance v2.1

**Date:** 2026-10-12 · **Status:** QA-only integration plan, no release approved.

The Master Plan is **app-wide**. Mathematics P1/P5 was first because its existing Tutor and live beta must remain untouched. P5/P6 extend the same independently gated architecture to Chemistry, Economics, Biology, Informatics, Tours, Practice, General Help, Home, Profile, English/SAT and eventual videos.

## Verified aggregate baseline (Supabase SELECT only)

| Surface / subject | Actual confirmed data | Current conclusion for NEW AI |
|---|---|---|
| Mathematics Exam Prep | 45 P1 + 36 P5 skills; 243 approved Tutor v3 locale cards; separate existing Math AI | Keep original working Tutor and its entitlement; **no automatic migration** |
| Economics Practice | 81 current approved cards / language (RU/UZ/EN): 80 answer explanations + 1 result context. Of 80, **4 exact question IDs**, 76 generic topic cards. 11 topic names per locale | QA candidates, not new AI released. Specific-error source requires exact matching question ID. |
| Chemistry Practice | 38 current approved cards / language. **33 exact question IDs**, 5 generic topic cards. 5 topic names per locale | QA candidates, not new AI released. Specific-error source requires exact matching question ID. |
| Biology | Subject is active; only global basic readiness with no verified adapter in current global AI subject registry | **Not ready** until source and per-topic/editorial QA are proven |
| Informatics | Subject is active; only global basic readiness with no verified adapter in current global AI subject registry | **Not ready** until source and per-topic/editorial QA are proven |
| Mathematics other screens | global readiness basic/no adapter | Do not equate ready Exam Prep with globally ready Mathematics |
| Tours | Server completion uses attempt status + separate finalized runtime + archive unlock; no governed per-topic content release established here | Show no specific protected explanation unless archive and exact source gate pass |
| General iClub Help | global basic / app_help_v1 adapter exists; NEW global UI/gateway disabled | Can be future safe navigation alternative only after separately validated content and live rollout |
| Home / Profile | No signed next-action / progress aggregate authority has yet been implemented for new AI | In development; do not infer personal progress from browser |
| English A1, A2, B1 / SAT / IELTS | Public subject rows exist but are currently inactive | No new AI use, no topic promotion |
| Videos | No verified transcript/timecode source established in this audit | AI cannot claim specific video content |

**Total:** 357 currently approved Practice source rows across three languages = 111 exact-question rows + 246 generic/topic/result rows. This is an aggregate count, **not** 357 fully usable AI responses. Exact source binding available only for **37 unique question IDs across subjects** (4 Economics + 33 Chemistry) over three languages. No conflicting approved exact-question sources were seen in the checked snapshot, but the new contract fails closed if multiple versions appear.

All current Practice cards have approved `original_iclub` rights and 64-character content hashes. **This verifies row metadata only**, not mathematical/scientific accuracy, source usefulness, learner comprehension, or complete content/editorial QA. Global AI remains `ui=false`, `gateway=false`, `generation=false`, `kill_switch=true`. Existing Practice AI policy remains `enabled=false`.

## Delivered QA integration

1. `qa/ai-layer-v21-subject-readiness-inventory.snapshot.json` — small, metadata-only inventory (no learner records, source keys, question text, or personal data), with **all 10 current subjects**, release blockers and exact-vs-generic counts. Never treat it as live authorization.
2. `qa/ai-layer-v21-cross-subject-admission.cjs` — **server-only synthetic admission** using authenticated learner's finalized Practice/Tour context, DB-derived active subject, topic evidence, current source proof, eight editorial/safety/readiness gates, exact locale and late rechecks. It does not bill, generate, change progress or expose answers. It keeps Mathematics on its dedicated legacy-preserving path.
3. `qa/ai-layer-v21-cross-subject-admission.test.cjs` — **25/25** tests PASS: Economics/Chemistry route isolation, subject spoofing, foreign users, active exams, incomplete Practice, generic fallback refusal, active/disabled subjects, locked Tours, revoked sources and entitlement, source/topic switch, context and language.
4. `qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql` — new **read-only service_role-only** proof function for *one exact answered question* in a finalized Economics/Chemistry Practice session; verifies current learner, real `practice_session_answers_v4`, subject from `public.subjects`, live source version/hash/rights, new AI kill switch and protected exam guard. Rejects missing **or ambiguous** approved source; **no topic-only fallback**. It does not return source/answer body or authorize billing. The SQL itself refuses production/nonlocal DB execution.
5. `qa/sql_drafts/iclub_ai_practice_exact_source_local_pg.psql` — synthetic isolated scratch PostgreSQL test with explicit rollback. Covers finalized chemistry/economics, foreign learner, unfinished and unanswered questions, inactive/non-approved subject, generic question source, wrong locale, denied rights, source ambiguity, protected exam and new AI disabled. **PREPARED, NOT EXECUTED.**
6. `qa/ai-layer-v21-cross-subject-sql.test.cjs` — **14/14 static tests** PASS, including service role, no academic writes, exact question proof, SQL scratch guards, no generic fallback, source conflicts, and subject inventory.
7. `qa/run-ai-layer-v21-postgres-local.sh` now allowlists `ICLUB_PGTEST_SUITE=practice` alongside math/meter, only for a **new empty localhost PostgreSQL** DB. No actual database test was performed.

## Rollout order and mandatory gates

- **P5 — after Practice result**: first integrate Economics and Chemistry only for those exact questions with strong proof, once approved by editorial QA and the owner. Do not release 76 generic Economics cards or 5 generic Chemistry cards as precise error explanations. Generic-topic explanations require a distinct feature/prompt route and separate source relevance review.
- **P5 — Tours**: prove archive opening and versioned Tour question source before enabling any answer, separately for each subject/tour/locale.
- **P6 — subjects**: Biology and Informatics need source-to-topic map, approval status, rights/content version, substantive accuracy/editorial signoff and RU/UZ/EN coverage. Any ready subset can be released after all eight gates, without waiting for entire subject. No guessed source if missing.
- **P6 — General Help, Home and Profile**: prepare verified help text and server-signed safe next-action/progress aggregates separately; never give academic answer or alter deterministic plan.
- **P6 — English/SAT/IELTS**: hold until subjects are active and independently governed. No English-course answer solely because app supports English language.
- **P7–P9**: preview-only 1:3 remains provisional. Release after actual local PostgreSQL concurrency/identity tests, native Node suite, source/locale/browser QA, protected synthetic Preview, cost analysis and explicit owner permission. Original Exam Prep stays independently functional under new AI OFF.

**Architectural rule:** Different subjects share an AI shell and eventual quota, but **never share unverified content, another subject's readiness, or protected academic records**. All subject/source toggles are server-controlled. No new Vercel deployment, Supabase mutation or active app route changed in this milestone.
