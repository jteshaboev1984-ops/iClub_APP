# iClub Chemistry 9701 — J-08: protected learner ENTRY integration (27.10.2026)

**Status: IMPLEMENTED IN EXISTING ISOLATED BRANCH; RELEASE OFF.**
Branch: `work/chemistry-9701-j02-auth-host-20261026`. No new branch created, no PR/merge into `main`, no Vercel production deployment, no user enrollment or real test sessions.

## Boundaries / real app safety

- Reuses existing Mathematics controlled-beta cohort **by reference**, active Chemistry subject selection, and the separate Chemistry-specific opt-in/owner approval. Does **not** create a new student cohort, reuse P1 attempts, change Mathematics/Economics/Practice, or touch localStorage.
- Chemistry ENTRY has an **independent owner kill-switch**, exact 22-item release manifest and release-version registry. All are **empty/OFF**. The global Chemistry program remains `draft` and `launch_enabled=false`, Chemistry library hidden, P1 independently OFF.
- **22 original, trilingual J-07 entry questions stay in private Supabase.** The public GitHub branch contains only SQL structures/functions/QA metadata, UI code, test fixtures with fake question strings, and this report. No original stems, options, answer keys or explanations in public commits.
- Existing J-07 item rows are immutable `can_issue_learner=false` / `can_grade_mastery=false`. A separate, owner-approved **exact content hash** per item and a signed-off manifest are prerequisites for issuance; source items remain archival drafts. No unlock has been performed.
- The source-to-lesson map originally depended on the Chemistry paper **draft-only preview**. During a transaction-local `published` test the map stopped seeing the Theory/Tutor cards. Replaced it with stable links to `private.iclub_subject_library_theory` and `private.iclub_subject_library_tutor`. Both EN/RU/UZ source coverage and 22 out of 22 skills survive a hypothetical publish/rollback. This fix is documented as its own migration.

## User APIs and ownership

All are `SECURITY DEFINER`, with `search_path=''`, explicit `auth.uid()` checks, owner/subject/cohort/consent/release gates, private session ownership, authenticated-only EXECUTE and no anon grants.

- `public.get_my_exam_prep_chemistry_entry_shell_v1(language)`: shows nothing unless all 22 approved versions + exactly matching manifest are ready; never opens via beta flag alone.
- `public.iclub_exam_chemistry_entry_start_v1(client_key)`: independently owned 22-question 30-minute source-pinned attempt; one active per learner. Idempotent resume, serialized on the authenticated account ID.
- `..._get_v1(session_id,language)`: RU/UZ/EN localized questions and displayed choice order. **No correct letter or explanation before finalization**.
- `..._answer_v1(session_id,order,choice)`: server-only atomic save/revision, no writes past the deadline.
- `..._finish_v1(session_id)`: server-side 0–22 score, idempotent, missing answers score zero; no learning/mastery award.
- `..._history_v1()`: only the signed-in learner's latest 20 sessions.
- `..._review_v1(session_id,language)`: completed session only, 22 matched syllabus topic/skill titles linked to Theory sources; priority is errors and skipped items. Response explicitly `can_credit_mastery=false`, `calibrated_diagnostic=false`, `one_question_per_topic_not_mastery`.
- Additional unique `(user_id,source_manifest_md5)` protection means **the same disclosed entry form cannot be retaken** under a different nonce. Reopening returns the existing finalized attempt and result. A genuinely new source manifest is required for a new entry assessment.

## UI in existing shared host

- Added `exam-prep/exam-prep-chemistry-entry-native.js` and conditional server-shell integration in the **existing** `exam-prep-host.js`; `index.html` loads the module only. If ENTRY is allowed, ENTRY is shown first; if only Chemistry P1 is allowed, its existing screen remains. Both can be opened separately; Maths and Economics mounts are unchanged.
- Accessible 22-question selection grid, 30-minute timer, explicit missing-answer confirmation, auto-next unanswered, safe loss-of-connection recovery from authoritative server state, three languages, own history, finished result and post-final explanations.
- The result links **specific syllabus skill and topic titles** to a study-to-review list, then offers **back to existing Chemistry subject learning materials**. **Not yet a one-click deep link into a specific lesson**; a separate exact navigation contract for Tours/Theory is required rather than guessing a URL or bypassing content permissions. Existing Chemistry theory itself remains hidden until separate approved release.
- No misleading verified mastery, diagnosis validity, guaranteed grades, Tutor premium access or automatic P1 credit.
- Existing `ep-native-chemistry` styling and responsive 40-question map/list styles reused; no broad CSS or page restructuring.

## Positive and negative verification

- SQL positive flow in a **single BEGIN / ROLLBACK** using JWT **simulations of two actual Mathematics Beta account identifiers** (not a real browser sign-in): transient owner release of the 22 hashes, program publish, separate opt-in, get/switch RU/UZ/EN, no early answer-key leak, save/correct a choice, intentionally one wrong/one skipped, final **20/22 with 21 submitted**, idempotent finish, own review and history, cross-account get/save/finish denied, opt-in withdrawal blocks access without deleting the session. All changes rolled back.
- Additional transaction-local expiry test: post-deadline answers denied, scoring remains immutable; release manifest shell check required 22/22 hashes.
- Additional anti-memorisation test: second start with **new client nonce** after finalize returns the original session/result and creates no second attempt for the same source hash. Fully rolled back.
- Repeatable synthetic JavaScript test: `node scripts/qa-chemistry-9701-j08-entry-ui.cjs` — **11/11 PASS**; 12 extra source/loader checks passed; no actual browser or real student account used.
- Repeatable production **READ ONLY**: `scripts/qa-chemistry-9701-j08-entry-auth-host-readonly.sql` — **39/39 PASS**. At this checkpoint: ENTRY attempts 0, releases 0, Chemistry opt-ins 0, Chemistry P1 attempts 0, Chemistry launch flags OFF. Mathematics 544 sessions/1,979 responses; Practice 502 attempts/4,816 answers; Economics one native attempt; legacy 26 Chemistry originals all retained. The original 45 private P1 drafts and 40+4 P1 editorial version remain untouched.
- Supabase security advisor: INFO on private FORCE RLS tables intentionally with no policies; WARN on authenticated SECURITY DEFINER RPCs, which explicitly enforce current user/cohort/consent/content/session ownership and cannot be called by anon. Re-review at actual real-device beta sign-in. See [Supabase SECURITY DEFINER advisor guidance](https://supabase.com/docs/guides/observability/advisors?queryGroups=lint&lint=0029_authenticated_security_definer_function_executable).

## Next exact stage J-09

1. Create **new, distinct unseen follow-up/recheck items** (beyond this 22-item entry and 40-item P1 exam), with quality checks and protected source hashes. Avoid repeating an already reviewed answer as a diagnostic.
2. Ground and integrate exact skill/topic → actual student-reachable Tours/Theory lesson navigation without bypassing hidden content or AI Tutor restrictions; separate mastery credit and delayed recheck evidence from a one-item entry orientation.
3. Real desktop/mobile browser, keyboard/accessibility/network QA, with explicit consent on the existing Math Beta cohort and owner GO. These **have not been performed** in J-08. No new Chemistry access until permission and content authorization.
4. Before final merge, reconcile newer unrelated `main` commits (branch presently behind), preserve Economics and Maths latest. Do not overwrite newer production files, delete old branches with unique work, or reset any learner progress.

**No beta release, merge, PR, Vercel deploy or real-user database modifications were performed in J-08.**
