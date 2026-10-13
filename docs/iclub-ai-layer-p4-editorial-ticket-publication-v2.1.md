# iClub AI Layer v2.1 — P4 Editorial Publication & Safety Revocation (Technical Handoff)

**Verified:** 2026-10-13 · **Status:** QA-only, scratch PostgreSQL; production and academic content unchanged.

## Exact Master Plan scope

This workstream implements the **technical side of ingestion and release**, not the academic side. Explanations, cards, translations, examples, sources, question correctness and editorial evaluation are authored/reviewed **in another chat and content workflow**. The global AI remains OFF until the owner separately authorizes deployment, rollout, cohort and model budget.

This milestone implements the **permission transition** missing between independent, approved source proof (P2) and the future editorial publishing workflow (P4). It does **not** install a publisher in Supabase. The code deliberately remains only under `qa/sql_drafts/` with a local-scratch-only guard.

## Technical artifacts

| Artifact | Responsibility |
|---|---|
| `qa/sql_drafts/iclub_ai_editorial_ticket_publisher_v21_UNAPPLIED.sql` | Private one-use publishing/revocation tickets, independent reviewer signoffs, and atomic SQL functions |
| `qa/sql_drafts/iclub_ai_editorial_ticket_local_pg.psql` | Synthetic scratch fixture testing all publish and revoke transitions and partial transaction failures |
| `qa/ai-layer-v21-editorial-ticket-sql.test.cjs` | Node security invariants and explicit assertion that learner-serving Deno adapter has **no** publisher RPC |
| `qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` | Existing independent source rights, checksum and exact lesson/question access gate |
| `qa/sql_drafts/iclub_ai_topic_release_gate_v21_UNAPPLIED.sql` | Existing per-surface/subject/feature/topic/locale eight-gate read-only release registry |

## Publication contract and separation of authority

A future **separately reviewed and authorized editorial ingestion tool** must submit an immutable, pre-validated, version-scoped ticket for a source prepared by the content workflow. The technical contract includes:

- **Scope:** `surface_code`, `subject_key`, `feature_code`, `topic_key`, `locale` (RU/UZ/EN), `source_id`, `source_version`, and SHA-256 `source_hash`.
- **Independent evidence:** eight named release gates from the Master Plan — content approved, rights approved, source version verified, correctness passed, negative tests passed, exam security passed, locale verified and accessibility passed. Each gate must be explicitly true; existence or number of cards never substitutes for evidence.
- **Three distinct reviewer identities:** content, rights and technical signoffs, keyed by the **same ticket**. A single identity cannot sign multiple domains on the same ticket (unique database constraint). Review records are **out-of-band** and cannot be created via the learner service.
- **Single-use, bounded validity:** unique ticket ID, expiry and `used_at`. Stale, unsigned, expired or consumed approvals cannot be replayed. Transactional row and advisory locks plus expected publication revision prevent races and stale overwrites.
- **Exact current payload hash:** PostgreSQL independently recomputes SHA-256 of the current version's source content and canonical prepared variants, and compares it with the ticket. The source/release update and ticket consumption are **one transaction**. Missing material, conflict, quarantined or already approved scope fails closed.
- **No automatic learner rollout:** this permission transition is only the editorial *topic* state. Live runtime OFF, protected exams, learner cohort, subject authorization, future monetary provider budget and quota remain independent required gates.

For **safety revocation**, the editor/safety workflow stages a separate one-use ticket with a written reason and a distinct `safety` review domain. With the exact current version, hash, scope and expected revision, the authorized publication executor atomically changes the release to `suspended`, disables the feature, increases revision and suspends that content version. Current source proof and bundle access then deny; pre-existing learner contexts cannot read the revoked material. A future corrected version requires a fresh verified ticket and editorial approvals; the suspended version is **not automatically re-enabled**.

**Privilege boundary:** the two publish/revoke functions are NOT executable by `public`, `anon`, `authenticated`, or Supabase `service_role`. Only the **dedicated QA `iclub_ai_v21_editorial_publisher` NOLOGIN role** receives EXECUTE. The learner-serving `qa/edge_v21/supabase_services.ts` includes **zero** publisher RPC calls. This is an isolation proof in the scratch database, not a claim that a production publisher account has been provisioned.

No academic source or real student record is included in this handoff. Example strings in test data are synthetic routing receipts only, never production content.

## Failure behavior verified on actual PostgreSQL

- Source inserted without reviewer ticket → **not ready**.
- Missing reviewers, missing any of the eight gates or mismatched expected revision → **no publication**.
- Valid distinct signed reviewers + exact version and digest → published precisely one topic/language; RU does not enable UZ.
- Replaying the same ticket or submitting another publish ticket against an already-approved topic → **denied**.
- Revocation without safety ticket/reason, wrong revision or duplicate use → **denied**.
- Approved safety suspension → source proof and old session bundle immediately fail on subsequent checks; academic source and learner progress remain untouched.
- **Forced failure after the source-state UPDATE, before release-row INSERT:** entire operation rolled back, source remained draft, ticket remained unused, no release appeared. After removing the synthetic trigger, the request was completed correctly.
- Published topic + global kill switch ON → **still unavailable**. Editorial publication never silently turns on the app or provider.

## Native QA evidence

[**GitHub Actions run 38355636618**](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38355636618) — SUCCESS.

- **418/418** real Node.js 22 tests, including 12 editorial security tests.
- **40/40** native Deno 2 tests with strict TypeScript check.
- **9/9** real isolated PostgreSQL 16 scratch test suites: meter, mathematics, practice, release, claim, atomic, context, source and **publisher**.
- Existing Mathematics Exam Prep subject-isolation regression and protected-file comparisons GREEN.
- Cross-connection request claim race and atomic quota rollback GREEN. Scratch synthetic fixture rows were rolled back; ephemeral databases destroyed.
- GitHub workflow has no Supabase/project/provider credentials and performs no production or Vercel deployment.

## Remaining deployment gates (NO-GO until explicit approval)

1. Editorial packet ingestion, reviewer identity verification, genuine evidence provenance, rights review, and separate publishing credentials must be designed and audited with the **content workstream**. The QA ticket tables do not establish a real editorial authority.
2. A production-safe and reversible migration/RLS/role plan requires explicit architect permission. Scratch SQL contains local database guards and must NEVER be copied directly into the production migration directory.
3. Remaining read-only server authority for runtime, exam protection, rollout, pricing and provider monetary budget is not yet deployed. No paid provider integration or real-user migration exists.
4. Supabase Edge bundler/runtime parity, shared durable authentication and UI navigation/refresh logic, one protected synthetic Preview, mobile RU/UZ/EN QA and owner-approved beta follow later.
5. Retention and deletion of minimal ticket/revision audit records need a privacy/replay design. Revocation is effective on the **next server validation**, not a guarantee of cancelling a response already delivered to the user's device.
6. **Do not automatically publish content** merely because another chat created a card. All eight editorial checks, distinct signoffs, checksum, locale, explicit per-topic activation and independent global runtime/owner release must succeed.

**Production:** unchanged. **Real users:** no data changed. **Original Math Exam Prep:** unchanged.
