# Economics Diagnostic Seed Tracking Note

Date: 2026-07-03

The Economics diagnostic pilot rows were inserted directly into Supabase during the supervised QA session.

This was done in safe additive mode:

- no question rows were changed;
- no old user answers were changed;
- no old scores were recalculated;
- no public app policy was removed.

Current verified pilot state:

- selected pilot questions: 7;
- published diagnostic rows: 27;
- applied governance decisions: 7;
- existing `questions` count remained 4567;
- existing `practice_answers` count remained 8710;
- existing `tour_answers` count remained 6267.

The file `supabase/migrations/20260703_economics_diagnostic_pilot_seed.sql` records governance marker rows for this pilot. It intentionally does not re-create the full multilingual diagnostic feedback body, because those rows were authored and checked directly in Supabase during the QA session.

Before turning the pilot into a repeatable production migration, export the final approved diagnostic rows from `question_answer_diagnostics` and convert them into a complete idempotent SQL seed.
