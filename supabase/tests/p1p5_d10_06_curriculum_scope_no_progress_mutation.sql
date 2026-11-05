-- D10-06: read-only, disposable PostgreSQL source-vs-81-skill contract.
-- Does not write or rekey published questions, history, mastery or reserves.
\set ON_ERROR_STOP on
DO $test$
DECLARE
  v_program bigint;
  v_count int;
  v_good int;
  v_obj int;
  v_pub int;
  v_res int;
  v_written int;
BEGIN
  IF current_database()<>'postgres'
    OR current_setting('server_version_num')::int < 170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>2
  THEN
    RAISE EXCEPTION 'D10-06 refused: tests require isolated PG17 and exactly two fixture users';
  END IF;
  SELECT id INTO STRICT v_program
    FROM private.exam_prep_program_versions
    WHERE program_key='math_as_p1_p5' AND status='active';
  SELECT count(*) INTO v_count
    FROM private.exam_prep_syllabus_nodes WHERE program_version_id=v_program
      AND component_code IN ('P1','P5');
  IF v_count<>81 THEN
    RAISE EXCEPTION 'D10-06 lost original 81 canonical skill identities';
  END IF;

  WITH expected(skill_code,description) AS (
    VALUES
    ('P1-DIF-01','Понимать производную как предел градиентов секущих и мгновенную скорость изменения; оценивать градиент касательной без обязательного формального вывода из первых принципов.'),
    ('P1-DIF-03','Применять цепное правило к составным степенным функциям (g(x))^n, включая нелинейные внутренние многочлены, с учётом производной g''(x).'),
    ('P1-INT-01','Находить первообразные степенных функций и выражений (a x + b)^n для рационального n, кроме n = −1.'),
    ('P5-PRO-03','Применять сложение вероятностей в простых случаях, дополнение и несовместимость событий; общая формула включений–исключений не обязательна.')
  )
  SELECT count(*) INTO v_good
  FROM expected e
  JOIN private.exam_prep_syllabus_nodes s
    ON s.program_version_id=v_program
   AND s.skill_code=e.skill_code
   AND s.canonical_description=e.description;
  IF v_good<>4 THEN
    RAISE EXCEPTION 'D10-06 source scope descriptions differ from canonical 9709: %/4',v_good;
  END IF;

  -- The original protected objective corpus for the nonlinear-chain gap
  -- must not be silently removed, overwritten, leaked or reclassified.
  SELECT count(*),
         count(*) FILTER(where m.lifecycle_state='published'),
         count(*) FILTER(where m.lifecycle_state='reserve')
  INTO v_obj,v_pub,v_res
  FROM private.exam_prep_question_content_meta m
  WHERE m.primary_skill_code='P1-DIF-03';
  IF v_obj<>15 OR v_pub<>6 OR v_res<>9 THEN
    RAISE EXCEPTION 'D10-06 existing P1-DIF-03 question bank lifecycle changed';
  END IF;
  SELECT count(*) INTO v_written
  FROM private.exam_prep_written_tasks w
  WHERE w.primary_skill_code='P1-DIF-03' AND w.lifecycle_state='published';
  IF v_written<2 THEN
    RAISE EXCEPTION 'D10-06 existing written-task history missing';
  END IF;

  -- This read-only curriculum test does not write profile data. PG17
  -- tests guarantee two isolated AUTH users but not two exam-prep profiles;
  -- requiring a second profile was an unrelated false negative.
  IF (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
  THEN
    RAISE EXCEPTION 'D10-06 fixture two-user isolation changed';
  END IF;
  RAISE NOTICE 'D10-06 PASS: four source-scope corrections, 81 keys, preserved six published/nine reserves and written history';
END
$test$;
