# J-19 — Chemistry integration CI triage, owner preview acceptance and release hold

Date: 2026-10-28
PR: https://github.com/jteshaboev1984-ops/iClub_APP/pull/388
Current integration head before this report: `36466a06ca8ce2e7360b64c03a18351ead7b68bb`.
Current merged-in main parent: `dc85016406f9ab9eeab2887703a1610382f121ab`.

## Release evidence
- Owner acceptance: **3/3 OK**, signed in chat, on protected preview `dpl_8uv2zfcJgcAEYapGvdfpUU2xomdn`, SHA `b595a4ce1f9e782508ed7d83f6d9e18619054069`. See J-19 acceptance document.
- Subsequent re-sync with `main` was limited to unrelated Practice AI CI and quota migration, plus docs; GitHub tree SHA comparison confirmed **10/10 byte-identical production runtime entry and Exam Prep files** between accepted preview commit and current integration head: index.html, host.js/css, four Chemistry scripts, Exam Prep API/Live, Economics native JS. Therefore owner visual acceptance still targets the exact same relevant client code.
- Dedicated Chemistry CI: **two SUCCESS runs** on current integration commit; prior live SQL read-only 310/310 and isolated UI 82/82 PASS.
- Live Supabase snapshot on this date: Mathematics `private.exam_prep_responses`=1979, Practice `public.practice_answers`=4846 and `practice_attempts`=505, Chemistry LAB DRAFT=12, Chemistry P5/A approvals=0, Tutor approvals=0; `can_publish=false`, P3/P5/Tutor OFF. These counts are a read-only observation, **not a database backup**, not a before/after transaction audit.
- Chemistry package owner academic/rights approval is recorded in J-18. **No owner release GO** for new learner access or Chemistry publication.

## Eight currently failing legacy CI jobs — observed causes
From the GitHub Actions job logs of PR #388:
1. `written-source-gate`: `scripts/qa-economics-written-source-gate.cjs` insists on the old `written-core-view-v1.js?v=written-source-20261027` pin; actual working main uses the Oct 28 `econ-assessment-criteria-nohints-20261028` version.
2. `global-qa`: `scripts/math-practice-v2-publish-gate-contract.cjs` expects `reviewback1-postpublish1` in the app loader tag; current main loads `app.js?lesson-fidelity-20261020`. The actual Practice reset protection code remains checked independently.
3. `release-regression`: old workflow and `practice-content-language-preservation.cjs` require exact previous `app.js?v=...` strings; current main uses the new loader. Static step aborted before browser acceptance.
4. `topic-choice`: real mobile topic choice synthetic test passed, then `scripts/practice-review-back-regression.cjs` failed at old cache marker `ptopic1-reviewback1` while current main references `practice-topic-choice.js?v=ptopic3-release1-loadingpolish1`.
5. `clean-core`: `practice-content-language-preservation.cjs:47` expects a prior `app.js?v=support4...` cache tag. Current app loader is different; this is a stale assertion, not by itself a demonstrated learner data reset.
6. `conversations-safety`: Global AI conversation contract demands `global-ai-ui.css?v=globalaichat1`, but this Global AI UI asset is **not referenced in current main index**. This may reflect a deliberately dormant feature; release policy must be confirmed before altering it. **Do not bypass a live-shell requirement to obtain green CI.**
7. `shell-safety`: same missing Global AI shell stylesheet/JS expectation. **Needs product-level assessment**, not a blind tag injection.
8. `practice-ai-foundation`: `ai2_practice_review_ui_contract.js` identifies `app.js?v=` as the application loader, so its ordering check fails on current `app.js?lesson-fidelity-20261020` even though `practice-ai-ui.js?v=ai2review1` is after the actual app script.

**Important:** Both baseline and integration use byte-identical copies of these historic JS test files. A failing old string assertion is evidence of stale checks; it does NOT establish that the complete failing job is fixed, and does NOT justify suppressing checks. Do not rewrite or relabel checks as green without restoring their meaningful invariants. Separate test maintenance from Chemistry release.

## Unresolved high-impact conditions
- Live Chemistry release gate still has `backup_restore_tested=false`. No read-only isolated restore API was available via the connected Supabase tools. **Do not restore production.**
- GitHub PR #388 is still **DRAFT / mergeable_state=unstable** with eight red checks. **Do not merge into production while this state persists**, notwithstanding successful Chemistry-specific CI and owner's visual approval.
- Chemistry remains fully dormant, with no user approvals or content publish.
- Future work: independent CI repair on current main, synthetic and real browser safety regression, isolated database restore proof or explicit approved equivalent backup-recovery signoff, and then separate code merge review. Learner Chemistry opening still requires a different owner's release GO.
