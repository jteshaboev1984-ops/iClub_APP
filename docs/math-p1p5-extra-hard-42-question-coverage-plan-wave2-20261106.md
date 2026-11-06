# Mathematics P1/P5 — Extra Hard full-course target: 42 optional challenges

## LATEST 2026-11-06 — complete protected authored corpus (42 of 42)

**The former 24/42 checkpoint below is historical.** A complete 42-task
owner-private source bank now exists: **P1=24, P5=18**, exactly three
different challenges in each of the eight P1 and six P5 strands.
The last 18 original tasks (12 P1/6 P5) were prepared EN/RU/UZ and
independently checked against symbolic, combinatorial and numerical mathematics
calculations (**18/18 passed**). Distinct source IDs, English question wording,
component allocation and official skill mapping were checked across all 42.
One ambiguous condition about sequential sampling was corrected in all
three languages before final hashing.

**Protected FULL42 source file** is stored in the owner's private Library:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_PRIVATE_20261106.zip`.
Its canonical protected JSON SHA-256 is
`c28ce95658c2237754179bc6e67b141f4c023b25d639dea393065aa21f656c58`;
do not commit/upload question text, answer keys or worked solutions to public Git.

**CRITICAL STATUS:** 42 authored and computationally checked, but only the
previous first 12 have internally approved trilingual and technical QA flags.
For the other 30, translations/technical review **remain PENDING** and
`lifecycle_status=draft`. No honest claim of external-expert review,
published content, exam grades or user access. The current original 12-only
importer MUST NOT be expanded by changing a count constant; it belongs to
the earlier v2 bank. Full 42 requires a **new versioned private importer**
and one controlled QA/publish decision, leaving learner data untouched.
The present PR only corrects the live-candidate catalog grouping of
geometric vs binomial distributions under syllabus section 5.4.
No current Supabase, user, localStorage or production deployment is changed.


**2026-11-06 · architect product decision · Issue #450 · DRAFT / no live release**

## Decision grounded in the actual program

The existing Extra Hard runtime allows **one durable attempt per student per task** and
is explicitly **optional, not graded and not part of exam/mastery scores**.
The original newly authored private bank contained **6 P1 + 6 P5 = 12 tasks**:
enough to check the feature during a short limited-use pilot, but a learner
could exhaust each component after only six challenges. Two P1 official
syllabus areas had **no independent dedicated task** (1.5 Trigonometry and
1.8 Integration); a composite differentiation/integration challenge does
not substitute for a dedicated integration task.

**Product target for the first fully developed course: 42 tasks**, not an
official Cambridge number, and not a mandatory 81-skill item bank.
Exactly three distinct, multistep optional challenges per academic strand:

| Course strand (mapped to 2026/27 approved canonical syllabus) | Target | Prepared as of 2026-11-06 |
|---|---:|---:|
| P1 1.1 Quadratics | 3 | 1 |
| P1 1.2 Functions | 3 | 1 |
| P1 1.3 Coordinate geometry | 3 | 1 |
| P1 1.4 Circular measure | 3 | 1 |
| P1 1.5 Trigonometry | 3 | 3 |
| P1 1.6 Series (including binomial) | 3 | 1 |
| P1 1.7 Differentiation | 3 | 1 |
| P1 1.8 Integration | 3 | 3 |
| **P1 subtotal** | **24** | **12** |
| P5 5.1 Data representation | 3 | 2 |
| P5 5.2 Permutations and combinations | 3 | 2 |
| P5 5.3 Probability | 3 | 2 |
| P5 5.4 Geometric distribution | 3 | 2 |
| P5 5.4 Binomial distribution | 3 | 2 |
| P5 5.5 Normal distribution | 3 | 2 |
| **P5 subtotal** | **18** | **12** |
| **TOTAL** | **42** | **24** |

**Remaining to author: 18** unique challenges: **12 P1 + 6 P5**. Do not
infer a 42-item quota from Cambridge, mandate challenges for learners, or
delay the existing accessible Mathematics Core because of optional work.

## Wave 1 (existing and separately held)

- 12 original, full EN/RU/UZ solutions: 6 P1, 6 P5
- Bank metadata: `math-extra-hard-2026-11-original-v2`; database stays EMPTY
  until a separate owner-approved import.
- Protected source in private Library:
  `/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_12_NEW_PRIVATE_20261106.zip`.
- Original 12-task importer still validates **exactly 12** and must never
  be tricked into accepting 24 by modifying a single constant.

## Wave 2 (new original protected candidates, not imported)

- 12 additional original multistep tasks, six each P1/P5, all EN/RU/UZ.
- P1: 3 distinct trigonometry tasks (equations, identities and transformed
  graphs); 3 distinct integration tasks (curve recovery, enclosed area,
  volume of revolution), filling the two previous dedicated-topic gaps.
- P5: an additional task each on pooled data, restricted committees,
  conditional probability/trees, geometric waiting time, binomial
  conditional tails, and normal approximation with continuity corrections.
- Original task keys and source scope checked against the original private
  bank and current 81 canonical skill codes. **12/12 programmatic
  symbolic/numeric results verified.** Language editorial review is
  **still PENDING**: the private package correctly leaves `qa_languages=pending`
  and `lifecycle_status=draft`, not a fabricated approved publication.
- Protected source Library path:
  `/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_12_EXPANSION_private_20261106.zip`.
  Source JSON SHA256:
  `f24f9965b9f842ea551a335b91769b16fd82ea920db9dd7367b8eba85420e916`.
  Answer keys/solutions must never be committed to public Git, static bundles
  or CI logs.

## New full 42 protected source checker (read-only, safe for local use)

`scripts/ops/p1p5-extra-hard-private-full42-check-v3.cjs` checks the
**exact owner-private full42 source checksum**, each of the 42 individual
SHA256 checks, precisely 24 P1 + 18 P5 tasks, 14 groups of three, unique
IDs and English source conditions, EN/RU/UZ presence and the honest
12 approved + 30 draft QA-state distribution. It does NOT stage/import
anything and does not reveal protected prompts, keys or solutions.

**Actual local owner-private check PASS** for SHA256
`c28ce95658c2237754179bc6e67b141f4c023b25d639dea393065aa21f656c58`.
A tampered source was rejected. Public CI only parses this script with
`node --check` and tests synthetic UI; the private JSON is NEVER sent
to GitHub/Actions. This is not approval to publish the 30 unreviewed drafts.
Future 42-row PostgreSQL staging is a separately gated follow-on.

## Runtime/product change for 42

A flat list of 42 options is cumbersome and does not show progress.
This DRAFT package extends the existing **owner-authenticated**
`get_my_exam_prep_extra_hard_catalog_safe_v1` to return only public
catalog metadata: official section, per-owner status
(`not_started`, `started`, `submitted`) and counts. The server still
returns protected prompts **only** on explicitly started attempts, and
worked solutions **only after durable submission**. Frontend groups
catalog entries into collapsible topical sections with RU/UZ/EN names
and shows **“Submitted N / total”** (never “correct”/exam grade).
The first unfinished topic opens by default; 390px and 1280px
Chromium acceptance is included.

No release, bank version, student attempt, AI, Mentor, grading or other
subject mutation is part of the catalog change. When the private bank
is OFF the original `content_preparing` experience remains unchanged.

## What is NOT done

The 12 expansion tasks are **private academic draft candidates**: not
staged, not published or externally edited. The current 12-task importer
is intentionally unchanged. Before a full 42-task release:
complete the remaining 18 unique tasks, review all 42 in EN/RU/UZ,
assemble a single immutable source-versioned protected 42-item bundle,
replace the old importer contract with a **separate tested 42-row version**,
then obtain owner authorization for the restricted import and publication.
There must be no live DML/DDL, backup wipe, production deploy or `main`
merge in this DRAFT.

**Do not erase any old genuine learner attempt:** a bank version change
must preserve prior answers if real rows ever exist. The previously
decided one-time **identified test-data-only** cleanup is independent.
