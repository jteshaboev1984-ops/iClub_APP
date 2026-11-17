# UX #531 — second owner review: saturated blue Study, one My plan, scalable history

2026-11-17 · Source-only Draft · Canonical tracker Issue #531 · Academic data integrity Issue #450

## Owner's specific feedback
1. Pinned Study remains in the same blue family as Competitive, but has less visual prominence; the previous `#75A5EB → #C1DAFA` looked washed out.
2. Separate 'План экзамена' duplicates 'Мой план'; put every real preference and action into 'Мой план'.
3. History must show three latest records and expandable older entries in sets of five; decide what happens after 70–90 records and whether deletion/automatic cleaning is appropriate.
4. Inspect other iClub screens for the same long-list problem.

## Exact source facts
- Competitive Home CSS: `#174AAB → #3071E1` white text and prominent shadow. This Draft changes **only pinned Study** to `#5689D2 → #6196DD → #74A2E1`, navy `#071E3D`, border and softer elevation. This is a true blue gradient, not grey/white/pastel; title-label contrast on darkest stop >=4.5:1.
- `exam-prep/exam-prep-live.js`: old `renderProfile` was separate form for exam series, target grade, total weekly study hours, Mathematics hours; existing `renderMyPlan` already offered schedule, confirmed P1/P5 exam dates, weekly choice/reports and an Edit profile action.
- This Draft unifies initial profile setup and later editing **inside My plan** using the same `saveExamProfile` RPC and validation. First save still takes learner to P1/P5; an unsuccessful save keeps the unsaved form values. No new access/mandatory hours policy or legacy data mutations.
- History has **two independent sources**: Core objective/diagnostic results vs *ungraded* S4 Paper executions. Core `get_exam_prep_recent_results_safe_v1(text,int)` has a hard server limit of 20 and written extension delegates to this function. Paper `get_exam_prep_hybrid_s4_history_safe_v1(text)` has a hard server limit of 30. Previous UI asked for only 10 Core and showed up to 30 Paper, potentially all on one page.
- New UI asks for at most 20 Core and 30 Paper, independently shows latest **3** for each, opens an accessible native disclosure for older records, appends **5** records per click, preserves original owner-authorized review, separate P1/P5 and ungraded Paper. If the server cap is reached, a small honest note says only recent entries are available. **This is local progressive disclosure, not unimplemented server pagination.**
- No delete/archive mutations, no client-only fake counters, no new library or paid service, no learner records touched.

## How to scale when history reaches 70–90 or 900
**Next design proposal, NOT implemented nor authorized:** owner-scoped server-side cursor pagination per (component, record type). Return 3 newest on first page, batches of 5 afterwards. Sort by `(finalized_at DESC,id DESC)` for Core and `(started_at DESC,id DESC)` for Paper with tie-breaker; signed or validated cursor, `has_more`, optional count, explicit server-side permission, bounded page size, indexed filter on user/component/time. Never download 90 records at initial screen opening, never rely on client slicing of a 20-row RPC response, never merge ungraded Paper into graded Core score. Preserve active/open Paper and current attempts. Test two learners, locale, pagination under concurrent new attempts, null dates, rerenders and authorized session review. New API/migration/release requires separate owner approval and signed PostgreSQL17/JWT/PostgREST/Chromium evidence.

## Retention / deletion proposal: release HOLD
- **Do not auto-delete academic history** just because a learner has 70/90 records. Record count is a UI/pagination issue, not a data-retention justification. Exam Prep evidence feeds progress, correction history, reporting and readiness; deleting records could corrupt projections.
- Differentiate: (a) hide/archive a record from a learner-facing list while preserving server-authoritative audit/progress; (b) safe removal of cache or notification UI state; (c) irreversible personal-data deletion only under an approved account/retention lifecycle. These are different operations and permissions.
- If owner chooses a user-facing hide option later: require exact affected records/ownership, a visible explanation that it does not erase academic results or rankings, audit and recovery semantics, anti-manipulation checks. No student-controlled deletion of official competitive Tour scores, ranks, certificates, verified academic evidence or original answers without an independently approved retention/deletion policy.
- Any age-based data deletion requires a written policy: categories, legal/educational purpose, retention period, consent/notice, access rights, backups, recovery, downstream aggregates and audit. **No period, scheduled cleanup, archival SQL, soft-hide column, timer, feature flag or data change is approved by this Draft.**

## Other real iClub surfaces to inspect (read-only, not changed)
1. `practice-topic-choice.js` already trims a topic Practice preview to three recent attempts; `practice-results-tabs.js` shows recent attempt preview five and has a separate fuller history surface. Check its server cap and navigation back behavior before adopting a shared cursor convention.
2. `app.js` Notifications already supports a per-row user-scoped `deleted_at` *soft hide* and a confirmed Clear all. Notification hiding is **not** an acceptable precedent for deleting scored student work; notification lists still deserve bounded loading.
3. `app.js` Archive filters by season and loads Tour attempts to derive per-tour results; preserve competition evidence and certificates. For a large number of seasons/attempts, review server filtering and pagination, not deletion.
4. `app.js` Certificates has a season selector; a long list should group by season/year or bounded batches without removing verifiable documents.
5. `app.js` Ratings and existing Practice histories are read-oriented lists that may need pagination/virtualization under real volumes; review their actual query limits separately. Do not alter competitive rules in a UX PR.

## Verification / release gates
Source-only isolated Draft from exact published `main`; adapted Chromium tests must check RU/UZ/EN, widths 320/375/390/430/1440, initial setup, failed save retention, inline re-edit, P1 and P5, Core/Paper 3+5 disclosure, no writes/attempt starts on browse, original history review buttons and objective-vs-Paper separation. Full source hashes of answer-ACK and profile API remain pinned in their existing guard workflows. Main/prod/rollout/SQL/student-data untouched; separate owner GO needed to publish.

UI rationale is consistent with NN/g's documented advice that goal-oriented lists often benefit from user-controlled "Load More" or pagination rather than endless infinite scrolling. This is a design recommendation, not a claim about other specific apps' internal retention policies.
