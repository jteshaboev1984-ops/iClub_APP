# iClub Mathematics P1/P5 — D09-05: follow-up guidance after a verified seven-day week

**2026-11-04 — DRAFT, NO_GO.** Extends the exact 70/70 GREEN [D09-04 PR #482](https://github.com/jteshaboev1984-ops/iClub_APP/pull/482) at SHA `9c803718680b4086e9f85d1e2e065e7e0bb6c73f`. Full tests must be rerun on this new candidate head; no inherited CI claim.

## Existing evidence & decision

The D09-04 server already calculates P1 and P5 independently measured diagnostic periods, freezes original verified Stage0 completion, preserves earlier weekly plans and one chosen Mathematics budget, and emits one receipt for each completed study week/month. But the existing weekly digest described only session counts and historical plan-goal adherence when their week-ending timestamp happened to match.

The validated P2-09 learner-specific **81-skill** remaining-work engine `private.exam_prep_remaining_work_internal_v1` provides objective observation, actual unresolved corrections, delayed retest, transfer, written activity and syllabus skill contract. It explicitly distinguishes unobserved knowledge from demonstrated weakness, never multiplies a wrong answer into an entire new course, and has no individually approved hour norms. That is the evidence to use, not self-reported hours or reconstructed Cambridge skill time.

## D09-05 change

- The EXISTING weekly claim function (one receipt per completed diagnostic-anchored seven-day period) adds `evidence_next_steps` only on a genuinely completed **weekly** summary. Monthly reporting and the existing session/grade/plan data remain unchanged.
- A new restricted, read-only helper takes the owner identity supplied by the existing guarded claim function and uses P2-09's current canonical 45 P1 + 36 P5 skill work. It selects **at most three** nonduplicated skill/phase candidates across the two papers, with one initial slot available per paper when both contain source-supported work. It orders existing actions (correction, due retest, mixed transfer, targeted practice, unobserved targeted check, written-work practice) without inventing new skills, tasks or answers.
- Records precisely `read_at=report_claim_time_not_historical_week_end`. Current state at actual claim is **not** misrepresented as the objective state on the week-ending date; if the learner opens the report days later, the follow-up actions describe what is currently pending. A frozen receipt preserves that original snapshot across devices.
- This is supplementary **guidance** to the existing protected priorities, not a new generator, an automatically accepted time recommendation or an assertion that a closed/partially observed skill is weak. The existing 1–3 weekly plan tasks, pending sessions, corrections, due retests, plan IDs and stages remain authoritative.
- The RU/UZ/EN existing report card displays a succinct 'What to check next' with Cambridge syllabus section and plain action text; never exposes internal state names or source identifiers. It is absent in earlier receipts and monthly reports. It does not add a fourth choice or a duplicate weekly message.
- `recommended_weekly_hours=null`, `recommended_daily_minutes=null`, `recommendation_accept_enabled=false` until **separately approved** academically reviewed workload intervals can justify a real numeric suggestion. A learner alone decides whether to maintain, adopt a future verified recommendation, or choose new time; existing D11 choices stay unchanged. No time cap, automatic grade, or alleged off-platform activity.
- Existing JS loader versions are bumped for a future controlled release only; no production hosting, flags or migrations changed here.

## Isolated acceptance

- A guarded disposable PG17 test uses genuinely completed synthetic Stage0/P1+P5 evidence produced by the existing real signed learner JWT→PostgREST→Chromium suite; it verifies exact 45+36 syllabus skills, each returned action's existence in actual remaining work, no duplicate phase billed as a full skill, max three, consistent replay, no fake hours, anonymous/private execute denial and unchanged sessions/corrections/report receipts.
- Separate *actual signed local* owner HTTP check confirms the fresh diagnostic has NOT produced a seven-day digest, anonymous claims are denied, and repeated dashboard entry does not create daily reminders.
- RU/UZ/EN × 390/1280 Chromium visual checks render factual recommendations for one observed P1 correction and one **unobserved** P5 targeted check, verify no technical jargon, no automatic schedule/plan writes, and no overflow.
- Keep the prior Stage D, JWT/PostgREST/PG17, 600–10 concurrency, P2-79 recovery and full exact-SHA test matrix. A complete seven-day report delivery simulation remains a separate evidence point unless CI explicitly exercises a genuine time-shifted week; do not claim that merely checking a helper tested future receipt delivery.

## Extra Hard (unchanged architect decision)

Keep the exact **original 12 problems** (six P1/six P5) already authored, with their original RU/UZ/EN texts and solutions. **No replacement generation.** The original content payload is absent from the rebuilt DRAFT public feature branch and not reliably recovered, so there is no authorized database import or release flag yet. This package adds no question or answer seed.

**No live database writes, main merge, rollout, Vercel deploy, cleanup, learner progress reset or mutation of Practice/Tours/certificates/Economics/Chemistry. Public NO_GO until separate architect GO.**
