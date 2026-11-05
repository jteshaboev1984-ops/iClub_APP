-- D10-07: isolated PG17 READ-ONLY curriculum and original question protection.
-- Never reset live user data. No question text, keys, attempts, or answers here.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_program bigint;
  v_ok integer;
  v_s text;
  v_obj integer;
  v_pub integer;
  v_res integer;
  v_written integer;
BEGIN
  IF current_database()<>'postgres'
    OR current_setting('server_version_num')::integer<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
  THEN RAISE EXCEPTION 'D10-07 refused non-isolated PG17 test'; END IF;
  SELECT id INTO STRICT v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND status='active';
  IF (SELECT count(*) FROM private.exam_prep_syllabus_nodes
      WHERE program_version_id=v_program AND component_code='P1')<>45
    OR (SELECT count(*) FROM private.exam_prep_syllabus_nodes
      WHERE program_version_id=v_program AND component_code='P5')<>36
  THEN RAISE EXCEPTION 'D10-07 altered original 45 + 36 skill map'; END IF;
  SELECT count(*) INTO v_ok
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=v_program
    AND ((skill_code='P1-INT-03'
      AND canonical_description='Вычислять определённые интегралы, включая простые несобственные интегралы с особенностью на конечной границе и с бесконечным пределом интегрирования.')
      OR (skill_code='P1-INT-05'
      AND canonical_description='Находить объёмы тел вращения вокруг координатных осей, в том числе для областей между двумя кривыми, не прилегающих к оси вращения.'));
  IF v_ok<>2 THEN RAISE EXCEPTION 'D10-07 both syllabus corrections not present: %',v_ok; END IF;
  FOR v_s IN SELECT unnest(ARRAY['P1-INT-03','P1-INT-05'])
  LOOP
    SELECT count(*),count(*) FILTER(WHERE lifecycle_state='published'),
      count(*) FILTER(WHERE lifecycle_state='reserve')
    INTO v_obj,v_pub,v_res FROM private.exam_prep_question_content_meta
    WHERE primary_skill_code=v_s;
    IF v_obj<>15 OR v_pub<>6 OR v_res<>9
    THEN RAISE EXCEPTION 'D10-07 original bank lifecycle corrupted for %',v_s; END IF;
    SELECT count(*) INTO v_written
      FROM private.exam_prep_written_tasks
      WHERE primary_skill_code=v_s AND lifecycle_state='published';
    IF (v_s='P1-INT-03' AND v_written<3)
      OR (v_s='P1-INT-05' AND v_written<4)
    THEN RAISE EXCEPTION 'D10-07 original written source vanished for %',v_s; END IF;
  END LOOP;
  RAISE NOTICE 'D10-07 PASS: 45 P1 + 36 P5, 2 exact source descriptions, both 6 published/9 reserve, original written history intact';
END
$proof$;
