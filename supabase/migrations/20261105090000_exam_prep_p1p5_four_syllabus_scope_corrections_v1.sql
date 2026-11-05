-- 9709 D10-06: Correct four curriculum DESCRIPTION errors only.
-- Cambridge 2026–2027 §1.7/1.8 and §5.3; published 2028–2030 equivalent.
-- No question text, attempt, mastery, score, student progress, ID or timetable.
-- DO NOT apply to production without separate architect release GO.
BEGIN;
DO $scope$
DECLARE
 v_program bigint;
 v_count integer;
 v_seen integer;
BEGIN
 SELECT id INTO STRICT v_program
 FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active';
 SELECT count(*) INTO v_seen
 FROM private.exam_prep_syllabus_nodes
 WHERE program_version_id=v_program AND component_code IN ('P1','P5');
 IF v_seen<>81 THEN
   RAISE EXCEPTION 'D10-06 refused: current 81-skill curriculum not matched';
 END IF;
 -- Update only known text with a CAS guard; never overwrite a new reviewed
 -- curriculum version or an already corrected row.
 WITH corrected(skill_code,old_description,new_description) AS (
   VALUES
    ('P1-DIF-01','Интерпретировать derivative как gradient/rate of change и использовать limit definition в простом случае.','Понимать производную как предел градиентов секущих и мгновенную скорость изменения; оценивать градиент касательной без обязательного формального вывода из первых принципов.'),
    ('P1-DIF-03','Применять chain rule к функциям вида (a x + b)^n.','Применять цепное правило к составным степенным функциям (g(x))^n, включая нелинейные внутренние многочлены, с учётом производной g''(x).'),
    ('P1-INT-01','Интегрировать powers и expressions (a x + b)^n как antiderivatives.','Находить первообразные степенных функций и выражений (a x + b)^n для рационального n, кроме n = −1.'),
    ('P5-PRO-03','Применять addition rule, complements и mutually exclusive events.','Применять сложение вероятностей в простых случаях, дополнение и несовместимость событий; общая формула включений–исключений не обязательна.')
 )
 UPDATE private.exam_prep_syllabus_nodes s
 SET canonical_description=c.new_description
 FROM corrected c
 WHERE s.program_version_id=v_program AND s.skill_code=c.skill_code
   AND s.canonical_description=c.old_description;
 GET DIAGNOSTICS v_count=ROW_COUNT;
 IF v_count<>4 THEN
   RAISE EXCEPTION 'D10-06 expected exactly four source-description changes, got %',v_count;
 END IF;
END;
$scope$;
COMMIT;
