# Mathematics P1/P5 — D10-05: exact learner deadline arithmetic and narrowly scoped academic check

**2026-11-05 · DRAFT / no live writes / no additional access restriction · issue #450.**
Based on [DRAFT PR #488](https://github.com/jteshaboev1984-ops/iClub_APP/pull/488), verified **70/70** on exact SHA `e6fb8251de7cc2c6e77f311a8562cbd8c74437ff`.

## 1. Real numeric defect in an existing approximate recommendation

The P2-17 owner-only `get_exam_prep_simple_learning_timeline_with_hours_safe_v2` divided the existing iClub historical-2020-guided topic-based *illustrative* hours by **`weeks_to_exam` already rounded to 0.01 week** and rounded the final joint weekly target to the *nearest* 0.1 hour. This can produce a displayed target **below its own formula** and make an equal learner-selected weekly time appear sufficient even if it is below the continuous rate. A simple transparent arithmetic illustration: 50 proxy hours / 11 weeks = 4.5454… hours/week; nearest tenth gives 4.5, but rounding UP to one decimal gives 4.6.

**Limited repair:** redefine the same existing owner-only read RPC after all earlier migrations, preserving its identity, profile/diagnostic sources, every field and privilege. Use exact timestamp difference from the **already verified** `exam_at` and server `as_of` in each P1 and P5 component; do **not** consume two-decimal display week values for computation. For each single-paper and joint recommendation, round UP to the next tenth only after finding the original minimum constant one-budget rate:
```
w1 = (P1 exam_at − as_of) / 604800 seconds
w5 = (P5 exam_at − as_of) / 604800 seconds
joint = ceil(10 * max(hours_for_earlier_paper / weeks_until_earlier,
                      (P1_hours + P5_hours) / weeks_until_later)) / 10
paper = ceil(10 * existing_illustrative_paper_hours / exact_paper_weeks) / 10
```
P1 and P5 still share **ONE elective Mathematics weekly budget**, never independent additive capacity. Returned `weekly_pace_precision` identifies the method; `weekly_pace_is_verified_personal_requirement=false` explicitly preserves that this is an **unvalidated iClub planning heuristic**, not empirical personal learning time or Cambridge normative preparation hours. A higher figure is a **suggestion**, never an access quota or mandatory study demand. The student keeps all three consent actions **Keep / Accept / Choose another**; no schedule, profile or academic mark writes are added, and the existing total-budget guard is unchanged. No change to four-year date selection, Stage0 T0, weekly reports, lesson availability, reserve questions or historical learner IDs.

## 2. Actual source-level reserve scope check — no release change

Official [Cambridge Mathematics 9709 2026–27 syllabus, Paper 1 §1.7, printed p.22](https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf) and [2028–30 syllabus, same Paper 1 §1.7](https://www.cambridgeinternational.org/Images/744634-2028-2030-syllabus.pdf) distinguish **informal understanding of the idea of a limit** from **formal differentiation using the general first-principles method, which is NOT required**. This matters for the existing `P1-DIF-01` original 81-skill map, which mentions “limit definition in a simple case.”

**Read-only, production metadata audit (no user records and no answer keys):** exactly **6 published** owner-scoped objective items and **9 withheld reserve** objective items are currently mapped to `P1-DIF-01`; of the withheld items, **three** contain English wording referring to a limit or difference quotient. No currently published English prompt in this skill contains that explicit wording. The three withheld prompts could be informal secant-gradient concepts rather than an out-of-syllabus formal proof. **Do not automatically declare them wrong, do not promote/reject them from keyword matching alone, and do not copy protected question texts, IDs, answer choices or exact solutions into public GitHub.** A follow-up academic source examination should distinguish conceptual recognition from a compulsory formal proof before any routine content lifecycle decision. This note creates **no new learner/recommendation gate** and authorizes no live content state change.

## 3. Strict isolated verification

- `supabase/migrations/20261105081000_exam_prep_p1p5_weekly_pace_precision_v1.sql`: changes only calculation precision in the existing owner RPC; no database tables, triggers, keys, release flags or assessment mutations.
- `supabase/tests/p1p5_p3_d10_05_weekly_pace_precision_rollback.sql`: local PostgreSQL 17 only, exactly two disposable test learners and existing authorized owner context. Uses ordinary personal paper dates approximately four/five months ahead; recomputes exact independent timestamps, P1 and P5 per-paper rates, the **non-additive joint rate**, checks no under-rounding, checks that one paper alone still receives an approximate rate, verifies unchanged student-selected Math budget, preservation of another user's dates, and post-transaction **exact original profile/date ROLLBACK**. It does not claim these test dates are an official Cambridge examination schedule or that the unmeasured independent study hours are real.
- The existing full signed owner JWT/PostgREST/PG17 suite and Stage D consolidated release gate remain required. CI pass proves implementation behavior, not mathematical certainty of iClub personal learning estimates.

**Existing release status: DRAFT / public NO_GO pending architect decision; no new release blocker.** Original author-written 12 Extra Hard (6 P1/6 P5) are not present in the examined public draft branch; do not fabricate them. No `main` merge, real Supabase DDL/DML, Vercel deploy, reset of localStorage or learner records, Practice/Tours/certificate change, or anything outside Mathematics P1/P5.
