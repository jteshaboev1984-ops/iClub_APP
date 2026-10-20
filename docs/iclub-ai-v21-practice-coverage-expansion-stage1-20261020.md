# iClub Global AI v2.1 — first reachable Practice coverage expansion
**20 October 2026 · controlled beta · data-only source intake · QA branch**

## Verified production starting point
- `main` / Vercel READY: `7ea6c2960e6be1b1c46bf7b8506ee3106ad974e7`; last `practice_after` fix deployed.
- Supabase `mmmduffgpvwjdpruzikw`, Edge `iclub-ai-v21-prepared` v5 ACTIVE/JWT ON.
- Academic policy ON; provider OFF; 111 exact existing owner-released RU/UZ/EN cards (37 question IDs), all integrity/admission checks pass.
- Three preselected beta members, one enabled/consented at snapshot, zero **real** academic deliveries. Previous GitHub browser/DB fixture PASS is **not** a signed student E2E success.

## Material student-reachability finding (the priority)
- Each subject has 490 active questions in 7 active Practice pools (70 per tour).
- Of the 37 owner-released exact question IDs, only **10 chemistry** questions and **0 economics** questions belong to active Practice pools.
- Another 27 source question IDs are active in the main question bank but absent from active Practice pools. Changing pool membership to force exposure would disturb an existing production assessment setup; **do not do that**.
- All 490 active Practice questions per subject already contain EN/RU/UZ database explanations, but database availability is not independent source QA or permission to publish through Global AI. Some chemistry explanations are too short. Many Economics explanations label the correct option as "Selected answer", which could be misunderstood as the student's own selected option in a review.
- Result: nominal catalog coverage (37 source questions) and **actually pool-reachable** source coverage (10) were being confused.

## Finished stage: 70 new exact-question, closed draft candidates (210 locale entries)
One existing **data-only** content route was used, **without any JS, Edge, UI, pool, user or tariff change**.

- Source SQL: `qa/live_candidate/iclub_ai_v21_practice_70_candidate_staging_20261020.sql`.
- Applied migration: `iclub_ai_v21_stage_70_reachable_practice_drafts_20261020`, result SUCCESS.
- 5 active Practice questions per tour × 7 tours × 2 subjects = 70 **new** questions; all have EN/RU/UZ copies from their existing iClub question records.
- Exact source keys, version, SHA-256 of explanation and SHA-256 fingerprint of live question were recorded.
- Criteria: published active bank question, active Practice pool, eligible `mcq/input`, 100+ characters in each localized explanation, minimum original question length; for Economics, excluded templates using "Selected answer:" or "Selected:".
- Favoured different subtopics per tour. These filters are **technical pre-screening**, not scientific/linguistic publication QA.
- **Every new source has `published=false`, `revoked=true`, all four independent review flags false and `approved_at=NULL`.** No owner-beta grant was created for the new 210 cards.

| Tour | Chemistry new IDs | Economics new IDs |
| --- | --- | --- |
| 1 | 9241, 9272, 10069, 10071, 10073 | 9391, 9411, 9413, 9418, 9420 |
| 2 | 8515, 8547, 10075, 10076, 10078 | 9462, 9465, 9472, 9474, 9477 |
| 3 | 3098, 3113, 9734, 10061, 10077 | 9549, 9551, 9560, 9562, 9565 |
| 4 | 3348, 3362, 3368, 3393, 10062 | 9599, 9601, 9615, 9617, 9620 |
| 5 | 4381, 9790, 9791, 9792, 9793 | 9659, 9665, 9674, 9675, 10097 |
| 6 | 4738, 9814, 10063, 10080, 10081 | 9722, 9723, 9727, 9730, 10098 |
| 7 | 5318, 10085, 10088, 10090, 10095 | 9901, 9907, 9913, 9915, 9916 |

## Post-migration facts and acceptance
| Invariant | Observed |
| --- | --- |
| Total source rows | 321 (111 prior + 210 new) |
| Exact question IDs in registry | 107 (37 prior + 70 new) |
| New closed/unpublished rows | 210/210 |
| New erroneously published or reviewed | 0 |
| Prior admitted owner-beta rows | 111/111 (unchanged) |
| Existing owner release records | 111 (unchanged) |
| Fingerprint mismatches | 0 |
| Source-text SHA mismatches | 0 |
| Existing general Help published rows | 39 |
| Academic real deliveries | 0 |
| Provider generation | OFF |
| `main` production | unchanged / READY |

**Student reality:** 70 newly staged questions cannot yet return an AI academic explanation. Only the existing 111 owner-released source cards remain admitted; among these only 10 question IDs appear in active Practice pools. The *potential* pool-reachable question count after release would be 80 (45 chemistry + 35 economics), subject to learner access/unlocks and complete QA. No release has yet occurred.

## Editorial issues that matter, not cosmetic QA
- Verify accurate, original and age-appropriate explanations in EN/RU/UZ against exact active question, answer and options. Source presence/length does not establish correctness or rights.
- Example metadata mislabelled in current production bank: chemistry #10073 names magnesium oxide in subtopic but asks combustion of a C/H/O compound; #10077 names sulfur sulfate but asks to balance a MnO4− half-reaction; #10063 labels "Buffer action" but asks quantitative electrolysis. **Do not rewrite history-bearing questions or assessment marks** to fix these; govern metadata corrections separately.
- New drafts originate from the `questions.explanation_{en,ru,uz}` columns, not legacy approved `private.practice_ai_source_cards` rows. The current owner-beta admission function deliberately requires a matching old `approved/original_iclub` exact card, hence an owner allowlist entry alone would NOT make these drafts deliverable. This is a **real generic provenance/approval integration task**, not something to bypass by forging legacy approvals.
- The owner decision on **the earlier 111** cannot be silently treated as editorial sign-off or automatic beta-release authorization for **210 new** entries.

## Next coherent release work
1. Review this 70-question editorial queue academically, check EN/RU/UZ equivalence and rights, and correct new draft text by a new source version rather than editing question histories. Check the flagged metadata against real question meanings.
2. Establish once, in isolated QA, a **generic verifiable new-source provenance branch** for owner-controlled beta that is not hard-coupled to legacy `practice_ai_source_cards` (no subject hardcoding), while keeping strict prior rights and 111-card guard. Or use genuinely independently governed publication when that workflow is operational. No false flags.
3. Only after the governed new batch and explicit owner release conditions are met, release source rows via general registry; do not alter active Practice pools. Then monitor real successful student deliveries, wrong vs correct vs unanswered, three locales, quota and unchanged marks.
4. Preserve Math Tutor, already accepted Option A mark and UI, source revocation, existing 3-person cohort and separate consent. Real student E2E remains to be demonstrated in an actual eligible incorrect finalized Practice attempt.

Rollback is independent: new sources are already `revoked=true` and invisible, existing owner-academic beta may be paused with `qa/live_candidate/iclub_ai_v21_owner_beta_PAUSE_20261020.sql`. No legacy tables, localStorage or end-user progress were modified by this stage.
