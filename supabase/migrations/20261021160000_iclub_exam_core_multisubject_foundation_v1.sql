-- iClub Exam Prep reusable multi-subject academic blueprint, phase 1.
-- DORMANT and ADDITIVE. Does not touch Math Exam Prep tables or any student academic state.
-- The new blueprint is not an assessment runtime and grants no new learner access.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '90s';

CREATE TABLE IF NOT EXISTS private.iclub_exam_core_programs_v1 (
  program_key text NOT NULL CHECK (program_key ~ '^[a-z][a-z0-9_]{2,75}$'),
  version_key text NOT NULL CHECK (length(version_key) BETWEEN 3 AND 120),
  subject_key text NOT NULL REFERENCES public.subjects(subject_key) ON UPDATE RESTRICT ON DELETE RESTRICT,
  integration_mode text NOT NULL CHECK (integration_mode IN ('legacy_adapter','native')),
  library_subject_key text,
  library_version_key text,
  syllabus_uri text NOT NULL,
  titles jsonb NOT NULL CHECK (jsonb_typeof(titles)='object' AND titles ?& ARRAY['ru','uz','en']),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','review','published','legacy_external','retired')),
  launch_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key),
  CONSTRAINT iclub_exam_core_programs_library_pair CHECK ((library_subject_key IS NULL)=(library_version_key IS NULL)),
  CONSTRAINT iclub_exam_core_programs_native_library CHECK (
    (integration_mode='native' AND library_subject_key IS NOT NULL)
    OR (integration_mode='legacy_adapter' AND library_subject_key IS NULL)
  ),
  CONSTRAINT iclub_exam_core_programs_launch_safety CHECK (NOT launch_enabled OR (status='published' AND integration_mode='native')),
  CONSTRAINT iclub_exam_core_programs_library_fk FOREIGN KEY (library_subject_key,library_version_key)
    REFERENCES private.iclub_subject_library_releases(subject_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS private.iclub_exam_core_papers_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  paper_code text NOT NULL CHECK (paper_code ~ '^P[0-9]{1,2}$'),
  paper_no smallint NOT NULL CHECK (paper_no BETWEEN 1 AND 12),
  level_code text NOT NULL CHECK (level_code IN ('AS','A')),
  assessment_kind text NOT NULL CHECK (assessment_kind IN ('mcq','data_response_essays','other')),
  duration_seconds int NOT NULL CHECK (duration_seconds BETWEEN 600 AND 21600),
  total_marks smallint NOT NULL CHECK (total_marks BETWEEN 1 AND 200),
  mcq_count smallint CHECK (mcq_count BETWEEN 1 AND 100),
  sections jsonb NOT NULL CHECK (jsonb_typeof(sections)='array'),
  syllabus_units int[] NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','review','validated','published','retired')),
  source_uri text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(program_key,version_key,paper_code),
  UNIQUE(program_key,version_key,paper_no),
  FOREIGN KEY (program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK ((assessment_kind='mcq' AND mcq_count IS NOT NULL) OR (assessment_kind<>'mcq' AND mcq_count IS NULL))
);

CREATE TABLE IF NOT EXISTS private.iclub_exam_core_skills_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  skill_key text NOT NULL,
  library_subject_key text NOT NULL,
  library_version_key text NOT NULL,
  syllabus_point text NOT NULL,
  syllabus_unit smallint NOT NULL CHECK (syllabus_unit BETWEEN 1 AND 99),
  level_code text NOT NULL CHECK (level_code IN ('AS','A')),
  tour_no smallint NOT NULL CHECK (tour_no BETWEEN 1 AND 100),
  content_hash text NOT NULL CHECK (content_hash ~ '^sha256:[a-f0-9]{64}$'),
  status text NOT NULL DEFAULT 'candidate' CHECK (status IN ('candidate','reviewed','blocked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key,skill_key),
  FOREIGN KEY (program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (library_subject_key,library_version_key,skill_key)
    REFERENCES private.iclub_subject_library_theory(subject_key,version_key,skill_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS private.iclub_exam_core_paper_skills_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  paper_code text NOT NULL,
  skill_key text NOT NULL,
  link_role text NOT NULL CHECK (link_role IN ('direct','assumed_prerequisite')),
  status text NOT NULL DEFAULT 'candidate' CHECK (status IN ('candidate','approved','blocked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key,paper_code,skill_key,link_role),
  FOREIGN KEY (program_key,version_key,paper_code)
    REFERENCES private.iclub_exam_core_papers_v1(program_key,version_key,paper_code)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (program_key,version_key,skill_key)
    REFERENCES private.iclub_exam_core_skills_v1(program_key,version_key,skill_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

-- Assessment candidates are *not* promoted from existing Practice/Tour questions automatically.
-- A future QA step must approve mapping, answer-key correctness, source rights and exam format.
CREATE TABLE IF NOT EXISTS private.iclub_exam_core_question_candidates_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  paper_code text NOT NULL,
  skill_key text NOT NULL,
  legacy_question_id bigint NOT NULL REFERENCES public.questions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  link_role text NOT NULL DEFAULT 'direct' CHECK (link_role='direct'),
  source_snapshot_md5 text NOT NULL CHECK (source_snapshot_md5 ~ '^[a-f0-9]{32}$'),
  qa_scope_status text NOT NULL DEFAULT 'pending' CHECK (qa_scope_status IN ('pending','pass','fail')),
  qa_academic_status text NOT NULL DEFAULT 'pending' CHECK (qa_academic_status IN ('pending','pass','fail')),
  qa_language_status text NOT NULL DEFAULT 'pending' CHECK (qa_language_status IN ('pending','pass','fail')),
  qa_format_status text NOT NULL DEFAULT 'pending' CHECK (qa_format_status IN ('pending','pass','fail')),
  status text NOT NULL DEFAULT 'candidate' CHECK (status IN ('candidate','approved','rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key,paper_code,skill_key,legacy_question_id),
  FOREIGN KEY (program_key,version_key,paper_code,skill_key,link_role)
    REFERENCES private.iclub_exam_core_paper_skills_v1(program_key,version_key,paper_code,skill_key,link_role)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK (status<>'approved' OR
    (qa_scope_status='pass' AND qa_academic_status='pass' AND qa_language_status='pass' AND qa_format_status='pass'))
);

-- Private tables are not an alternative route to existing Math or user answers.
ALTER TABLE private.iclub_exam_core_programs_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_programs_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_papers_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_papers_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_skills_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_skills_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_paper_skills_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_paper_skills_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_question_candidates_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_question_candidates_v1 FORCE ROW LEVEL SECURITY;

REVOKE ALL ON private.iclub_exam_core_programs_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_core_papers_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_core_skills_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_core_paper_skills_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_core_question_candidates_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON private.iclub_exam_core_programs_v1 TO service_role;
GRANT SELECT,INSERT ON private.iclub_exam_core_papers_v1 TO service_role;
GRANT SELECT,INSERT ON private.iclub_exam_core_skills_v1 TO service_role;
GRANT SELECT,INSERT ON private.iclub_exam_core_paper_skills_v1 TO service_role;
GRANT SELECT,INSERT ON private.iclub_exam_core_question_candidates_v1 TO service_role;

-- An existing Math program is represented as an adapter, without modifying the Math engine.
INSERT INTO private.iclub_exam_core_programs_v1 (
 program_key,version_key,subject_key,integration_mode,syllabus_uri,titles,status
) VALUES (
 'math_as_p1_p5','p1_p5_canonical_v1_0','mathematics','legacy_adapter',
 'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/',
 '{"en":"Mathematics P1 + P5","ru":"Математика P1 + P5","uz":"Matematika P1 + P5"}'::jsonb,
 'legacy_external'
) ON CONFLICT (program_key,version_key) DO NOTHING;

INSERT INTO private.iclub_exam_core_programs_v1 (
 program_key,version_key,subject_key,integration_mode,library_subject_key,library_version_key,syllabus_uri,titles,status
) VALUES (
 'economics_9708','economics_2026_2028_v1','economics','native','economics','economics9708_20261021_p62',
 'https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf',
 '{"en":"Economics AS & A Level","ru":"Экономика AS и A Level","uz":"Iqtisodiyot AS va A Level"}'::jsonb,
 'draft'
) ON CONFLICT (program_key,version_key) DO NOTHING;

-- Cambridge 9708: A Level Paper 3/4 assume AS knowledge, but do not directly test AS topics.
INSERT INTO private.iclub_exam_core_papers_v1 (
 program_key,version_key,paper_code,paper_no,level_code,assessment_kind,
 duration_seconds,total_marks,mcq_count,sections,syllabus_units,source_uri
) VALUES
 ('economics_9708','economics_2026_2028_v1','P1',1,'AS','mcq',3600,30,30,
  '[{"section":"all","type":"mcq","required":30,"marks":30}]'::jsonb,
  ARRAY[1,2,3,4,5,6], 'https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf'),
 ('economics_9708','economics_2026_2028_v1','P2',2,'AS','data_response_essays',7200,60,NULL,
  '[{"section":"A","type":"data_response","required":1,"marks":20},{"section":"B","type":"structured_micro_essay","choose":1,"from":2,"marks":20},{"section":"C","type":"structured_macro_essay","choose":1,"from":2,"marks":20}]'::jsonb,
  ARRAY[1,2,3,4,5,6], 'https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf'),
 ('economics_9708','economics_2026_2028_v1','P3',3,'A','mcq',4500,30,30,
  '[{"section":"all","type":"mcq","required":30,"marks":30}]'::jsonb,
  ARRAY[7,8,9,10,11], 'https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf'),
 ('economics_9708','economics_2026_2028_v1','P4',4,'A','data_response_essays',7200,60,NULL,
  '[{"section":"A","type":"data_response","required":1,"marks":20},{"section":"B","type":"unstructured_micro_essay","choose":1,"from":2,"marks":20},{"section":"C","type":"unstructured_macro_essay","choose":1,"from":2,"marks":20}]'::jsonb,
  ARRAY[7,8,9,10,11], 'https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf')
ON CONFLICT (program_key,version_key,paper_code) DO NOTHING;

INSERT INTO private.iclub_exam_core_skills_v1 (
 program_key,version_key,skill_key,library_subject_key,library_version_key,syllabus_point,
 syllabus_unit,level_code,tour_no,content_hash
)
SELECT 'economics_9708','economics_2026_2028_v1',t.skill_key,t.subject_key,t.version_key,t.syllabus_point,
 split_part(t.syllabus_point,'.',1)::smallint,
 CASE WHEN split_part(t.syllabus_point,'.',1)::int <= 6 THEN 'AS' ELSE 'A' END,
 t.tour_no,t.content_hash
FROM private.iclub_subject_library_theory t
WHERE t.subject_key='economics' AND t.version_key='economics9708_20261021_p62'
 AND t.syllabus_point ~ '^(?:[1-9]|10|11)\.'
ON CONFLICT (program_key,version_key,skill_key) DO NOTHING;

INSERT INTO private.iclub_exam_core_paper_skills_v1 (
 program_key,version_key,paper_code,skill_key,link_role
)
SELECT s.program_key,s.version_key,p.paper_code,s.skill_key,
 CASE WHEN (p.level_code='AS' AND s.level_code='AS')
            OR (p.level_code='A' AND s.level_code='A') THEN 'direct'
      ELSE 'assumed_prerequisite' END
FROM private.iclub_exam_core_skills_v1 s
JOIN private.iclub_exam_core_papers_v1 p
 ON p.program_key=s.program_key AND p.version_key=s.version_key
WHERE s.program_key='economics_9708'
  AND (p.level_code='A' OR s.level_code='AS')
ON CONFLICT (program_key,version_key,paper_code,skill_key,link_role) DO NOTHING;

DO $postcheck$
DECLARE v_total int; v_as int; v_a int; v_direct int; v_assumed int; v_papers int;
BEGIN
 SELECT count(*),count(*) FILTER (WHERE level_code='AS'),count(*) FILTER (WHERE level_code='A')
 INTO v_total,v_as,v_a
 FROM private.iclub_exam_core_skills_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1';
 SELECT count(*) INTO v_papers FROM private.iclub_exam_core_papers_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1';
 SELECT count(*) FILTER(WHERE link_role='direct'),count(*) FILTER(WHERE link_role='assumed_prerequisite')
 INTO v_direct,v_assumed
 FROM private.iclub_exam_core_paper_skills_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1';
 IF v_total<>498 OR v_as<>200 OR v_a<>298 OR v_papers<>4
    OR v_direct<>996 OR v_assumed<>400 THEN
   RAISE EXCEPTION 'Multi-subject blueprint counts failed: %,%,%,%,%,%',v_total,v_as,v_a,v_papers,v_direct,v_assumed;
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 WHERE launch_enabled)
 OR has_table_privilege('anon','private.iclub_exam_core_programs_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_papers_v1','SELECT') THEN
   RAISE EXCEPTION 'Exam Core Phase 1 must remain dormant and private';
 END IF;
END;
$postcheck$;
COMMIT;