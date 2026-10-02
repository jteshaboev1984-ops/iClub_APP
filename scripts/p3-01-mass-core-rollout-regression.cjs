const fs = require('fs');

const migration = fs.readFileSync('supabase/migrations/20261002070000_exam_prep_p3_01_mass_core_rollout_gate_v1.sql','utf8');
const matrix = fs.readFileSync('supabase/tests/p3_01_mass_core_rollout_gate_matrix.sql','utf8');

function must(ok,msg){ if(!ok) throw new Error(`P3-01 regression: ${msg}`); }

for(const token of [
  'private.exam_prep_p3_01_mass_core_rollout_gate_v1',
  'private.exam_prep_beta_expansion_gate_v1',
  "milestone_key='product_content_complete'",
  'get_exam_prep_readiness_summary_safe_v1',
  'get_exam_prep_final_calibration_safe_v1',
  "'automatic_rollout_permitted',false",
  "'ai_scale_independent',true",
  "'mentor_scale_independent',true",
  "'decision',case when v_ready then 'ELIGIBLE_FOR_EXPLICIT_MASS_CORE_DECISION' else 'NO_GO' end"
]) must(migration.includes(token), `missing gate token: ${token}`);

for(const forbidden of [
  /update\s+private\.exam_prep_feature_config/i,
  /insert\s+into\s+private\.exam_prep_feature_entitlements/i,
  /update\s+private\.exam_prep_feature_entitlements/i,
  /insert\s+into\s+private\.exam_prep_beta_members/i,
  /update\s+private\.exam_prep_beta_members/i,
  /delete\s+from\s+private\.exam_prep_beta_members/i,
  /insert\s+into\s+public\.users/i,
  /update\s+public\.users/i,
  /delete\s+from\s+public\.users/i,
  /insert\s+into\s+public\.practice_answers/i,
  /update\s+public\.practice_answers/i,
  /insert\s+into\s+public\.tour_answers/i,
  /update\s+public\.tour_answers/i,
  /insert\s+into\s+public\.certificates/i,
  /update\s+public\.certificates/i
]) must(!forbidden.test(migration), `forbidden rollout/learner mutation: ${forbidden}`);

must(matrix.includes("'NO_GO'"), 'matrix must explicitly test NO_GO');
must(matrix.includes('v_before<>v_after'), 'matrix must prove read-only behavior');
must(matrix.includes('__missing_p3_01_cohort__'), 'matrix must prove fail-closed missing cohort');

console.log('P3-01 Mass Core rollout static regression: GREEN');
