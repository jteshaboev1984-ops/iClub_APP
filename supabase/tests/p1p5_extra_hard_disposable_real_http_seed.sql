-- Disposable JWT/PostgREST smoke: synthetic 1+1 ONLY, not protected exam content.
\set ON_ERROR_STOP on
DO $$
BEGIN
 IF current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
  OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'REFUSED: Extra Hard dummy seed requires isolated PG with exactly two test users'; END IF;
END $$;
INSERT INTO private.exam_prep_extra_hard_tasks_v1(
 task_key,program_version_id,bank_version,component_code,primary_skill_code,
 official_section,book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,
 qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256,published_at
) SELECT 'CI-EXTRA-HARD-TEST-01',p.id,r.bank_version,'P1','P1-QUA-01',
 '1.1 Quadratics','CI synthetic only',
 '{"en":"CI synthetic example","ru":"Тестовый пример","uz":"Sinov misoli"}'::jsonb,
 '{"en":"What is 1 + 1?","ru":"Сколько будет 1 + 1?","uz":"1 + 1 nechiga teng?"}'::jsonb,
 '{"en":"1 + 1 = 2.","ru":"1 + 1 = 2.","uz":"1 + 1 = 2."}'::jsonb,
 '2','approved','approved','approved','published',repeat('a',64),now()
 FROM private.exam_prep_program_versions p
 JOIN private.exam_prep_extra_hard_release_v1 r
   ON r.program_key=p.program_key
 WHERE p.program_key='math_as_p1_p5' AND p.status='active'
 ORDER BY p.id DESC LIMIT 1;
UPDATE private.exam_prep_extra_hard_release_v1
 SET academic_approved=true,enabled=true,updated_at=now()
 WHERE program_key='math_as_p1_p5';
