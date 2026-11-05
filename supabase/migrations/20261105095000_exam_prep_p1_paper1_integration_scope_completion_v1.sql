-- 9709 D10-07: correct TWO incomplete integration-skill descriptions.
-- Official Cambridge 2026–2027 syllabus §1.8 printed p.22 explicitly includes
-- improper integrals to infinity and revolution of regions not bounded by
-- the axis of rotation. No user or question/answer/mark/history mutation.
-- DRAFT/NO LIVE EXECUTION WITHOUT THE ARCHITECT'S SEPARATE GO.
BEGIN;
DO $scope$
DECLARE v_program bigint; v_count integer;
BEGIN
 SELECT id INTO STRICT v_program
 FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active';
 IF (SELECT count(*) FROM private.exam_prep_syllabus_nodes
     WHERE program_version_id=v_program AND component_code IN ('P1','P5'))<>81
 THEN RAISE EXCEPTION 'D10-07 refused noncanonical 81-skill program'; END IF;

 WITH corrected(skill_code,old_description,new_description) AS (
  VALUES
   ('P1-INT-03','Вычислять definite integrals, включая простой improper endpoint case из P1.','Вычислять определённые интегралы, включая простые несобственные интегралы с особенностью на конечной границе и с бесконечным пределом интегрирования.'),
   ('P1-INT-05','Находить volume of revolution около coordinate axis с корректными limits.','Находить объёмы тел вращения вокруг координатных осей, в том числе для областей между двумя кривыми, не прилегающих к оси вращения.')
 )
 UPDATE private.exam_prep_syllabus_nodes s
 SET canonical_description=c.new_description
 FROM corrected c
 WHERE s.program_version_id=v_program
   AND s.skill_code=c.skill_code
   AND s.canonical_description=c.old_description;
 GET DIAGNOSTICS v_count=ROW_COUNT;
 IF v_count<>2 THEN
   RAISE EXCEPTION 'D10-07 expected exactly two verified descriptions, got %',v_count;
 END IF;
END
$scope$;
COMMIT;
