\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p273.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-73 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_seed bigint;
  v_sha text;
  v_run_id text;
  v_payload jsonb;
  v_report jsonb;
  v_ordered_count int;
  v_distinct_count int;
BEGIN
  v_seed:=nullif(current_setting('p273.seed',true),'')::bigint;
  v_sha:=lower(nullif(current_setting('p273.git_sha',true),''));

  IF v_seed IS NULL OR v_seed<1 THEN
    RAISE EXCEPTION 'P2-73 deterministic seed required';
  END IF;
  IF v_sha IS NULL OR v_sha !~ '^[0-9a-f]{40}$' THEN
    RAISE EXCEPTION 'P2-73 exact candidate Git SHA required';
  END IF;

  v_report:=private.exam_prep_synthetic_scenario_set_report_v1('p2_67_canonical_v2_0');
  IF coalesce((v_report->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_report->>'canonical_profiles')::int,-1)<>15
     OR coalesce((v_report->>'adversarial_variants')::int,-1)<>18
     OR coalesce((v_report->>'locale_violations')::int,-1)<>0
     OR coalesce(jsonb_array_length(v_report->'missing_required_tags'),-1)<>0 THEN
    RAISE EXCEPTION 'P2-73 canonical scenario manifest is not rehearsal-ready: %',v_report;
  END IF;

  -- The rehearsal seed controls a deterministic rotation of all 15 canonical
  -- profiles. Each rehearsal therefore consumes the same complete universe in
  -- a different deterministic order without changing the signed scenario set.
  WITH ordered AS (
    SELECT scenario_code,
           row_number() over(
             order by mod(deterministic_ordinal-1 + mod(v_seed,15)::int,15),deterministic_ordinal
           ) AS seeded_order
    FROM private.exam_prep_synthetic_scenarios
    WHERE scenario_set_version='p2_67_canonical_v2_0'
      AND scenario_type='canonical_profile'
  )
  SELECT count(*),count(distinct scenario_code)
  INTO v_ordered_count,v_distinct_count
  FROM ordered;

  IF v_ordered_count<>15 OR v_distinct_count<>15 THEN
    RAISE EXCEPTION 'P2-73 seeded canonical profile coverage invalid count=% distinct=%',v_ordered_count,v_distinct_count;
  END IF;

  v_run_id:='SV-P273CI-'||v_seed::text;
  v_payload:=private.register_exam_prep_canonical_synthetic_run_v2(
    v_run_id,'p2_67_canonical_v2_0',v_sha,'p2-73',v_seed,'core',
    'p2-73-core-engineering-dress-rehearsal'
  );

  IF v_payload->>'run_status'<>'registered'
     OR v_payload->>'scenario_set_version'<>'p2_67_canonical_v2_0'
     OR (v_payload->>'deterministic_seed')::bigint<>v_seed
     OR v_payload->>'git_sha' IS DISTINCT FROM v_sha THEN
    RAISE EXCEPTION 'P2-73 rehearsal registration mismatch: %',v_payload;
  END IF;

  RAISE NOTICE 'P2-73 rehearsal candidate_sha=% seed=% canonical_profiles=15 adversarial_variants=18',v_sha,v_seed;
END
$$;

ROLLBACK;

DO $$
DECLARE
  v_seed bigint:=nullif(current_setting('p273.seed',true),'')::bigint;
BEGIN
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_synthetic_validation_runs
    WHERE run_id='SV-P273CI-'||v_seed::text
  ) THEN
    RAISE EXCEPTION 'P2-73 rehearsal guard left synthetic run residue seed=%',v_seed;
  END IF;
END
$$;

SELECT 'P2-73 rehearsal guard: GREEN' AS result;
