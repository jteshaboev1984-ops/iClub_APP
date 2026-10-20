# iClub Global AI v2.1 — P4 governance handoff for 70 live Practice-source drafts
**20 October 2026 · existing QA branch only · NO-GO for expanded live rollout**

## Decision: reuse one independent editorial evidence mechanism, not a parallel approval system

The owner-approved Master Plan requires one source-backed AI, per-lesson/question/locale readiness, five distinct operational review responsibilities (Content Manager, Academic Reviewer, Rights Reviewer, Language Reviewer and technical QA), reviewed original content, precise context authority and unchanged Mathematics Exam Prep. Current closed beta for the **previous** 111 locale cards was separately owner-authorized; that approval does **not** extend to the 210 new closed drafts.

The older P4 QA publisher already includes a default-DENY Ed25519 verifier with reviewer trust registry, independent signed content/rights/technical roles, one-use scoped tickets and eight named release gates. **Reuse that crypto/signoff protocol only after a verified adapter exists**. Do not clone a second editorial approval chain simply to turn the new qbank beta on. Additional academic/language reviewer evidence must be explicitly represented and checked for this academic product; the older three-signature P4 QA alone does not establish independent academic/locale sign-off in the newly stipulated roles.

### Verified mismatches — automatic source promotion would be wrong

| Field | Live prepared academic beta | Older QA P4 publication source |
| --- | --- | --- |
| Surface | `practice_error` | `practice` |
| Feature | inferred from academic `surface_code` | `answer_explanation` |
| Question identity | `context_key='question_<id>'` | `topic_key='question_<id>'` |
| Content row | `private.iclub_ai_v21_academic_sources` | `private.iclub_ai_v21_editorial_source_versions` |
| Source identity | `source_card_key` | `source_id` |
| Content digest | `SHA256(UTF8(body_text))` | `SHA256(UTF8(source_text + LF + prepared_variants::text))` |
| Version counter | `publication_revision` of academic source | independently revisioned topic release row |
| Permissions | `private.iclub_ai_v21_source_admitted_v1` and special owner closed-beta allowlist | 8-gate release row + signed one-use ticket + Ed25519 verification |
| Locale | New qbank owner gate requires all **three** EN/RU/UZ release rows aligned together | Older P4 signer operates on **one** locale-specific topic release |
| Cohort | separately consented owner-controlled academic beta | signed editorial approval does not itself give owner rollout |

**Consequence:** changing `practice_error` to `practice` in a ticket, or copying `content_hash` into `source_hash`, does not establish an equivalent publication proof. Publisher data structures and hash contracts differ. Do not insert synthetic reviewer IDs, signoff references, credentials or approval booleans into production as a substitute. A passing old P4 synthetic publication suite does not authenticate a new live academic source.

## Reviewer packet completed; no answers or learner information exported

The existing CSV `docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv` now holds exactly **70 rows**, with source snapshots for **210 locale cards** (all EN/RU/UZ), live source/target SHA-256 per locale, and the existing eight issue flags.

At the verified production read-back: no source/target fingerprint mismatch, no already-open new source, no real new academic delivery. Hash snapshots are **not permanent**: they must be refreshed against the live bank immediately before any controlled release.

Each candidate is **not editorially approved**: the eight P4 named gates remain `PENDING`, cryptographically signed content/rights/technical evidence is `MISSING`, academic/language/owner approval is not present, and P4 compatibility is marked `DIFFERENT_SURFACE_AND_STORAGE__NO_AUTOMATIC_RELEASE`. Structural/hashing preflight `PASS` cannot imply any academic correctness or legal rights.

Three correction proposals (Chemistry #10095, Economics #9465 and #9723) remain in `docs/iclub-ai-v21-3-trilingual-curated-content-proposals-20261020.json` with all EN/RU/UZ texts, original SHA-256 and status `NOT_APPROVED_NOT_STAGED_NOT_RELEASED`. Other five flagged topics need **metadata/taxonomy** review, not forced changes to the historical question bank. A proposed AI-only text revision must be versioned via the QA-tested immutable archive rather than rewriting a student's original question.

## Smallest next safe technical implementation

1. Use existing **Ed25519** verifier `qa/ai-layer-v21-editorial-evidence.cjs`, not a second signing protocol. Before any real signer is provisioned, define how Content/Academic/Rights/Language/Technical responsibilities are authenticated distinctly and how one released trilingual packet is attested (per-locale/revision source proof; no implied approval for missing locales).
2. Build an explicit **fail-closed, separately versioned source adapter** for `practice_error` content that validates exact live question/source ownership, original and curated source digests, the P4 envelope digest (where applicable), subject/feature/locale, version and independent evidence. No route aliasing based only on text labels. Test stale SHA, cross-subject, dropped locales, revoked owner permission, already delivered archive, replay, missing reviewer, wrong content and swapped language.
3. Keep the two independent states separate: **editorially published** vs **owner-cohort allowed**. A topic may be academically signed yet unavailable because the beta is not authorized; owner beta alone cannot substitute for actual editorial sign-off on **new** content.
4. Introduce only the minimum reversible QA-tested schema adapter after owner explicitly approves a production release scope. Do **not** install old P4 scratch publisher SQL into working Supabase; its original guard forbids that. Retain old 111-card admission and current Math Tutor without automatic migration.
5. After authentic review and source release, use a real consenting eligible learner's naturally finalized incorrect Practice item for positive E2E. Never create a learner, modify answers/marks, or weaken active assessment controls for tests.

## Automated failsafe added
`qa/live_candidate/iclub-ai-v21-qbank-provenance.contract.test.cjs` cross-checks the 70-row snapshot: exact 35 Chemistry + 35 Economics, 210 unique source keys, all source/target digests correctly shaped, eight reviewer gates pending, no signatures, no owner authorization. It also asserts both the distinct P4 source/route grammars and digest formula. An additional negative check calls the **existing** P4 Ed25519 verifier: live `practice_error` route fails, converting it to `practice` without reviewer checks fails, and even eight claimed TRUE gates fail when the externally provisioned trust registry is missing.

**Production boundary:** no GitHub `main` push, Supabase migration, Vercel deploy, live user write, paid provider invocation, tariffs or existing Math Tutor edit. This file and CSV are editorial/technical handoff artifacts only; they do not constitute real academic publication.
