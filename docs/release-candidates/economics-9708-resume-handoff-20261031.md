# iClub Economics Exam Prep (9708) — verified handoff / safe resume

**Checkpoint:** 31 October 2026 (Asia/Tashkent). **Decision:** **HOLD / no learner rollout**. This handoff captures what was actually present at verification time; on the next work session **recheck the branch, issues, private Library versions and live read-only metadata** before editing anything.

**Repository:** `jteshaboev1984-ops/iClub_APP` (**PUBLIC**).
**Implementation branch:** `feat/economics-private-retest-gated-20261030`.
**PR:** [#430](https://github.com/jteshaboev1984-ops/iClub_APP/pull/430), OPEN **DRAFT**, **not merged**. Any code/SQL currently in this branch is not permission to deploy.
**Academic continuation:** [issue #435](https://github.com/jteshaboev1984-ops/iClub_APP/issues/435), OPEN.
**Other subjects:** [issue #432](https://github.com/jteshaboev1984-ops/iClub_APP/issues/432), OPEN, requires equivalent independently authored unseen same-skill correction for Mathematics, Chemistry, Biology, Computer Science and future subjects when their question banks are worked on.

## A. Completed work, separated by delivery type

### A1. Protected Economics academic work (never published in repo)

- **60 private first-form Economics MCQs:** P1 **30**, P3 **30**, separate original exam package. NOT the existing native live exam sources.
- **71 earlier private same-skill retest MCQs:** P1 **35**, P3 **36**, built for the **existing approved live native-skill set**, not interchangeable with the private 60 just because a skill ID looks alike.
- The prior 71 bank underwent multiple internal content revisions through **v9**: relative to v8, **18 distinct item records** changed (nine semantic redesigns and nine wording/provenance edits); **53 remained unchanged**. In **v10** exactly **50 previously missing textbook PDF chapter-start-page annotations** were filled (all 71 now have chapter-start pages); from v9→v10 **question text, options, keys, explanations and language fields did NOT change**. These are chapter *starts*, **not pinpoint verification of individual claims**.
- The prior **131-item internal academic ledger** covers the 60 originals + prior 71 retests, but **is not full blind/native-speaker or external-examiner certification**. User has no external experts; use independently structured **internal multi-pass QA**, disclosing its limits.
- Academic crosswalk of the private 60 against the older 71 identified **5 matching broad skill IDs** but only **3 matching actual diagnostic operations/facets**. Two were **false positive** (same skill ID, different operation); **do not relabel or reuse** those items.
- **2** further trilingual private questions were authored for those two mismatched facets. Therefore **5/60** private-original questions have *first-pass* same-facet retest candidates (**P1 4/30; P3 1/30**). **55/60** still lack alternatives (**P1 26, P3 29**). Current authored material across separate packages: **133 items (60 + 71 + 2)**; do not present them as one ready-to-serve bank.
- Existing 71 items are still not approved for publishing and are not a substitute for the **55** missing private-60 pairs.

### A2. Server security design and tests

- [PR #430](https://github.com/jteshaboev1984-ops/iClub_APP/pull/430) stages a **non-applied** SQL document: isolated private source/control/session tables; default global issuance **OFF**; private server-side answer keys and scoring; check current authenticated nonanonymous session, ownership of original **finalized incorrect** source answer, exact paper/skill; prevent previously seen/reissued items; idempotent retries, expiry and kill switch; old grade/history untouched.
- An early candidate SQL file was found damaged (truncated guard, broken dollar quoting and trailing duplicate statements) and **repaired**; the synthetic tests were expanded to catch future textual corruption.
- A second issue was found via read-only real native metadata: historical native MCQ item snapshots may identify exposure through `source_id` / `snapshot_md5`, **not** `item_key`. The un-applied SQL and fictional fixtures were improved to consider those real legacy fields for eligible known source provenance. NULL provenance never implies semantic novelty. See `docs/release-candidates/economics-retest-v9-admission-gate-20261031.md`.
- A disposable **PostgreSQL 17** service executed/compiled the staged SQL against **fictional** users, sources and exam attempts; verified authorization negatives, no pre-completion correct-answer leakage, server score, safe retry/duplicate submit, completed/expired anti-reissue, cross-user denial, revocation, and feature OFF. **Two simultaneous clients → one session.** A **fictional** `pg_dump` / `pg_restore` roundtrip retained synthetic history and privilege checks. This is **not proof** of real Supabase auth/REST/browser or production restoration.
- The automated synthetic gates were checked on PR head **`96c7c86d0cd48e4cbc014e060544252a44416aa3`** and all **three completed successfully**: Economics semantic revision, unified subject access and isolated PostgreSQL runtime. These checks only cover the scoped synthetic tests; verify them again after any subsequent code changes.
- Offline `scripts/qa-economics-private-retest-v9-integrity.cjs` is pinned to **v9**, **not v10**. Never state that it validated v10 or the two extra new questions. A later explicit v10/source audit is required.

### A3. Production and non-interference, observed 31 October

- **Read-only** production Supabase query found **none** of the new `private.iclub_econ_retest_control_v1`, `private.iclub_econ_retest_sources_v1`, or `private.iclub_econ_retest_sessions_v1` tables.
- Existing Economics native attempt count was **3** at checkpoint (do not freeze or edit this count; live users may add attempts later).
- There was **no production SQL apply, bank import, Vercel feature rollout, historical attempt rescore, registration/localStorage reset, or learner release** in the work described here. Do not assume an absence of changes by other concurrent work without verifying anew.
- No real Supabase staging/auth/JWT/REST/RLS/browser integration test or production-grade recovery rehearsal is complete.

## B. Exact private source pointers and integrity anchors

**Only private Library `/iClub APP/Exam Prep/`**, not public GitHub, PR comments or frontend assets. Before academic edits, find, materialize and SHA-256 verify these exact byte files:

| File (all filenames are under private Library folder) | Byte SHA-256 |
|---|---|
| `iClub_Economics_P1_30_original_independent_paper_DISTRACTORS_REVISED_PRIVATE_v4_20261030.json` | `ba2e076e6fde0f6597c9cd1a5e3bb9e4bb6ca704bc34df34b64` |
| `iClub_Economics_P3_30_original_independent_paper_SOURCE_DEPENDENCIES_FIXED_PRIVATE_v4_20261030.json` | `effcaf1165e7b8e348a0f137d847d4060c74f54a69c30204df992184622dbb4c` |
| **Current prior-native-skill retest 71, private v10 HOLD:** `Economics_9708_P1_P3_71_Same_Skill_Retest_BOOK_PAGE_PROVENANCE_COMPLETED_PRIVATE_HOLD_v10_20261031.json` | `94a1399dd95adbd758a3abef89bc208eebd58d8807c8f755dce33a714c84eff8` |
| **Current work queue / 60-to-retest exact-facet crosswalk:** `Economics_9708_60_Originals_Retest_Coverage_After_Two_Actual_New_Facet_Questions_PRIVATE_HOLD_v2_20261031.json` | `e657abfe9ca02c6ff460859b88303d34de4bc3730ae5a5deb795a73767da03e7` |
| Two new EN/RU/UZ same-facet questions, separately HELD: `Economics_9708_Private60_Two_Diagnostic_Skill_Facet_Retests_Trilingual_INTERNAL_HOLD_20261031.json` | `58680d2c8b0d83e912657c1a19537303cc5d5fa8da2a8b408519596b3c66b367` |
| Private original 131-item QA ledger (does **not** cover final 2): `Economics_9708_131_Original_and_Retest_Academic_Integrity_Review_PRIVATE_HOLD_20261031.json` | `5dc7057bec0f5aaae935db3750e7b2c217aab39c9ebf6efdcc2fba81edd8e092` |
| v10 source-page QA metadata: `Economics_9708_71_Book_Source_Page_Integrity_v10_PRIVATE_20261031.json` | `95a9a184dbe99a83b8622f1c82803cb4c9340b5232f4ed6fc1007f1e80536922` |

Earlier immutable versions v8/v9/semantic revisions remain in private Library for provenance; **do not overwrite/delete historic versions**. See `docs/release-candidates/economics-academic-checkpoint-20261031.md` for exact details.

## C. Exact next-work priority (NO code/release work first)

**Start at [#435](https://github.com/jteshaboev1984-ops/iClub_APP/issues/435).** The immediate academic goal is to create and critically review **55 missing exact-diagnostic-facet alternatives** for the *private* first-form 60 question set (**26 P1, 29 P3**). Read `unpaired_original_exam_items` from the private coverage v2 crosswalk, never copy that private item list into this public repository.

For each new item: check original paper/versioned skill/syllabus/AO **and diagnostic operation**; independently author non-memorisable, not-yet-seen EN/RU/UZ MCQ; solve without using the drafted answer; check unique key and all distractors, calculations, source/rights and language equivalence; independently compare semantics with live/Practice/Tours, private 60 and 71. Preserve separate private version and QA ledger; recalculate hashes. Incrementally regenerate an audited 60→60 exact-facet crosswalk. Meaningful batches suggested in the academic checkpoint: P1 13+13, P3 15+14. Document only counts/digests/next blockers in issue #435.

**Do not confuse scope:** The earlier request for *academic verification of the existing 71* is not automatically the same task as adding 55 retests for the *new private 60*. The currently most urgent identified gap is **55 missing pairs**. Academic internal verification of all 71, last v10 provenance, and later variants still requires honest evidence coverage; never assume v9 structure tests, 131 ledger or two new items amount to complete reviewer sign-off.

Once 60/60 valid first-pass retests and multi-pass academic review are independently recorded: assess second/third distinct alternatives, verify no old question exposure, plan a real **separate Supabase staging environment** and rollback/backup safety, test authentic JWT/REST/RLS and mobile/web UI, then request **explicit architect decision** before any controlled learner beta.

## D. Absolute boundaries / no-go

- Keep `release_enabled=false`, `ready_for_public_exam=false`, `ready_for_server_authorization=false`, `private_server_import_status=not_imported`, `retest_authorization_status=hold`. No academic document, test green tick or PR merge automatically grants permission to enable.
- **Do not merge PR #430**, apply draft SQL/migrations, import protected keys into public Supabase, upload protected item text into PUBLIC GitHub/Vercel static/browser/localStorage, or authorize normal users without explicit separate release decision.
- Never rewrite existing native Econ exams, Practice, Tours, attempts, grades, certificates, ratings, lesson progression, local user data or other subjects to make tests pass.
- All academic source text, private correct answers and individualized audit ledgers stay in the **private Library**. Public repo contains only harmless aggregate metadata, scripts and synthetic fixtures.
- No external human expert is currently available. Use **internal multi-pass academic QA**; report actual test methods and remaining uncertainty, **not** `independent external expert approved` or `Cambridge certified`.

## E. One-line next-chat handoff

> Continue iClub Economics 9708 from GitHub issue #435 and `docs/release-candidates/economics-9708-resume-handoff-20261031.md` (PR #430 still DRAFT). Verify private P1/P3 60 originals and private 60→retest coverage v2 against recorded hashes. **Author, fix and privately save the 55 missing exact-facet EN/RU/UZ independent retests (26 P1 / 29 P3), with independently checked keys, semantic separation and updated crosswalk, in substantive batches.** Preserve the old 71 v10 for its original live-skill use; do not merge, import or change production until separate academic/staging/release gates and explicit architect approval.
