# iClub Chemistry 9701 — J-18 owner academic/rights attestation and release boundaries

Date: 2026-10-28. Source version `chemistry9701_20261022_stageb_draft`; preflight source snapshot MD5 `cfd46b6e603abf046a1c5a25be051086`.

## Explicit owner statement
In this project conversation on 2026-10-28 the application owner stated: **«формальное подтверждение академ проверки и прав даю я как владелец проекта»**.

This document records that the project owner **personally attests to and approves the academic-content and rights review for the prepared Chemistry package**, according to the owner's authority. The owner is the approving party; do not portray this as independent examination by the assistant, Cambridge International or a third-party licensing specialist.

The package under development contains **154 normal Theory skills + 12 cross-tour LAB skills = 166**, plus 462 locale-specific static Tutor-source records. The 12 LAB cards represent 6 AS/Paper 3 and 6 A/Paper 5 learning materials. The owner statement does NOT authorize publication, unlocking Chemistry features, new beta invitations, new A Level permissions, enabling generative AI Tutor, changing marks, or rewriting student history. It does not transfer copyright of any third-party source text.

## Separation of technical integration from learner rollout
Integration PR #388: https://github.com/jteshaboev1984-ops/iClub_APP/pull/388
Integration branch: `integration/chemistry-9701-rebased-main-20261028`.
- Existing user data/localStorage MUST remain untouched.
- All Chemistry switches remain OFF by default: Core, Entry, Recheck, P1, Paper 3, Paper 5, static Tutor. Legacy Mathematics/Economics/Practice/Tours continue their live behavior.
- Independent owner GO for learner release has **not** been given in this statement; the J12 `owner_explicit_go` and composite publish gate remain false.
- The Supabase J12 `rights_reviewed` operational flag has NOT been changed: recording owner approval in this document is distinct from a full reviewed release execution, and no bulk release/control mutation is permitted.
- No real learner consent or permissions are created.

## Technical checks and current limitations
- 2026-10-28 main reconciliation completed with a Git parent `ff5e64562a8b066ff0a2f1bd5026c934dd451151` and 0 divergence behind main at that checkpoint.
- 310/310 read-only SQL assertions and 82/82 synthetic Chemistry UI assertions passed on integrated code.
- Static script/cache and independent Chemistry CI are tracked separately from historical GitHub Actions workflows.
- The PR contains 33 Chemistry migration files already installed in production Supabase with identical version/name; do not reapply manually.
- Separate preview is Vercel-authenticated and not production.
- Backup **restore rehearsal has not been verified** (`backup_restore_tested=false` in live gate). Do not invoke `restore_project` on production. Supabase did not expose a read-only production backup-history or isolated restore-test operation through the connected tools.
- User's previous five J-14 UI checks passed on an **older Chemistry preview**, not proven on the final main-integrated SHA. Browser acceptance of the final integrated build is still a distinct check.
- Existing GitHub CI contains stale static asset/cache assertions (e.g. Economics written source requires the old `written-source-20261027` pin while current main uses the Oct 28 criteria source). New Chemistry CI should not mask unrelated failures. Do not alter functioning production asset references to satisfy old assertions.
- Do not claim comprehensive production readiness while unrelated checks fail.

## Explicit decision
**Academic/rights owner attestation: received and documented.**
**Production integration code: requires safe CI and final integrated preview.**
**Chemistry learner publication: NO GO; all gates OFF.**
