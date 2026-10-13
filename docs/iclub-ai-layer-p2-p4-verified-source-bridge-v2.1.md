# iClub AI Layer v2.1 — P2/P4 Verified Source Bridge

**Date:** 2026-10-13 · **State:** real Node/Deno/PostgreSQL QA GREEN. This is an **UNAPPLIED TECHNICAL DRAFT**, not a deployment or editorial publication.

## Master Plan alignment and ownership

Implements approved decisions **3A, 12A, 21A, 24A, 30A, 33B, 34A, 35A, 38C, 39A, 40A, 42A, 43A**. This workstream implements **AI technical integration only**. Academic explanations, questions, approved card variants, theory, translations and source rights assessment are produced and signed off in the **separate content conversation/workflow**. No real content, subject-bank change, model/provider call or student data change was made here.

**Contract:** editorial source published + private release row with eight approvals + independently recomputed content digest + current rights/version/locale + current authenticated server screen + cohort/kill switch = *candidate* AI source readiness. This does NOT alone authorize generating a response, debiting units or starting beta. A topic not satisfying all checks returns **«В разработке»** rather than a guessed explanation.

## QA-only technical receiver

**`qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql`** introduces a private versioned source receiver and two read-only service-role functions. No content publisher/writer function or public table grant is included.

1. **`private.iclub_ai_v21_editorial_source_versions`** is keyed by exact **surface × subject × feature × topic × locale × source ID × version**. It carries metadata, current source payload and approved prepared variants, independently of the existing `private.iclub_ai_topic_release_v21` release-approval table. Both default to non-published/not-ready; runtime, rights, integrity, editorial QA and conflict flags default closed.
2. **`get_iclub_ai_v21_source_proof_service`** checks global runtime flags, exact published release and all eight gates, exact source version, rights, integrity/QA, absence of conflict and **fresh SHA-256 of actual payload**. Returns only metadata to the privileged Edge; never text, an answer key or a learner record.
3. **`get_iclub_ai_v21_source_bundle_service`** accepts an authenticated user and opaque server-minted context handle, resolves the **current** screen through the verified v2.1 server context RPC, then checks exact topic/source/version/hash/publication revision/locale against the release row and independently verified source. A prepared route returns **only the single approved action key** (never the full prepared-variant catalog). A generated route returns only the short approved source passage, with no unrelated prepared variants. Invalid routes, missing card, stale context, other subjects or languages deny; no fallback or user answer leakage.
4. **Digest contract for a future separately approved content publisher:** SHA-256 over the UTF-8 bytes of `source_text + LF + canonical PostgreSQL jsonb::text(prepared_variants)`. The publisher must recompute and version the digest; any post-approval change invalidates the source. This is a deliberately testable technical interchange format; do not insert content or approve rollout in this chat.

The function names and signatures match the existing QA Deno adapter `qa/edge_v21/supabase_services.ts`. They are **not present in production Supabase**. No academic source body was authored in the code; the PostgreSQL fixture uses synthetic transport strings solely to test access control.

## Security regression found and corrected

Native PostgreSQL detected that a **nonexistent prepared variant** could be accepted with JSON `null`: PostgreSQL `jsonb_typeof(missing_variant)` returns SQL NULL, and `NULL <> 'string'` does not evaluate to true in a PL/pgSQL IF. The safety condition was corrected to `IS DISTINCT FROM 'string'`, which reliably denies missing/null/non-string entries. The full real PostgreSQL end-to-end test, including the missing prepared key, has since passed.

## Verified tests

[**GitHub Actions #38354487650**](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38354487650) — **SUCCESS**, QA commit `c0d95159f99e0700798d57c65f7c060ebd0777cd`.

- **406/406 native Node.js 22 tests** across 24 suites; additional **8/8** tariff smoke checks and original Mathematics subject isolation regression GREEN.
- **40/40 Deno 2 tests** including strict TypeScript Edge check and four new exact source-proof/RPC contract cases.
- **8/8 real PostgreSQL 16 scratch-only suites**: meter, math, practice, release, claim, atomic, context and **source**. Plus real two-connection request claim race and injected transaction rollback tests.
- New source SQL fixture explicitly verifies no publication from mere source insertion, exact verified hash, exact prepared reply, missing card denial, only approved source for generation, foreign learner rejection, RU/UZ isolation, stale revision denial, tampered content hash, rights revocation, feature suspension, cross-subject navigation, and protected exam denial. Synthetic setup and all test rows were rolled back, scratch DBs destroyed.
- Protected production Mathematics Exam Prep source, original migrations and app entrypoints were checked unchanged by CI; no production or Supabase writes, Vercel deployment, paid model or test on real learners.

## Remaining NO-GO before beta/Preview

- **No editorial publisher is installed**. A later separately reviewed server-side publication workflow must atomically approve a particular source hash/locale/topic with an authorized reviewer. Inserting new content by itself is NOT sufficient to activate new iClub AI.
- **Global runtime, protected-assessment/rollout, pricing policy and provider-budget service adapters** still require real schema-level review and privileged implementation. Beta and external provider remain OFF.
- **Source security beyond digest**: approved lesson passages must be independently checked for contamination, rights, exact question/answer-key restrictions, prompt injection, response safety and academic accuracy. A hash proves integrity, not truth or educational correctness.
- **Real Supabase Edge bundling and one protected Preview** must be verified with synthetic data, mobile RU/UZ/EN and retained production parity before any owner-approved rollout. No migration has been deployed.
- Content production, editorial review and lesson/question writing remain **entirely in the other chat**. This milestone is solely a technical receiver.

**Status:** QA verified, **NOT installed in production**. Kill switch / rollout disabled; existing Mathematics Exam Prep and learner progress entirely unchanged.
