-- P2-10 / Annual Roadmap C21: operational source hierarchy + governed working-tools registry.
-- Additive Exam Prep metadata only. No learner evidence/mastery/stage/correction or legacy Practice/Tours history is rewritten.
begin;

create table if not exists private.exam_prep_source_registry (
  id bigint generated always as identity primary key,
  source_key text not null,
  source_version text not null,
  source_level smallint not null check(source_level between 1 and 6),
  source_kind text not null check(source_kind in (
    'official_syllabus','teaching_reference','original_iclub_content',
    'official_exam_workflow','examiner_feedback','supplementary_aid'
  )),
  title_en text not null,
  title_ru text not null,
  title_uz text not null,
  role_en text not null,
  role_ru text not null,
  role_uz text not null,
  can_define_scope boolean not null default false,
  can_define_coverage_denominator boolean not null default false,
  can_support_assessment_evidence boolean not null default false,
  downstream_only boolean not null default false,
  rights_status text not null check(rights_status in (
    'official_external','licensed_reference','original_iclub','metadata_only_external','downstream_internal'
  )),
  official_url text null,
  status text not null default 'active' check(status in ('active','retired','superseded')),
  checked_at timestamptz null,
  created_at timestamptz not null default now(),
  unique(source_key,source_version),
  check(not can_define_scope or source_level=1),
  check(not can_define_coverage_denominator or source_level=1),
  check(not can_support_assessment_evidence or source_level in (3,4)),
  check(not downstream_only or source_level=6),
  check(official_url is null or official_url ~ '^https://')
);

create unique index if not exists exam_prep_source_registry_one_active_version_idx
  on private.exam_prep_source_registry(source_key)
  where status='active';

alter table private.exam_prep_source_registry enable row level security;
revoke all on private.exam_prep_source_registry from public,anon,authenticated;
grant all on private.exam_prep_source_registry to service_role;
grant usage,select on sequence private.exam_prep_source_registry_id_seq to service_role;

drop trigger if exists exam_prep_source_registry_audit_v1 on private.exam_prep_source_registry;
create trigger exam_prep_source_registry_audit_v1
after insert or update or delete on private.exam_prep_source_registry
for each row execute function private.exam_prep_audit_row_change_v1();

insert into private.exam_prep_source_registry(
  source_key,source_version,source_level,source_kind,title_en,title_ru,title_uz,
  role_en,role_ru,role_uz,can_define_scope,can_define_coverage_denominator,
  can_support_assessment_evidence,downstream_only,rights_status,official_url,checked_at
) values
(
  'cambridge_9709_current_syllabus','9709:2026-2027',1,'official_syllabus',
  'Official Cambridge 9709 syllabus','Официальная программа Cambridge 9709','Cambridge 9709 rasmiy dasturi',
  'Defines assessable scope, components, assessment objectives, exam conditions and syllabus changes.',
  'Определяет экзаменационный объём, компоненты, цели оценивания, условия экзамена и изменения программы.',
  'Imtihon doirasi, komponentlar, baholash maqsadlari, imtihon shartlari va dastur o‘zgarishlarini belgilaydi.',
  true,true,false,false,'official_external',
  'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',now()
),
(
  'coursebook_teacher_learning','p1_p5_reference:v1',2,'teaching_reference',
  'Coursebook and qualified teacher','Учебник и квалифицированный учитель','Darslik va malakali o‘qituvchi',
  'Supports learning, explanation and chapter-to-skill mapping without defining the syllabus denominator.',
  'Поддерживает обучение, объяснение и привязку глав к навыкам, но не определяет объём программы.',
  'O‘rganish, tushuntirish va boblarni ko‘nikmalarga bog‘lashni qo‘llab-quvvatlaydi, lekin dastur doirasini belgilamaydi.',
  false,false,false,false,'licensed_reference',null,null
),
(
  'iclub_original_topic_content','content_governance:v1.1',3,'original_iclub_content',
  'Original iClub topic questions and tasks','Оригинальные вопросы и задания iClub','iClub original mavzuli savol va topshiriqlari',
  'Turns canonical skills into original learning, diagnostic, retest and transfer evidence without expanding scope.',
  'Преобразует канонические навыки в оригинальные учебные, диагностические, повторные и переносные задания без расширения программы.',
  'Kanonik ko‘nikmalarni original o‘quv, diagnostika, qayta sinov va transfer topshiriqlariga aylantiradi, doirani kengaytirmaydi.',
  false,false,true,false,'original_iclub',null,null
),
(
  'cambridge_official_past_paper_workflow','metadata_workflow:v1',4,'official_exam_workflow',
  'Official past-paper workflow and mark-scheme metadata','Официальный процесс работы с past papers и metadata mark schemes','Rasmiy past paper jarayoni va mark scheme metadata',
  'Supports mixed, timed and full-paper evidence through authorised external workflow; the app stores metadata only.',
  'Поддерживает mixed, timed и full-paper evidence через разрешённый внешний процесс; приложение хранит только metadata.',
  'Mixed, timed va full-paper evidence uchun ruxsat etilgan tashqi jarayonni qo‘llaydi; ilova faqat metadata saqlaydi.',
  false,false,true,false,'metadata_only_external',
  'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',now()
),
(
  'cambridge_examiner_feedback','feedback_workflow:v1',5,'examiner_feedback',
  'Examiner reports and candidate-response feedback','Отчёты экзаменаторов и обратная связь по ответам кандидатов','Examiner reports va nomzod javoblari bo‘yicha fikrlar',
  'Supports standards, recurring-error analysis and answer-quality review after an attempt without copying protected text.',
  'Поддерживает анализ стандартов, повторяющихся ошибок и качества ответа после попытки без копирования защищённого текста.',
  'Urinishdan keyin standartlar, takroriy xatolar va javob sifatini tahlil qilishni qo‘llaydi, himoyalangan matn ko‘chirilmaydi.',
  false,false,false,false,'metadata_only_external',
  'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',now()
),
(
  'supplementary_gap_aids','downstream_only:v1',6,'supplementary_aid',
  'Supplementary gap aids','Дополнительные материалы для точечных пробелов','Aniq bo‘shliqlar uchun qo‘shimcha materiallar',
  'May help resolve a specific misunderstanding but never defines truth, scope, mastery or evidence authority.',
  'Может помочь закрыть конкретное непонимание, но не определяет истину, объём программы, mastery или evidence authority.',
  'Muayyan tushunmovchilikni bartaraf etishga yordam beradi, lekin haqiqat, dastur doirasi, mastery yoki evidence authorityni belgilamaydi.',
  false,false,false,true,'downstream_internal',null,null
)
on conflict(source_key,source_version) do nothing;

-- Structural source levels on existing semantic metadata. These columns do not alter learner state.
alter table private.exam_prep_syllabus_nodes
  add column if not exists source_level smallint not null default 1;
alter table private.exam_prep_component_paper_profiles
  add column if not exists source_level smallint not null default 1;
alter table private.exam_prep_exam_calendar
  add column if not exists source_level smallint not null default 1;
alter table private.exam_prep_content_versions
  add column if not exists source_level smallint not null default 3;
alter table private.exam_prep_paper_metadata
  add column if not exists source_level smallint not null default 4;
alter table private.exam_prep_threshold_references
  add column if not exists source_level smallint not null default 4;
alter table private.exam_prep_ai_source_cards
  add column if not exists source_level smallint not null default 6;

do $$ begin
  alter table private.exam_prep_syllabus_nodes
    add constraint exam_prep_syllabus_nodes_source_level_check check(source_level=1);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_component_paper_profiles
    add constraint exam_prep_component_paper_profiles_source_level_check check(source_level=1);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_exam_calendar
    add constraint exam_prep_exam_calendar_source_level_check check(source_level=1);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_content_versions
    add constraint exam_prep_content_versions_source_level_check check(source_level=3);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_paper_metadata
    add constraint exam_prep_paper_metadata_source_level_check check(source_level=4);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_threshold_references
    add constraint exam_prep_threshold_references_source_level_check check(source_level=4);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_ai_source_cards
    add constraint exam_prep_ai_source_cards_source_level_check check(source_level=6);
exception when duplicate_object then null; end $$;

create table if not exists private.exam_prep_material_library (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  material_key text not null,
  material_version text not null,
  source_registry_id bigint not null references private.exam_prep_source_registry(id) on delete restrict,
  component_code text null check(component_code in ('P1','P5')),
  resource_kind text not null check(resource_kind in (
    'official_syllabus','coursebook_reference','official_past_paper_index','examiner_feedback_index'
  )),
  access_mode text not null check(access_mode in ('official_external','licensed_reference','school_request')),
  rights_status text not null check(rights_status in ('official_link_only','licensed_copy_required','protected_school_access')),
  title_en text not null,
  title_ru text not null,
  title_uz text not null,
  note_en text not null,
  note_ru text not null,
  note_uz text not null,
  official_url text null,
  status text not null default 'active' check(status in ('active','retired','superseded')),
  source_checked_at timestamptz null,
  created_at timestamptz not null default now(),
  unique(program_version_id,material_key,material_version),
  check(
    (access_mode='official_external' and rights_status='official_link_only' and official_url ~ '^https://')
    or
    (access_mode in ('licensed_reference','school_request') and official_url is null)
  )
);

create index if not exists exam_prep_material_library_active_idx
  on private.exam_prep_material_library(program_version_id,status,component_code,material_key);

alter table private.exam_prep_material_library enable row level security;
revoke all on private.exam_prep_material_library from public,anon,authenticated;
grant all on private.exam_prep_material_library to service_role;
grant usage,select on sequence private.exam_prep_material_library_id_seq to service_role;

drop trigger if exists exam_prep_material_library_audit_v1 on private.exam_prep_material_library;
create trigger exam_prep_material_library_audit_v1
after insert or update or delete on private.exam_prep_material_library
for each row execute function private.exam_prep_audit_row_change_v1();

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), materials(
  material_key,material_version,source_key,component_code,resource_kind,access_mode,rights_status,
  title_en,title_ru,title_uz,note_en,note_ru,note_uz,official_url,source_checked_at
) as (values
  (
    'cambridge_9709_syllabus_2026_2027','2026-2027','cambridge_9709_current_syllabus',null,
    'official_syllabus','official_external','official_link_only',
    'Cambridge 9709 syllabus 2026–2027','Cambridge 9709 syllabus 2026–2027','Cambridge 9709 syllabus 2026–2027',
    'Official scope reference for the current Exam Prep syllabus version.',
    'Официальный источник объёма программы для текущей версии Exam Prep.',
    'Joriy Exam Prep dastur versiyasi uchun rasmiy doira manbasi.',
    'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',now()
  ),
  (
    'complete_pure_mathematics_1_reference','coursebook_reference:v1','coursebook_teacher_learning','P1',
    'coursebook_reference','licensed_reference','licensed_copy_required',
    'Complete Pure Mathematics 1','Complete Pure Mathematics 1','Complete Pure Mathematics 1',
    'Teaching and chapter-reference source for P1. Use a legally available copy; it does not define syllabus scope.',
    'Учебный и справочный источник по главам P1. Используется законно доступная копия; учебник не определяет объём syllabus.',
    'P1 uchun o‘quv va boblar bo‘yicha ma’lumot manbasi. Qonuniy mavjud nusxadan foydalaniladi; darslik syllabus doirasini belgilamaydi.',
    null,null
  ),
  (
    'complete_probability_statistics_1_reference','coursebook_reference:v1','coursebook_teacher_learning','P5',
    'coursebook_reference','licensed_reference','licensed_copy_required',
    'Complete Probability & Statistics 1','Complete Probability & Statistics 1','Complete Probability & Statistics 1',
    'Teaching and chapter-reference source for P5. Use a legally available copy; it does not define syllabus scope.',
    'Учебный и справочный источник по главам P5. Используется законно доступная копия; учебник не определяет объём syllabus.',
    'P5 uchun o‘quv va boblar bo‘yicha ma’lumot manbasi. Qonuniy mavjud nusxadan foydalaniladi; darslik syllabus doirasini belgilamaydi.',
    null,null
  ),
  (
    'cambridge_9709_past_papers_index','official_index:v1','cambridge_official_past_paper_workflow',null,
    'official_past_paper_index','official_external','official_link_only',
    'Cambridge 9709 past papers','Cambridge 9709 past papers','Cambridge 9709 past papers',
    'Open the official Cambridge page externally. iClub stores metadata and workflow only, not protected paper or mark-scheme content.',
    'Открывается официальная страница Cambridge. iClub хранит только metadata и процесс, а не защищённые тексты papers или mark schemes.',
    'Cambridge rasmiy sahifasi tashqarida ochiladi. iClub faqat metadata va jarayonni saqlaydi, himoyalangan paper yoki mark scheme matnini emas.',
    'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',now()
  ),
  (
    'cambridge_9709_examiner_reports_index','official_index:v1','cambridge_examiner_feedback',null,
    'examiner_feedback_index','official_external','official_link_only',
    'Cambridge 9709 examiner reports','Отчёты экзаменаторов Cambridge 9709','Cambridge 9709 examiner reports',
    'Use official examiner feedback after an attempt to review recurring errors and answer quality. Protected text is not copied into iClub.',
    'Используйте официальные отчёты экзаменаторов после попытки для анализа повторяющихся ошибок и качества ответа. Защищённый текст не копируется в iClub.',
    'Urinishdan keyin takroriy xatolar va javob sifatini ko‘rib chiqish uchun rasmiy examiner feedbackdan foydalaniladi. Himoyalangan matn iClubga ko‘chirilmaydi.',
    'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',now()
  )
)
insert into private.exam_prep_material_library(
  program_version_id,material_key,material_version,source_registry_id,component_code,resource_kind,
  access_mode,rights_status,title_en,title_ru,title_uz,note_en,note_ru,note_uz,official_url,source_checked_at
)
select pv.id,m.material_key,m.material_version,sr.id,m.component_code,m.resource_kind,
       m.access_mode,m.rights_status,m.title_en,m.title_ru,m.title_uz,m.note_en,m.note_ru,m.note_uz,
       m.official_url,m.source_checked_at
from materials m
cross join pv
join private.exam_prep_source_registry sr on sr.source_key=m.source_key and sr.status='active'
on conflict(program_version_id,material_key,material_version) do nothing;

create or replace function public.get_exam_prep_materials_library_safe_v1(p_language text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_lang text:=lower(coalesce(nullif(trim(p_language),''),'en'));
  v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if v_lang not in ('en','ru','uz') then v_lang:='en'; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_materials_program_missing'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'material_key',m.material_key,
    'component_code',m.component_code,
    'resource_kind',m.resource_kind,
    'title',case v_lang when 'ru' then m.title_ru when 'uz' then m.title_uz else m.title_en end,
    'note',case v_lang when 'ru' then m.note_ru when 'uz' then m.note_uz else m.note_en end,
    'access_mode',m.access_mode,
    'external_url',case when m.access_mode='official_external' then m.official_url else null end,
    'licensed_copy_required',(m.access_mode='licensed_reference'),
    'school_request_required',(m.access_mode='school_request'),
    'source_checked_at',m.source_checked_at
  ) order by coalesce(m.component_code,''),m.material_key),'[]'::jsonb)
  into v_items
  from private.exam_prep_material_library m
  join private.exam_prep_source_registry sr on sr.id=m.source_registry_id and sr.status='active'
  where m.program_version_id=v_program and m.status='active';

  return jsonb_build_object(
    'language',v_lang,
    'materials',v_items,
    'rights_respected',true,
    'protected_content_embedded',false,
    'official_links_open_externally',true
  );
end;
$$;
revoke execute on function public.get_exam_prep_materials_library_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_materials_library_safe_v1(text) to authenticated,service_role;

create or replace function public.get_exam_prep_working_tools_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_p1_tracker jsonb;
  v_p5_tracker jsonb;
  v_p1_corrections jsonb;
  v_p5_corrections jsonb;
  v_p1_resolved int:=0;
  v_p5_resolved int:=0;
  v_p1_timed int:=0;
  v_p1_full int:=0;
  v_p1_comparable_full int:=0;
  v_p5_timed int:=0;
  v_p5_full int:=0;
  v_p5_comparable_full int:=0;
  v_p1_plan private.exam_prep_weekly_plans%rowtype;
  v_p5_plan private.exam_prep_weekly_plans%rowtype;
  v_p1_plan_items int:=0;
  v_p5_plan_items int:=0;
  v_material_count int:=0;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_working_tools_program_missing'; end if;

  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=v_uid and program_version_id=v_program;

  v_p1_tracker:=private.exam_prep_syllabus_tracker_payload_v1(v_uid,'P1');
  v_p5_tracker:=private.exam_prep_syllabus_tracker_payload_v1(v_uid,'P5');
  v_p1_corrections:=private.exam_prep_correction_queue_payload_v1(v_uid,'P1');
  v_p5_corrections:=private.exam_prep_correction_queue_payload_v1(v_uid,'P5');

  select count(*)::int into v_p1_resolved
  from private.exam_prep_correction_cases
  where user_id=v_uid and component_code='P1' and status='resolved';
  select count(*)::int into v_p5_resolved
  from private.exam_prep_correction_cases
  where user_id=v_uid and component_code='P5' and status='resolved';

  select count(*)::int,
         (count(*) filter(where t.attempt_kind='full_paper'))::int,
         (count(*) filter(where t.attempt_kind='full_paper' and private.exam_prep_timed_score_comparable_v1(t.session_id)))::int
    into v_p1_timed,v_p1_full,v_p1_comparable_full
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  where t.user_id=v_uid and t.component_code='P1'
    and s.user_id=v_uid and s.program_version_id=v_program and s.component_code='P1' and s.status='finalized';

  select count(*)::int,
         (count(*) filter(where t.attempt_kind='full_paper'))::int,
         (count(*) filter(where t.attempt_kind='full_paper' and private.exam_prep_timed_score_comparable_v1(t.session_id)))::int
    into v_p5_timed,v_p5_full,v_p5_comparable_full
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  where t.user_id=v_uid and t.component_code='P5'
    and s.user_id=v_uid and s.program_version_id=v_program and s.component_code='P5' and s.status='finalized';

  select * into v_p1_plan from private.exam_prep_weekly_plans
  where user_id=v_uid and program_version_id=v_program and component_code='P1' and status='active'
  order by generated_at desc limit 1;
  if v_p1_plan.id is not null then
    select count(*)::int into v_p1_plan_items from private.exam_prep_weekly_plan_items where plan_id=v_p1_plan.id;
  end if;

  select * into v_p5_plan from private.exam_prep_weekly_plans
  where user_id=v_uid and program_version_id=v_program and component_code='P5' and status='active'
  order by generated_at desc limit 1;
  if v_p5_plan.id is not null then
    select count(*)::int into v_p5_plan_items from private.exam_prep_weekly_plan_items where plan_id=v_p5_plan.id;
  end if;

  select count(*)::int into v_material_count
  from private.exam_prep_material_library m
  join private.exam_prep_source_registry sr on sr.id=m.source_registry_id and sr.status='active'
  where m.program_version_id=v_program and m.status='active';

  return jsonb_build_object(
    'contract_version','p2_10_c21_v1',
    'read_only',true,
    'p1_p5_separate',true,
    'legacy_state_mutated',false,
    'exam_map',jsonb_build_object(
      'status',case when v_profile.user_id is null then 'required' else 'configured' end,
      'profile_revision',v_profile.profile_revision,
      'exam_series',v_profile.exam_series,
      'target_grade',v_profile.target_grade,
      'components',jsonb_build_array('P1','P5')
    ),
    'syllabus_tracker',jsonb_build_object(
      'P1',jsonb_build_object(
        'denominator_count',(v_p1_tracker->>'denominator_count')::int,
        'coverage_count',(v_p1_tracker->>'coverage_count')::int,
        'coverage_pct',(v_p1_tracker->>'coverage_pct')::numeric,
        'open_correction_count',(v_p1_tracker->>'open_correction_count')::int
      ),
      'P5',jsonb_build_object(
        'denominator_count',(v_p5_tracker->>'denominator_count')::int,
        'coverage_count',(v_p5_tracker->>'coverage_count')::int,
        'coverage_pct',(v_p5_tracker->>'coverage_pct')::numeric,
        'open_correction_count',(v_p5_tracker->>'open_correction_count')::int
      )
    ),
    'score_tracker',jsonb_build_object(
      'P1',jsonb_build_object('timed_or_paper_attempts',v_p1_timed,'full_papers',v_p1_full,'current_comparable_full_papers',v_p1_comparable_full),
      'P5',jsonb_build_object('timed_or_paper_attempts',v_p5_timed,'full_papers',v_p5_full,'current_comparable_full_papers',v_p5_comparable_full)
    ),
    'error_journal',jsonb_build_object(
      'P1',jsonb_build_object('active_count',(v_p1_corrections->>'active_count')::int,'resolved_count',v_p1_resolved),
      'P5',jsonb_build_object('active_count',(v_p5_corrections->>'active_count')::int,'resolved_count',v_p5_resolved)
    ),
    'materials_library',jsonb_build_object('active_materials',v_material_count,'protected_content_embedded',false),
    'weekly_plan',jsonb_build_object(
      'P1',jsonb_build_object('has_active_plan',(v_p1_plan.id is not null),'recovery_mode',coalesce(v_p1_plan.recovery_mode,'normal'),'priority_count',v_p1_plan_items),
      'P5',jsonb_build_object('has_active_plan',(v_p5_plan.id is not null),'recovery_mode',coalesce(v_p5_plan.recovery_mode,'normal'),'priority_count',v_p5_plan_items)
    )
  );
end;
$$;
revoke execute on function public.get_exam_prep_working_tools_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_working_tools_safe_v1() to authenticated,service_role;

-- Release assertions: hierarchy authority, rights boundary and private storage must be structural.
do $$
declare
  v_levels int;
  v_materials int;
  v_def text;
begin
  select count(distinct source_level) into v_levels
  from private.exam_prep_source_registry where status='active';
  if v_levels<>6 then raise exception 'P2-10 source hierarchy: expected active levels 1..6'; end if;

  if exists(
    select 1 from private.exam_prep_source_registry
    where status='active' and source_level<>1 and (can_define_scope or can_define_coverage_denominator)
  ) then raise exception 'P2-10 source hierarchy: lower source gained scope authority'; end if;

  if exists(
    select 1 from private.exam_prep_source_registry
    where status='active' and can_support_assessment_evidence and source_level not in (3,4)
  ) then raise exception 'P2-10 source hierarchy: invalid assessment-evidence authority'; end if;

  if not exists(
    select 1 from private.exam_prep_source_registry
    where status='active' and source_level=6 and downstream_only
  ) then raise exception 'P2-10 source hierarchy: downstream-only level missing'; end if;

  if exists(select 1 from private.exam_prep_syllabus_nodes where source_level<>1)
     or exists(select 1 from private.exam_prep_component_paper_profiles where source_level<>1)
     or exists(select 1 from private.exam_prep_exam_calendar where source_level<>1)
     or exists(select 1 from private.exam_prep_content_versions where source_level<>3)
     or exists(select 1 from private.exam_prep_paper_metadata where source_level<>4)
     or exists(select 1 from private.exam_prep_threshold_references where source_level<>4)
     or exists(select 1 from private.exam_prep_ai_source_cards where source_level<>6) then
    raise exception 'P2-10 source hierarchy: existing metadata mapped to wrong source level';
  end if;

  if exists(
    select 1 from private.exam_prep_material_library
    where (access_mode<>'official_external' and official_url is not null)
       or (access_mode='official_external' and official_url !~ '^https://')
  ) then raise exception 'P2-10 materials: rights/link boundary failed'; end if;

  select count(*) into v_materials from private.exam_prep_material_library where status='active';
  if v_materials<5 then raise exception 'P2-10 materials: governed seed set incomplete'; end if;

  if has_table_privilege('authenticated','private.exam_prep_source_registry','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_material_library','SELECT') then
    raise exception 'P2-10 private registry/material tables exposed';
  end if;

  select pg_get_functiondef('public.get_exam_prep_materials_library_safe_v1(text)'::regprocedure) into v_def;
  if position('correct_answer' in lower(v_def))>0 or position('source_level' in lower(v_def))>0 then
    raise exception 'P2-10 materials API exposes protected/internal authority data';
  end if;
end $$;

commit;
