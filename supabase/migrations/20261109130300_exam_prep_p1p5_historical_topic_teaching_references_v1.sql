-- Cambridge-authored 9709 Scheme of Work (for examination from 2020).
-- Historical suggested GUIDED TEACHING time PER TOPIC, NOT private self-study
-- hours or 2026-27 verified per-skill norms. Never use as an automatic
-- personal recommendation. Store the source/version/caveat explicitly.
create table private.exam_prep_historical_topic_teaching_refs_v1 (
 program_version_id bigint not null
   references private.exam_prep_program_versions(id) on delete restrict,
 component_code text not null check (component_code in ('P1','P5')),
 official_syllabus_section text not null,
 suggested_guided_teaching_hours smallint not null
   check (suggested_guided_teaching_hours between 1 and 100),
 source_document text not null,
 source_url text not null,
 source_scheme_version text not null default 'from_2020_v1',
 status text not null default 'historical_reference_unverified_for_2026_27'
   check (status in ('historical_reference_unverified_for_2026_27','confirmed_for_current_content','retired')),
 approved_as_personal_study_norm boolean not null default false
   check (approved_as_personal_study_norm=false),
 created_at timestamptz not null default now(),
 primary key(program_version_id,component_code,official_syllabus_section)
);
alter table private.exam_prep_historical_topic_teaching_refs_v1
  enable row level security;
revoke all on private.exam_prep_historical_topic_teaching_refs_v1 from public,anon,authenticated;
comment on table private.exam_prep_historical_topic_teaching_refs_v1 is
'Historical Cambridge-authored 9709 2020 Scheme of Work topic GUIDED TEACHING time only. 2026/27 applicability unconfirmed. Not hours needed by a learner. Never feed directly to personal daily study hours.';

-- Only 13 exact Cambridge syllabus topics existing in active canonical P1/P5
-- map: 8 Pure1 topics + 5 ProbStats1 topics.
-- P1 source: Cambridge Assessment International Education, Pure Mathematics 1,
-- Scheme of Work, for examinations from 2020, Version 1, page 5.
-- https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf
-- P5 source: Cambridge Assessment International Education, Probability & Statistics 1,
-- Scheme of Work, for examinations from 2020, Version 1, page 5.
-- https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf
-- Official 2026-27 syllabus content is maintained separately in
-- private.exam_prep_syllabus_nodes; do not infer 2026-27 topic hours.
with source_hours(component_code,section,hours,document_name,reference_url) as (
 values
 ('P1','1.1 Quadratics',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.2 Functions',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.3 Coordinate geometry',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.4 Circular measure',4,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.5 Trigonometry',14,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.6 Series',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.7 Differentiation',16,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.8 Integration',16,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P5','5.1 Representation of data',14,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.2 Permutations and combinations',4,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.3 Probability',12,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.4 Discrete random variables',8,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.5 The normal distribution',12,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf')
)
insert into private.exam_prep_historical_topic_teaching_refs_v1(
  program_version_id,component_code,official_syllabus_section,
  suggested_guided_teaching_hours,source_document,source_url
)
select distinct s.program_version_id,r.component_code,r.section,r.hours,
  r.document_name,r.reference_url
from source_hours r
join private.exam_prep_syllabus_nodes s
  on s.component_code=r.component_code and
     s.official_syllabus_section=r.section
join private.exam_prep_program_versions p
  on p.id=s.program_version_id
where p.program_key='math_as_p1_p5' and p.status='active'
on conflict do nothing;

do $$
declare v_p1_count int;v_p5_count int;v_p1_hours int;v_p5_hours int;
begin
 select count(*) filter(where component_code='P1'),
        count(*) filter(where component_code='P5'),
        sum(suggested_guided_teaching_hours) filter(where component_code='P1'),
        sum(suggested_guided_teaching_hours) filter(where component_code='P5')
 into v_p1_count,v_p5_count,v_p1_hours,v_p5_hours
 from private.exam_prep_historical_topic_teaching_refs_v1 h
 join private.exam_prep_program_versions p on p.id=h.program_version_id
 where p.program_key='math_as_p1_p5' and p.status='active';
 if v_p1_count<>8 or v_p5_count<>5 or v_p1_hours<>90 or v_p5_hours<>50 then
   raise exception 'exam_prep_historical_scheme_source_mismatch';
 end if;
end $$;
