# Mathematics P1/P5 — protected V4.1 editorial repair and live DB source integrity
**2026-11-09 · Issue #450 · DRAFT only · PUBLIC HOLD**

This checkpoint supersedes only the protected-source fingerprint stated for V4 in older documents. The original V4/V3 archives are preserved. Do **not** repeat the completed 42-row import.

## Scope and actually observed errors
- Read all **42 private English mathematical conditions and worked solutions** in the V4 owner-private archive, plus a focused numerical and semantics comparison across RU/UZ. External Cambridge 9709 **2026–2027** official syllabus §1.3 confirms elementary circle/line tangency is in Paper 1 scope, and §5.4 confirms binomial/geometric questions are in Paper 5 scope. No claim of independent Cambridge examiner signoff.
- A real Russian P5 normal-quantile solution displayed a rounded **numerical value different from EN/UZ**. Recomputed the value with independent normal CDF/PPF at higher precision; corrected **one RU number**.
- In a P1 circle-tangent solution, added a missing overall positive factor in the displayed polynomial factorisation in **all three languages**. Same roots but algebraic equality is now exact.
- Corrected one awkward Russian mathematical phrase about tangent segments in a different P1 circle question.
- Exact three affected private task IDs are recorded in the **owner-private** review manifest, not in this public repository. **No answer keys or prompt bodies** appear here.

## Actual protected source
Owner-private Library:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_v4_1_PRIVATE_REVIEW_20261109.zip`

- Original immutable V4 source SHA256: `8f9d8aec32da6de43e9415f8ab2965b8d425809bc2e849e6e3d1f4a1ee612a88`.
- Reviewed **V4.1** source SHA256: `2bfcfc8b5f961a4905788cc8cb3e33c6c72f663230c2681149bec5a3d0e56666`.
- New private ZIP SHA256: `410a1052c87f5a9393eab05fca96935942214bf26b91188205c6e64bf70e5b9a`.
- Original V4 staging script in PR #511 had a **mistyped hash character**, meaning the legitimate private V4 source would have been refused by its real `check`/stage mode. This is now fixed and pinned to the verified V4.1 bytes in this new child draft. A separate source-only regression prevents using the stale pin again.
- Identifiers and bank version unchanged because **only three unpublished `draft` source rows** were surgically corrected, with zero historic Extra Hard attempts. No V3 source or student work rewritten.

## Live existing iClub_APP PostgreSQL 17.6
After verifying exactly three original row SHAs, the unchanged release pointer, **42 draft/pending rows**, and **zero** Extra Hard attempts, applied a **single guarded database transaction** updating only those three private candidate rows. It verifies all revised source fields, recalculated content SHA and the same 42-row pending-only state; any unexpected source/flag drift raises an exception and rolls back.

Independent **read-only postflight**: `md5(string_agg(content_sha256,'' ORDER BY task_key))` for all 42 private rows is **`8626763d403dfedc1a230eb49ec59c42`**, identical to the same aggregation computed from the private revised V4.1 source bytes. P1=24, P5=18, 42/42 pending drafts, Extra Hard attempts 0, public release `enabled=false, academic_approved=false, bank=original-v2`; `public.users=1476`, existing exam-prep sessions=548.

No change to `main`, Vercel, Practice, Tours, certificates, learner progress, other subjects, or cleanup. Paper execution and verified awarded marks remain separate; unknown written correctness is **not zero, a score, a grade or readiness**. No mandatory Mentor, no writing self-score.

## Academic difficulty remains a separate review
Private **AI editorial** screening, not external-examiner judgement, provisionally flagged **17/42** guided multistep exercises for difficulty strengthening; the other **25 are only candidates for genuinely nonroutine work**, not 25 certified Extra Hard. 42/42 structural/math source checks and three repairs do **not** elevate QA status. Language proofreading is not an independent RU/UZ signoff.

**Next:** strengthen those 17 privately and verify every changed worked solution/EN-RU-UZ equivalence, with new source SHA, then build a V4-specific content-fidelity publication candidate. Public bank switch and UI deployment still **NO_GO**. P0-16B remains independently unfinished; beta cleanup separately deferred.
