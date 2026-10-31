-- Independent inverse normal quantile calculations, not stored-answer copies.
-- Use z0.90=1.2815515655, z0.95=1.644853627, z0.975=1.959963985.
WITH derived(k,answer) AS (VALUES
('P5NOR04-A01',round((100+4*1.2815515655)::numeric,1)::text),
('P5NOR04-A02',round((50-3*1.959963985)::numeric,1)::text),
('P5NOR04-A03',round(1.644853627::numeric,3)::text),
('P5NOR04-D01',round(1.959963985::numeric,3)::text),
('P5NOR04-D02',round(1.959963985::numeric,2)::text),
('P5NOR04-D03',round((50+10*1.282)::numeric,2)::text),
('P5NOR04-L01',round(1.644853627::numeric,3)::text),
('P5NOR04-L02',round(1.2815515655::numeric,4)::text),
('P5NOR04-L03',round((50+5*1.2815515655)::numeric,1)::text),
('P5NOR04-M01',round((100-4*1.644853627)::numeric,1)::text),
('P5NOR04-M02',round((84+3*0.674)::numeric,2)::text),
('P5NOR04-R01',round((-1.959963985)::numeric,3)::text),
('P5NOR04-R02',round(1.644853627::numeric,3)::text),
('P5NOR04-R03',round((40-5*1.282)::numeric,2)::text),
('P5NOR04-R04',round((70+4*0.674)::numeric,2)::text)
), actual AS (
SELECT m.content_key k, CASE WHEN q.qtype='input' THEN q.correct_answer
ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END chosen
FROM private.exam_prep_question_content_meta m
JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
JOIN public.questions q ON q.id=m.question_id
WHERE cv.component_code='P5' AND m.lifecycle_state IN ('published','reserve')
AND m.primary_skill_code='P5-NOR-04'
)
SELECT 'P5_NOR04_INVERSE_15' AS audit,count(*) checked,
count(*) FILTER(WHERE d.k IS NULL OR a.k IS NULL OR d.answer IS DISTINCT FROM a.chosen) AS failures,
jsonb_agg(jsonb_build_object('key',coalesce(d.k,a.k),'calculated',d.answer,'current',a.chosen))
 FILTER(WHERE d.k IS NULL OR a.k IS NULL OR d.answer IS DISTINCT FROM a.chosen) AS exceptions
FROM derived d FULL JOIN actual a USING(k);
