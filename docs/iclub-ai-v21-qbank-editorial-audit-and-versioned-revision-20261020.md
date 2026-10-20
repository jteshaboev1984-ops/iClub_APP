# iClub AI v2.1 — source-level audit and independently curated explanation revisions
**20 October 2026 · existing QA branch · editorial review HOLD**

## Live baseline and scope
- No production AI code deploy, no production question/pool/marks modification.
- Existing owner-released beta: 111 admitted locale cards (37 question IDs), 10 pool-reachable IDs, zero confirmed learner academic deliveries at readback.
- New source candidates: **70 distinct questions** / **210 locale drafts**, Chemistry 35, Economics 35, exactly five questions per each active Practice tour. Entire new batch is `published=false,revoked=true`, not independently reviewed or owner-released.
- New technical metadata preflight `qa/live_candidate/iclub_ai_v21_qbank_editorial_preflight_READ_ONLY_20261020.sql` executed with **70/70 metadata_preflight_ok**. Verifies original live question, active pool, three locales, revision parity, exact draft text, two SHA-256 hashes, answer-key basic shape, and absence of accidental publication; it intentionally returns `PENDING_HUMAN_ACADEMIC_RIGHTS_LOCALE_AND_OWNER_RELEASE` even for technically valid records.
- Human academic accuracy, language fidelity, authorship/licensing and official editorial approval **NOT COMPLETE**. The 70 EN stems/keys/explanations were AI-assisted screened; selected 20 high-risk calculations were additionally checked against their RU/UZ explanation. Do **not** interpret this as independent full three-language review for all 70.

## Eight specific editorial issues — exact question IDs
| Subject | Question | Risk | Required governed action |
|---|---:|---|---|
| Chemistry | 9241 | Subtopic says `Moles of aluminium` but asks symbolic X₂/Y₂ limiting reagent | Metadata-label review |
| Chemistry | 10063 | Subtopic `Buffer action` but question computes Faraday / Avogadro constant from electrolysis | Metadata-label review |
| Chemistry | 10073 | Subtopic `Empirical formula of magnesium oxide` but question derives an organic C/H/O molecular formula | Metadata-label review |
| Chemistry | 10077 | Subtopic `Oxidation number of sulfur in sulfate` but question balances the permanganate half-equation | Metadata-label review |
| Chemistry | 10081 | Topic calls reaction-order work `non-integer` while worked exponents are A=0 and B=2 | Confirm taxonomy/label |
| Chemistry | 10095 | EN final sentence `An achiral HCN addition` is ambiguous for a racemic result | Clarify phrase in an independently versioned explanation; verify translations |
| Economics | 9465 | UZ explanation gives result 120 vs 130 but omits the explicit injection/leakage sum components | Restore transparent calculation steps in revised UZ explanation |
| Economics | 9723 | RU and UZ explanations give numeric price/output but omit the two explicit simultaneous equilibrium equations shown in EN | Add equations to revised RU/UZ explanations |

These are editorial *observations*, not proof of an incorrect answer key or mathematical result. There are **no authorized new grade revisions**. All 70 remain pending reviewer signoff, even if no specific flag is listed. The 70-row editorial queue records these eight holds and remediation instructions: `docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv`.

## Architectural issue discovered and repaired in QA only
The first reusable provenance gate accepted the new database explanation only if `AI source text == questions.explanation_{en,ru,uz}`. That prevented genuine quality improvements without editing live questions, contradicting the promised content versioning and user-history isolation.

**Corrected QA design** (in `qa/live_candidate/iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql`):
- `original_iclub_question_bank`: pin `original_source_hash`, exact original text plus current question fingerprint; preserve all previous constraints.
- `original_iclub_curated_revision`: separate updated AI source text is allowed *without modifying any question bank row*; additionally pin exact original-source text hash, new version and content hash, current question target hash and one shared editorial revision reference for all EN/RU/UZ. All three locale release records must be explicitly enabled and corresponding source versions must match.
- Existing original 111-card legacy predicate preserved literally.
- New source release registry is still empty/default OFF; evidence reference strings are neither actual human signatures nor proof of rights by themselves. Separate independent reviewer records/owner release are required before use.

The automated isolated PostgreSQL test covers positive deliberately synthetic three-locale editorial correction, stale original hash, mismatched revision proof, partial locale enablement, revocation, edited source without updated hash, version drift and inactive Practice pools. It uses **synthetic records only**; never authentic users, live progress or test registrations.

## Strict release boundary and next actions
1. Independent academic Content Manager and reviewers verify every question with its real subject syllabus, source rights, answer key, EN/RU/UZ clarity, and flagged issues; keep signed evidence in the proper operating workflow (do not insert fake evidence refs).
2. Prepare new versioned academic explanations for flagged copies, preserving old immutable versions and scores. Do **not** modify `public.questions` or earlier student grades under this AI task.
3. QA any approved release set in a disposable scratch DB; manually GO/NO-GO with the owner. **No mass source authorization, no auto-open for the additional 210 entries.**
4. Deploy the general provenance gate only in a separately approved production release; installing an empty gate on its own cannot improve learner coverage. Then introduce reviewed batches through the central registry, not new per-subject code.
5. Observe actual consenting beta students' authentic finalized wrong-answer flow, no quota or score regression. Never force a user answer for demonstration.

## State and artifacts
- QA branch `qa/iclub-ai-layer-v21-20261012`; no new branch.
- Source preflight `qa/live_candidate/iclub_ai_v21_qbank_editorial_preflight_READ_ONLY_20261020.sql` verified against real Supabase through read-only SQL; **70/70 passed structural conditions**.
- Source security and curated-version QA are under the existing offline GitHub Action; mark PASS **only after the latest run succeeds**. Neither earlier generic PASS nor a SELECT alone proves new revision-mode runtime correctness.

## Final QA evidence after restoring the clean SQL

The first trial detected an incorrectly formed SQL test-file replacement and was **NOT approved**. The SQL was reconstructed from the last known good QA file using a safe literal replacement method. No malformed candidate SQL was executed against production.

- [Isolated PostgreSQL + full offline Chromium / original Math preservation — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39430068610), source commit `cd1a751b328df41e8da039c1fed339b6faf10411`.
- [Current main parity — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39430068591), same tested source commit.
- The new isolated step passed real scratch PostgreSQL both for unchanged originals and for new separately curated three-language AI explanations. Regression suites completed with no failures.
- Final live read-only check: **321** academic source rows, **210** new fully closed/unreviewed draft locale cards, **111** existing source cards still admitted, **111** old owner allowlist rows unchanged, **0** real academic deliveries, `provider_enabled=false`.
- New qbank provenance table in production: `NULL` (not installed); existing production Vercel deployment remains `READY` at main SHA `7ea6c2960e6be1b1c46bf7b8506ee3106ad974e7`.

**GO for tested QA code only. NO-GO for production installation or releasing 210 additional locale drafts without specific owner approval and actual independent academic, language, provenance/rights review.** Technical preflight and AI-assisted content review cannot be relabelled as human editor signatures.
