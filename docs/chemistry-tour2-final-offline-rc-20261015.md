# Chemistry 9701 Tour 2 — final offline RC checkpoint (2026-10-15)

**STATUS: HOLD / NO-GO — candidate assembled, no production installation.**

## Single archive in iClub Library
- Folder: `/iClub APP/Chemistry 9701/`
- Filename: `Chemistry_9701_Tour2_FINAL_OFFLINE_RC_2026-10-15.zip`
- SHA256: `74fc5d3632a8862bb534e6235c562e01e0ccbe48c15e3465388460da59757a1b`
- Contents: 68 original entries, byte-for-byte identical, plus 8 dedicated final-candidate files. Test entry point: `FINAL_CANDIDATE_2026-10-15/check_final_candidate.py`.

## Candidate consistency
- 70 intended Practice questions = 11 immutable existing MCQ IDs + 59 new EN/RU/UZ authored candidates.
- 20 new Tour questions; all existing approved Tour clocks intact; total question-specific limits = 1895 seconds (31:35). No global Tour timeout created.
- 59 new Practice individual clock recommendations incorporated in a separate **non-executable** JSON preview, range 45–210 seconds, sum 5840 seconds (not a global Practice timer). The 11 existing Practice rows/timers and all original authoring snapshots stay untouched.
- 28 new numeric input policies; 28/28 arithmetic results independently recomputed. Other new records: 51 MCQ.
- Eight textbook-scope supplements (7 Practice, 1 Tour) remain labelled `BOOK_ONLY_EXTENSION`; no claim of separate, mandatory Cambridge 9701 learning outcomes. Curriculum source: official 9701 syllabus for 2025–2027, section 3.3, 4.1–4.2, 5.1–5.2 and textbook chapters 4–6.
- New archive verifier: **4839 assertions PASS**; prior route simulations **1811 PASS**, timer/content checks **674 PASS**, prior independent baseline checks **311 PASS**; 565 preexisting numeric case expectations inspected. Tampered candidate-timer negative test correctly rejected.

## Rechecked actual production (SELECT only)
- `public.questions` Chemistry total: **867**. Existing numeric inputs: **154** (151 active).
- Stable old input IDs MD5: `979f55f0e3d95b712a2313e3f8124745`.
- Unmodified Practice evaluator body MD5: `9183e7230bda1321df05138a472325cd`.
- Unmodified Tour evaluator body MD5: `6fda83af7c7c38415475b82fdee99a40`.
- New strict policy and old-input allowlist tables: **absent**. Supabase development branches: **none**.

## Still blocking any GO
1. Authorised isolated PostgreSQL authenticated E2E for standard Practice, Practice by topic, Tour, multiuser isolation, retries/idempotency, session rollback on missing policy, timeout and answer leakage. **NOT RUN**; Vercel Preview has no isolated DB.
2. Subject-specific strict scorer routing has only offline simulations and SQL draft. **NOT INSTALLED**. No production write-path safety claim.
3. Expert academic and RU/UZ/EN native-reader signoff still pending; clock values are final offline recommendations, not a user-authorized publication.
4. Release sign-off requires explicit separate approval; this QA document is not a release permission.

**No new branch, no main merge, no deployed code, no Supabase changes, no synthetic users on the working DB, no historic rating/progress/certificate reset, no notifications.** The `chemistry-academic-audit` branch is historical (2702 commits behind main) and is for QA reports only; never merge its old app code into production.