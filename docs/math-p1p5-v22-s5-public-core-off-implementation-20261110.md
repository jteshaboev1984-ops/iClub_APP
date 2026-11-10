# Mathematics P1/P5 S5 — guarded public access channel, source-only OFF

**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) · **Date:** 2026-11-10 · **Status:** ISOLATED DRAFT, no public GO · **Parent:** [S4 DRAFT #523](https://github.com/jteshaboev1984-ops/iClub_APP/pull/523).

## Real live state (SELECT-only; no production changes)
Existing legacy `private.exam_prep_feature_config` is `controlled_beta`, `core_enabled=true`, `ai_enabled=true`, `mentor_enabled=false`, `kill_switch=false`, `qa_open_all_core=true`. The existing **beta AI tutor** is not the future per-tariff AI handwritten Paper marking. New S4 is not yet installed in production, and S5 public channel does not exist there. Existing `public.user_subjects` Mathematics id **5** has only `mode='study'` and `mode='competitive'` in current data; both should be eligible for the future public Mathematics *only* when enrolled. No student should be forced to choose competition to learn.

## Source implemented

`supabase/migrations/20261110120000_exam_prep_math_s5_public_core_access_off_v1.sql` adds:
- Independent singleton `private.exam_prep_public_math_s5_config_v1` with **`public_math_core_enabled=false` and `public_math_kill_switch=true`**, fail-closed release evidence check. No update to the existing feature config or any existing attempts, skills, answers, users or certificates.
- `private.exam_prep_s5_public_math_eligible_v1(uuid)`: Math subject **id 5**, enrollment `study` **OR** `competitive`; verified `public.users` identity; current programme Core not switched off and legacy kill switch not set; and the independent owner-GO flag released. No guest or another subject can gain access via this *new public* branch.
- `private.exam_prep_s5_require_public_math_v1()`: strict private public-path authenticator; denies missing auth, anonymous registration, non-Math enrollment, public switch OFF and kill switch. Does not permit old `qa_open_all_core` to impersonate an enrolled Math student on the public path.
- `private.exam_prep_s5_require_beta_or_public_math_v1()`: **versioned future integration reader**. While public flag is OFF it delegates to the ACTUAL `private.exam_prep_require_core_access_v1()` (no recreated beta access rules). After explicit public GO it can allow an enrolled public Math student or keep a legitimately entitled beta user; **not yet wired to old public endpoints**.
- `public.get_exam_prep_s5_public_math_status_safe_v1()`: per-requester owner-bound read-only status; distinguishes existing controlled-beta eligibility vs new public Math entitlement without granting access itself. Direct config access is denied to anon/authenticated; `public` status RPC is only granted to `authenticated`.

## What this does NOT do
It does **not** enable public Core, change the already active controlled beta, alter AI subscription tiers, add mandatory Mentor, affect Economics/Chemistry/Biology/CS, reset local/Tours/Practice/certificates, or merge/ship anything. It also does **not** automatically splice a new authorizer into every existing Exam Prep RPC. Such wiring can introduce silent public access and must be part of the **ONE planned source-stable S6 integration** with explicit tests and a separate S7 GO. An eligible student can have a public preview status of **false** today; that is the correct safe default.

## S6 acceptance targets, to execute ONCE when workflows can start
- Signed JWT+PostgREST positive cases: registered student with Mathematics id 5 in either study/competitive mode; verify the future public access grants only after independent owner-GO state in a **disposable** DB.
- Denials: anon role, registered user without Mathematics enrollment, other-subject-only student, expired token, spoofed `user_id`, stale beta entitlement, controlled-beta tenant without subject 5 on the **strict public** path, independent public kill switch and existing programme kill switch.
- With S5 flag **OFF**, old controlled-beta function and its policies remain unchanged; historical Exams, Tours, Practice, Extra Hard and certificates retain checksums/counts and student ownership.
- The new S4 hybrid Paper remain independent and feature OFF; nonblocking 1/2/3 Paper practice and unchanged verified-skill/correction gates, absolutely no student score or self-grade.
- Mobile RU/UZ/EN entry only after the fully assembled auth pathway is wired; no special blocker based on mentor, AI plan or uploaded handwriting.

## Next
**S6 integration (not another isolated microtest):** reconcile #519 S2, #520 S3, #522 S4 decision, #523 S4 runtime, then this S5 source branch against current main with no accidental migration or old-progress DML. Integrate the new guarded Math public authorization into the final candidate **only after checking the exact old beta-authorizer behaviour**. Run one meaningful comprehensive PG17 + JWT/PostgREST + Chromium pass **when GitHub can create jobs**. Produce source exact SHA plus proposal for owner-controlled S7 release. Public mass access remains OFF until separate explicit architect GO; P0-16B remains OPEN; beta cleanup forbidden without its own GO.
