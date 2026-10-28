# Chemistry 9701 — J23 component readiness and controlled beta rollout plan
Date: 2026-10-28. Owner: iClub project. Implementation and multi-pass AI-assisted academic review: ChatGPT.
Plan status only. Does not authorize immediate student access and does not modify Supabase or user history.

## Authority and scope
Official Cambridge International Chemistry 9701 2025–2027 syllabus: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf
Secondary project structure: Tour Map v1.0 Chemistry (7 tours); Chemistry J08–J22 audit/release documents; Mathematics content governance/AI Safety/Beta Plan provide precedent but do not automatically confer Chemistry approval.
The official exam has AS Paper 1 (40 MCQ, 75m), Paper 2 (structured, 60 marks, 75m), Paper 3 (real practical, 40 marks, 120m), A Level Paper 4 (structured, 100 marks, 120m), Paper 5 (planning/analysis/evaluation, 30 marks, 75m). Do not call current beta complete AS Chemistry without P2 and real P3 competency.

## Actual 2026-10-28 production baseline (read-only)
- Theory: 154 cards = 91 AS skills and 63 A Level skills. 462 static Tutor locale records = 154 skills × EN/RU/UZ.
- Practical study material: 12 LAB cards, 6 Paper 3 AS + 6 Paper 5 A. These are NOT executable practical examinations.
- Entry: 22 original MCQs, owner-approved release manifest 0.
- Recheck: 22 independent MCQs, owner-approved release manifest 0.
- Paper 1: 45 private draft MCQs, including one flagged. 44 reviewed-private; six QA checks pending, one failed, zero secure-ready questions. The 40-question exam is blocked.
- Chemistry releases, active version, learner permissions and attempts: none; all gates OFF.
- Existing Mathematics Beta: three active, four membership records, plan ceiling 12. Never grant Chemistry implicitly based only on Mathematics membership.
- Academic content/right ownership already attested by project owner; not an independent Cambridge certification.
- Real database export is a separate owner-accepted follow-up, NOT completed; do not falsely set backup_restore_tested=true or silently circumvent the existing J12 composite publisher gate.

## Expert functions executed by assistant (not outsourced)
Each item will get a versioned evidence row and six separate reviewer passes:
1. Chemistry subject editor: independent calculation, coefficients, charges, units, significant figures, chemical conditions, reaction mechanisms, balanced equations, scientific correctness.
2. Cambridge 9701 syllabus auditor: exact learning outcome, AS/A boundary, paper type and command-word compliance, not just textbook chapter matching.
3. Assessment specialist: question originality, unambiguous answer, distractor quality, progression, test independence and topic balance; written-answer rubrics for future P2/P4.
4. EN/RU/UZ language reviewer: scientific and numerical semantic equivalence, notation, readable text and exactly equivalent answer choices.
5. Copyright and laboratory safety reviewer: independently authored iClub items, documented provenance, no unauthorised Cambridge/book reproduction, realistic supervised-lab caveats.
6. Product security/measurement reviewer: RLS, access/consent, key secrecy, no score/mastery from AI or from one diagnostic MCQ, source-version integrity, no progress loss.
Any unresolved or failed issue remains BLOCKED. These are AI-driven specialist passes and reproducible checks; never describe them as signed independent human expert or official Cambridge review.

## J23–J32 implementation sequence
| Phase | Deliverable | Pass criterion |
|---|---|---|
| J23. Academic source audit | Check all 154 Theory cards, 12 LAB, 462 static Tutor locale rows, 22 Entry, 22 Recheck and 45 P1 drafts; verify official syllabus and Tour Map alignment; maintain a row-by-row QA ledger. | 100% of proposed beta items have versioned source, syllabus point, independent scientific proof, three-language and rights QA; no unresolved errors in selected subset. |
| J24. AS Theory reader | Build/verify safe **AS-only** delivery of 91 cards on approved source hashes, no A Level 63 cards, Tutor or P5 spill. Correct 154+12 composite publisher incompatibility; preserve real 166 source count. | Only separately approved Chemistry beta accounts see AS theory; no unauthorized reads; no misleading backup signoff or generic library privilege widening. |
| J25. Consent & onboarding | Reuse existing Math Beta eligibility, expose opt-in only to active members, learner acknowledges Chemistry separately; record owner approval and easy revocation; prevent A Level access. | First one consensual canary user, then remaining active consenting Math Beta members; no automatic enrollment of all 12 planned seats or reset of Math history. |
| J26. Entry | Review and approve exactly 22/22 independent EN/RU/UZ question hashes; release manifest after owner/content confirmation. | Real authenticated 30m start/save/timeout/resume/finish/review, no early keys, no second attempt on same revealed form, 0 false mastery. |
| J27. Study/Recheck | Connect Entry mistakes to exact approved Theory skill page; review 22/22 distinct Recheck MCQs, with study acknowledgement and delayed retest option. | Entry history stable; no cross-account read; 3-language comparison by syllabus unit without grade/mastery claims; real user QA. |
| J28. Paper 1 | Resolve flagged question and six pending QA checks; independently verify 40 unique eligible MCQs, blueprint and source hashes, 75-min timer, scoring/review rules. | secure_ready_items ≥40, 40/40 approved, no key leak, genuine beta user flow, no answer/attempt loss. |
| J29. Paper 3 | Validate six AS P3 LAB learning cards; explain graphs, titration, qualitative analysis and safety within practical-learning scope. | 6/6 authenticated lessons, no hands-on practical exam claim, no automated laboratory competence or mastery credit. |
| J30. Tutor | FIRST: enable audited static topic explanations as a clearly named non-generative feature, with AS-only authorization. SECOND: build real generative Tutor only via server-verified source retrieval, privacy, assessment/answer firewall, prompt injection/rate controls and separate opt-in. | No AI Tutor claim until genuine model service passes security + 3-language + active-exam block tests. AI never changes academic state. |
| J31. Complete AS | Design and author original structured Paper 2 plus supervised-lab preparation and an honest Paper 3 learning/evidence path. | AS suite reflects P1+P2+P3; do not market earlier limited beta as a full AS exam simulator. |
| J32. A Level | Separate 63 A Theory, six P5 LAB, authentic P4 structured and P5 planning/analysis exam tasks; independently approved A Level learner cohort. | Explicit new owner/learner consent, independent P4/P5 QA and no AS-to-A access inheritance. |

## Release waves
- A: AS Theory only to separately consenting/approved existing active Math Beta users; start with a single canary.
- B: Entry -> exact Theory lesson -> Recheck, after each bank has complete separately approved 22-item manifest and authenticated browser QA.
- C: P1 only after 40 secure-ready source items and completed 40-question user acceptance. P3 six lessons can be independently opened with explicit practical-study-only label.
- D: Generative Tutor, Paper 2/3 completeness and A Level P4/P5 are independent later stages. Do not auto-activate them in Waves A–C.

## Non-negotiable safety test matrix
For each wave: read-only pre/post baseline of Math Exam Prep, Practice, Economics, Tours, Chemistry and consent; source digest/rights/version check; server grants and RLS; cross-user/anon/revocation denial; pre-final assessment answer protection; timer expiry, idempotent saving, internet interruption, mobile/desktop, RU/UZ/EN, keyboard and accessible display. Preserve all localStorage, archived sources, previous assessment evidence and history. Rollback/hide must disarm the feature without deleting records. Approval is for only the exact tested version and scope. Natural increases in live answer counts must not be mistaken for tampering.

## Definition of done
- Theory beta READY: 91 AS source cards approved and safely available to consented Chemistry beta accounts; 63 A, P5 and Tutor OFF.
- Entry/Recheck READY: 22+22 distinct approved source manifests, meaningful study path, owned evidence/history and real signed-in acceptance.
- P1 READY: 40 original, source-pinned, fully secure/approved MCQs, 75-minute valid form and safe answer lifecycle.
- Static explanation READY: reviewed authored text, not claimed as generative.
- AI Tutor READY: actual model integration with full safety gate; source-only records do not qualify.
- Full AS READY: adds Paper 2 structured and appropriate Paper 3 practical support.
- A Level READY: separately approved A Level scope and genuine Paper 4/Paper 5 workflows.

## First execution target
Begin with J23 content audit and J24 AS-only publisher review. Keep all user-facing Chemistry release switches OFF until the exact subset is approved and canary tested. No destructive SQL, no copying book text to public content, no fake signoffs, no production data reset.
