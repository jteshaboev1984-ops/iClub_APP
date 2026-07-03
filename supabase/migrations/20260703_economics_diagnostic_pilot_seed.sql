begin;

-- Economics diagnostic pilot seed for President Tech Award.
-- Applied in production in safe additive mode on 2026-07-03.
-- This migration records the pilot scope and uses idempotent inserts.
-- Full diagnostic texts were inserted directly into question_answer_diagnostics.
-- No questions, answers, attempts, scores, ratings or policies are changed here.

-- Pilot questions:
-- 1081 Market / Allocative efficiency — MCQ A/B/C/D mapping
-- 1071 Demand / Complementary goods — MCQ A/B/C/D mapping
-- 1115 Market / Consumer surplus — MCQ A/B/C/D mapping
-- 1135 Basics / Income from factors of production — MCQ A/B/C/D mapping
-- 2548 Government macroeconomic intervention / Fiscal policy — MCQ A/B/C/D mapping
-- 1018 PPC / Opportunity cost on the PPC — input exact + pattern + fallback
-- 1022 Elasticity / Calculating PED — input exact + patterns + fallback

-- Marker rows in governance table are inserted only if missing.
-- The actual diagnostic rows should be maintained in the database via the QA tool
-- or expanded in a later full seed once the pilot set is finalized.

insert into public.question_content_change_decisions(
  question_id,
  decision_type,
  risk_level,
  history_policy,
  rationale,
  proposed_change,
  evidence_snapshot,
  status,
  decided_by
)
select *
from (
  values
  (
    1081::bigint,
    'diagnostic_mapping_only',
    'low',
    'future_only_no_retroactive_change',
    'Pilot MCQ diagnostic mapping added. No content/history change.',
    '{"action":"diagnostic_rows_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    1071::bigint,
    'diagnostic_mapping_only',
    'medium',
    'future_only_no_retroactive_change',
    'Pilot MCQ diagnostic mapping added. No content/history change.',
    '{"action":"diagnostic_rows_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    1115::bigint,
    'diagnostic_mapping_only',
    'low',
    'future_only_no_retroactive_change',
    'Pilot MCQ diagnostic mapping added. No content/history change.',
    '{"action":"diagnostic_rows_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    1135::bigint,
    'diagnostic_mapping_only',
    'low',
    'future_only_no_retroactive_change',
    'Pilot MCQ diagnostic mapping added. No content/history change.',
    '{"action":"diagnostic_rows_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    2548::bigint,
    'diagnostic_mapping_only',
    'medium',
    'clone_for_future_keep_old_history',
    'Pilot MCQ diagnostic mapping added. Question has tour history, so future stronger version should be cloned, not rewritten.',
    '{"action":"diagnostic_rows_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4,"tour_history":true}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    1018::bigint,
    'historical_recalculation_candidate',
    'high',
    'requires_architect_approval_before_recalc',
    'Future input pattern rule added for conceptually correct unit answers such as 3 units Y. Historical tour scores are not recalculated automatically.',
    '{"action":"future_input_rule_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":3,"false_negative_candidates":["3 birlik Y","3 единицы Y","3ta Y"]}'::jsonb,
    'applied',
    'assistant_qa'
  ),
  (
    1022::bigint,
    'future_evaluator_rule_only',
    'medium',
    'future_only_no_retroactive_change',
    'Future input exact/pattern/fallback rules added for PED calculation. No historical score change.',
    '{"action":"future_input_rules_added","rewrite_question":false,"recalculate_history":false}'::jsonb,
    '{"diagnostic_rows":4}'::jsonb,
    'applied',
    'assistant_qa'
  )
) as v(question_id, decision_type, risk_level, history_policy, rationale, proposed_change, evidence_snapshot, status, decided_by)
where not exists (
  select 1
  from public.question_content_change_decisions d
  where d.question_id = v.question_id
    and d.status = 'applied'
    and d.decided_by = 'assistant_qa'
);

commit;
