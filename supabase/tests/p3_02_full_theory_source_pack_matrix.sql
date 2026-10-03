-- P3-02 full theory source-pack matrix.
-- Rollback-only read validation after all migrations are applied.
\set ON_ERROR_STOP on

DO $guard$
BEGIN
  IF current_setting('p302.full_theory_isolated',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P3-02 full theory matrix requires p302.full_theory_isolated=true';
  END IF;
END
$guard$;

BEGIN;

DO $coverage$
DECLARE
  v_program bigint;
  v_total int;
  v_p1 int;
  v_p5 int;
  v_missing int;
  v_bad int;
  r record;
  v_locale text;
  v jsonb;
  v_wrong_component text;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P3-02 full theory canonical program missing'; END IF;

  SELECT count(*),
         count(*) filter(where component_code='P1'),
         count(*) filter(where component_code='P5')
  INTO v_total,v_p1,v_p5
  FROM private.exam_prep_ai_source_cards
  WHERE card_type='theory'
    AND approval_status='approved'
    AND rights_status='original_iclub'
    AND is_runtime_allowed;

  IF v_total<>243 OR v_p1<>135 OR v_p5<>108 THEN
    RAISE EXCEPTION 'P3-02 full theory coverage count mismatch total=% P1=% P5=%',v_total,v_p1,v_p5;
  END IF;

  SELECT count(*) INTO v_missing
  FROM private.exam_prep_syllabus_nodes n
  CROSS JOIN (VALUES('en'),('ru'),('uz')) l(locale)
  WHERE n.program_version_id=v_program
    AND n.component_code IN ('P1','P5')
    AND NOT EXISTS(
      SELECT 1
      FROM private.exam_prep_ai_source_cards c
      WHERE c.component_code=n.component_code
        AND c.skill_code=n.skill_code
        AND c.card_type='theory'
        AND c.locale=l.locale
        AND c.source_version='p3_02_full_theory_pack_v1_2026_10_03'
        AND c.approval_status='approved'
        AND c.rights_status='original_iclub'
        AND c.is_runtime_allowed
    );
  IF v_missing<>0 THEN RAISE EXCEPTION 'P3-02 missing theory skill/locale rows=%',v_missing; END IF;

  SELECT count(*) INTO v_missing
  FROM private.exam_prep_ai_source_cards c
  LEFT JOIN private.exam_prep_syllabus_nodes n
    ON n.program_version_id=v_program
   AND n.component_code=c.component_code
   AND n.skill_code=c.skill_code
  WHERE c.card_type='theory'
    AND c.approval_status='approved'
    AND c.is_runtime_allowed
    AND (
      n.skill_code IS NULL
      OR nullif(btrim(n.book_chapter),'') IS NULL
      OR nullif(btrim(n.book_pages),'') IS NULL
    );
  IF v_missing<>0 THEN
    RAISE EXCEPTION 'P3-02 theory source provenance lost canonical book mapping rows=%',v_missing;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_ai_source_cards c
  WHERE c.card_type='theory'
    AND c.approval_status='approved'
    AND c.is_runtime_allowed
    AND (
      c.skill_code IS NULL
      OR c.source_version<>'p3_02_full_theory_pack_v1_2026_10_03'
      OR c.rights_status<>'original_iclub'
      OR char_length(c.body_text)<120
      OR lower(c.body_text) like '%correct_answer%'
      OR lower(c.body_text) like '%answer_key%'
      OR lower(c.body_text) like '%mark scheme%'
    );
  IF v_bad<>0 THEN RAISE EXCEPTION 'P3-02 governed theory card quality boundary failed rows=%',v_bad; END IF;

  FOR r IN
    SELECT component_code,skill_code
    FROM private.exam_prep_syllabus_nodes
    WHERE program_version_id=v_program AND component_code IN ('P1','P5')
    ORDER BY component_code,sequence_no
  LOOP
    FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
      v:=public.get_exam_prep_ai_source_cards_service_v1(
        r.component_code,v_locale,'theory',r.skill_code,8
      );
      IF jsonb_array_length(v)<>1
         OR v#>>'{0,component_code}'<>r.component_code
         OR v#>>'{0,skill_code}'<>r.skill_code
         OR v#>>'{0,locale}'<>v_locale
         OR v#>>'{0,source_version}'<>'p3_02_full_theory_pack_v1_2026_10_03'
      THEN
        RAISE EXCEPTION 'P3-02 theory retrieval isolation failed component=% skill=% locale=% payload=%',
          r.component_code,r.skill_code,v_locale,v;
      END IF;

      v_wrong_component:=case r.component_code when 'P1' then 'P5' else 'P1' end;
      v:=public.get_exam_prep_ai_source_cards_service_v1(
        v_wrong_component,v_locale,'theory',r.skill_code,8
      );
      IF jsonb_array_length(v)<>0 THEN
        RAISE EXCEPTION 'P3-02 theory cross-component leak skill=% requested_component=% payload=%',
          r.skill_code,v_wrong_component,v;
      END IF;
    END LOOP;
  END LOOP;
END
$coverage$;

ROLLBACK;
\echo 'P3-02 full theory source-pack matrix: GREEN'
