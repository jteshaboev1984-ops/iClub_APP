-- P2-06 Stage-6 Final Calibration / exam operations v1.
-- Adds component-specific exam logistics, taper checklist and an exact >=24h major-work stop when the learner confirms the school start time.
-- No Cambridge 2027 exam date is invented here: the public June 2027 final timetable is not yet available on 2026-09-08.
-- Calendar rows count only when separately loaded from a verified final timetable. Checklist/appointment state never creates mastery or readiness.

begin;

create table if not exists private.exam_prep_exam_calendar (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  paper_code text not null,
  exam_series_key text not null,
  exam_date date not null,
  session_code text null check(session_code is null or session_code in ('AM','PM')),
  timetable_version text not null,
  status text not null check(status in ('draft','final_verified','retired')),
  source_url text not null,
  verified_at timestamptz null,
  source_note text not null,
  created_at timestamptz not null default now(),
  unique(program_version_id,component_code,exam_series_key,timetable_version)
);
create unique index if not exists exam_prep_exam_calendar_one_final_idx
  on private.exam_prep_exam_calendar(program_version_id,component_code,lower(exam_series_key))
  where status='final_verified';

create table if not exists private.exam_prep_exam_appointments (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  scheduled_start_at timestamptz not null,
  confirmation_source text not null default 'learner_school_confirmation'
    check(confirmation_source in ('learner_school_confirmation','staff_school_confirmation')),
  confirmed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code)
);

create table if not exists private.exam_prep_exam_ops_checklist_items (
  item_code text primary key,
  item_order smallint not null unique check(item_order between 1 and 20),
  title_ru text not null,
  title_uz text not null,
  title_en text not null,
  item_kind text not null check(item_kind in ('logistics','equipment','wellbeing','taper')),
  active boolean not null default true,
  source_note text not null
);

create table if not exists private.exam_prep_exam_ops_confirmations (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  item_code text not null references private.exam_prep_exam_ops_checklist_items(item_code) on delete restrict,
  confirmed boolean not null default false,
  confirmed_at timestamptz null,
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code,item_code)
);

alter table private.exam_prep_exam_calendar enable row level security;
alter table private.exam_prep_exam_appointments enable row level security;
alter table private.exam_prep_exam_ops_checklist_items enable row level security;
alter table private.exam_prep_exam_ops_confirmations enable row level security;
revoke all on private.exam_prep_exam_calendar from public,anon,authenticated;
revoke all on private.exam_prep_exam_appointments from public,anon,authenticated;
revoke all on private.exam_prep_exam_ops_checklist_items from public,anon,authenticated;
revoke all on private.exam_prep_exam_ops_confirmations from public,anon,authenticated;
grant all on private.exam_prep_exam_calendar,private.exam_prep_exam_appointments,private.exam_prep_exam_ops_checklist_items,private.exam_prep_exam_ops_confirmations to service_role;
grant usage,select on sequence private.exam_prep_exam_calendar_id_seq to service_role;

do $$ begin execute 'create trigger exam_prep_exam_calendar_audit_v1 after insert or update or delete on private.exam_prep_exam_calendar for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
do $$ begin execute 'create trigger exam_prep_exam_appointments_audit_v1 after insert or update or delete on private.exam_prep_exam_appointments for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
do $$ begin execute 'create trigger exam_prep_exam_ops_confirmations_audit_v1 after insert or update or delete on private.exam_prep_exam_ops_confirmations for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;

insert into private.exam_prep_exam_ops_checklist_items(item_code,item_order,title_ru,title_uz,title_en,item_kind,active,source_note)
values
  ('school_date_session_checked',1,'Проверить дату и экзаменационную сессию по информации школы','Imtihon sanasi va sessiyasini maktab ma’lumoti bo‘yicha tekshirish','Check the exam date and session against the school information','logistics',true,'Master Plan P2-06: official timetable / exam logistics must be confirmed.'),
  ('exact_start_arrival_checked',2,'Подтвердить точное время начала и время прибытия','Aniq boshlanish va yetib kelish vaqtini tasdiqlash','Confirm the exact start time and arrival time','logistics',true,'Cambridge timetable gives the session; the centre/school supplies detailed start arrangements.'),
  ('allowed_equipment_checked',3,'Проверить разрешённые материалы и оборудование по инструкции школы и Cambridge','Ruxsat etilgan material va jihozlarni maktab hamda Cambridge ko‘rsatmasi bo‘yicha tekshirish','Check permitted materials and equipment against school and Cambridge instructions','equipment',true,'Do not hard-code equipment rules that can change; learner confirms against current official/school instructions.'),
  ('travel_arrival_plan_ready',4,'Заранее спланировать дорогу и прибытие','Yo‘l va yetib kelishni oldindan rejalashtirish','Plan travel and arrival in advance','logistics',true,'Master Plan P2-06 exam logistics.'),
  ('sleep_recovery_plan_ready',5,'Сохранить сон и восстановление перед экзаменом','Imtihondan oldin uyqu va tiklanishni saqlash','Protect sleep and recovery before the exam','wellbeing',true,'Master Plan Stage 6 protects performance rather than chasing volume.'),
  ('short_review_plan_ready',6,'Оставить только короткое повторение и точечную работу по подтверждённым слабым местам','Faqat qisqa takrorlash va tasdiqlangan zaif joylar bo‘yicha aniq ishni qoldirish','Keep only short review and targeted work on confirmed weak points','taper',true,'Master Plan Stage 6: short reserved/targeted work; no bulk new content.'),
  ('major_work_stop_understood',7,'Не начинать большую новую работу менее чем за 24 часа до экзамена','Imtihonga 24 soatdan kam qolganda katta yangi ishni boshlamaslik','Do not start major new work within 24 hours of the exam','taper',true,'Master Plan P2-06 / Annual Roadmap: major work ends at least 24 hours before the exam.')
on conflict(item_code) do update set
  item_order=excluded.item_order,title_ru=excluded.title_ru,title_uz=excluded.title_uz,title_en=excluded.title_en,
  item_kind=excluded.item_kind,active=excluded.active,source_note=excluded.source_note;

create or replace function private.exam_prep_exam_ops_status_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_calendar private.exam_prep_exam_calendar%rowtype;
  v_appointment private.exam_prep_exam_appointments%rowtype;
  v_ready jsonb;
  v_stage smallint:=0;
  v_items jsonb:='[]'::jsonb;
  v_total int:=0;
  v_done int:=0;
  v_stop_at timestamptz;
  v_mode text;
  v_notices jsonb:='[]'::jsonb;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=p_user_id and program_version_id=p_program_version_id;
  if v_profile.user_id is null then raise exception 'exam_prep_profile_required'; end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(p_user_id,p_program_version_id,p_component_code);
  select coalesce(operational_stage,0) into v_stage
  from private.exam_prep_stage_states
  where user_id=p_user_id and program_version_id=p_program_version_id and component_code=p_component_code
  order by derived_at desc limit 1;

  if nullif(trim(v_profile.exam_series),'') is not null then
    select * into v_calendar from private.exam_prep_exam_calendar c
    where c.program_version_id=p_program_version_id and c.component_code=p_component_code
      and c.status='final_verified' and lower(trim(c.exam_series_key))=lower(trim(v_profile.exam_series))
    order by c.verified_at desc nulls last,c.id desc limit 1;
  end if;

  select * into v_appointment from private.exam_prep_exam_appointments a
  where a.user_id=p_user_id and a.program_version_id=p_program_version_id and a.component_code=p_component_code;
  if v_appointment.user_id is not null then v_stop_at:=v_appointment.scheduled_start_at-interval '24 hours'; end if;

  select count(*)::int,count(*) filter(where coalesce(c.confirmed,false))::int,
         coalesce(jsonb_agg(jsonb_build_object(
           'item_code',i.item_code,'item_order',i.item_order,'title_ru',i.title_ru,'title_uz',i.title_uz,'title_en',i.title_en,
           'item_kind',i.item_kind,'confirmed',coalesce(c.confirmed,false),'confirmed_at',c.confirmed_at
         ) order by i.item_order),'[]'::jsonb)
  into v_total,v_done,v_items
  from private.exam_prep_exam_ops_checklist_items i
  left join private.exam_prep_exam_ops_confirmations c
    on c.user_id=p_user_id and c.program_version_id=p_program_version_id and c.component_code=p_component_code and c.item_code=i.item_code
  where i.active;

  if v_appointment.user_id is null then v_mode:='start_time_confirmation_needed';
  elsif now()>=v_appointment.scheduled_start_at then v_mode:='component_time_reached';
  elsif now()>=v_stop_at then v_mode:='stop_major_work';
  else v_mode:='targeted_taper'; end if;

  if v_calendar.id is null then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','final_timetable_not_verified','priority',1)); end if;
  if v_appointment.user_id is null then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','school_start_time_not_confirmed','priority',1)); end if;
  if v_mode='stop_major_work' then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','major_work_stop_active','priority',1)); end if;
  if v_mode='component_time_reached' then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','component_time_reached','priority',1)); end if;

  return jsonb_build_object(
    'available',coalesce((v_ready->>'ready')::boolean,false),
    'component_code',p_component_code,
    'operational_stage',v_stage,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'final_timetable_verified',v_calendar.id is not null,
    'paper_code',v_calendar.paper_code,
    'exam_date',v_calendar.exam_date,
    'session_code',v_calendar.session_code,
    'timetable_version',v_calendar.timetable_version,
    'timetable_source_url',v_calendar.source_url,
    'school_start_time_confirmed',v_appointment.user_id is not null,
    'scheduled_start_at',v_appointment.scheduled_start_at,
    'major_work_stop_at',v_stop_at,
    'major_work_stop_rule_hours',24,
    'calibration_mode',v_mode,
    'checklist_total',v_total,
    'checklist_confirmed',v_done,
    'checklist_complete',(v_total>0 and v_total=v_done),
    'checklist_items',v_items,
    'notifications',v_notices,
    'new_mastery_allowed',false,
    'readiness_can_be_created_by_checklist',false,
    'note','Exam operations are planning/logistics only. They do not create mastery or readiness. Exact start time must come from the learner school/centre; a final Cambridge timetable row is stored only after source verification.'
  );
end;
$$;
revoke all on function private.exam_prep_exam_ops_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_exam_ops_status_v1(uuid,bigint,text) to service_role;

create or replace function public.get_exam_prep_exam_ops_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;
  return private.exam_prep_exam_ops_status_v1(v_uid,v_program,p_component_code);
end;
$$;
revoke execute on function public.get_exam_prep_exam_ops_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_exam_ops_safe_v1(text) to authenticated,service_role;

create or replace function public.save_my_exam_prep_exam_appointment_v1(
  p_component_code text,
  p_scheduled_start_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_scheduled_start_at is null then raise exception 'exam_prep_exam_start_required'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  insert into private.exam_prep_exam_appointments(user_id,program_version_id,component_code,scheduled_start_at,confirmation_source,confirmed_at,updated_at)
  values(v_uid,v_program,p_component_code,p_scheduled_start_at,'learner_school_confirmation',now(),now())
  on conflict(user_id,program_version_id,component_code) do update set
    scheduled_start_at=excluded.scheduled_start_at,confirmation_source=excluded.confirmation_source,
    confirmed_at=now(),updated_at=now();

  return private.exam_prep_exam_ops_status_v1(v_uid,v_program,p_component_code);
end;
$$;
revoke execute on function public.save_my_exam_prep_exam_appointment_v1(text,timestamptz) from public,anon;
grant execute on function public.save_my_exam_prep_exam_appointment_v1(text,timestamptz) to authenticated,service_role;

create or replace function public.set_my_exam_prep_exam_ops_confirmation_v1(
  p_component_code text,
  p_item_code text,
  p_confirmed boolean
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_code text:=trim(coalesce(p_item_code,''));
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if not exists(select 1 from private.exam_prep_exam_ops_checklist_items where item_code=v_code and active) then raise exception 'exam_prep_bad_exam_ops_item'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  insert into private.exam_prep_exam_ops_confirmations(user_id,program_version_id,component_code,item_code,confirmed,confirmed_at,updated_at)
  values(v_uid,v_program,p_component_code,v_code,coalesce(p_confirmed,false),case when coalesce(p_confirmed,false) then now() else null end,now())
  on conflict(user_id,program_version_id,component_code,item_code) do update set
    confirmed=excluded.confirmed,confirmed_at=excluded.confirmed_at,updated_at=now();

  return private.exam_prep_exam_ops_status_v1(v_uid,v_program,p_component_code);
end;
$$;
revoke execute on function public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean) from public,anon;
grant execute on function public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean) to authenticated,service_role;

-- Keep the existing Final Calibration contract and attach the component exam-operations status.
create or replace function public.get_exam_prep_final_calibration_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid; v_program bigint; v_profile private.exam_prep_exam_profiles%rowtype; v_ready jsonb; v_stage smallint:=0;
  v_open_cases int:=0; v_latest_skill text; v_latest_case uuid; v_actions jsonb; v_ops jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  v_program:=v_profile.program_version_id;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  v_ops:=private.exam_prep_exam_ops_status_v1(v_uid,v_program,p_component_code);
  select coalesce(operational_stage,0) into v_stage from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code order by derived_at desc limit 1;
  select count(*),(array_agg(skill_code order by updated_at desc,id desc))[1],(array_agg(id order by updated_at desc,id desc))[1]
  into v_open_cases,v_latest_skill,v_latest_case from private.exam_prep_correction_cases
  where user_id=v_uid and component_code=p_component_code and status in ('open','remediating','retest_due','reopened');

  v_actions:=jsonb_build_array(
    jsonb_build_object('action_code','short_targeted_work','priority',1,'purpose','Maintain exam form with short evidence-driven work; do not reopen the whole syllabus.'),
    jsonb_build_object('action_code','timing_and_logistics','priority',2,'purpose','Confirm component timing and exam logistics through the approved exam-profile process.'),
    jsonb_build_object('action_code','taper','priority',3,'purpose','Reduce bulk workload and protect sleep/recovery; calibration volume does not create new mastery.')
  );
  if v_open_cases>0 then
    v_actions:=jsonb_build_array(jsonb_build_object('action_code','close_recurring_issue','priority',1,'purpose','Resolve the highest-priority remaining evidence-based correction before adding optional work.','skill_code',v_latest_skill,'correction_case_id',v_latest_case))||v_actions;
  end if;

  return jsonb_build_object(
    'available',coalesce((v_ready->>'ready')::boolean,false),'component_code',p_component_code,'operational_stage',v_stage,
    'exam_series',v_profile.exam_series,'target_grade',v_profile.target_grade,'readiness',v_ready-'threshold_version',
    'open_correction_cases',v_open_cases,'actions',v_actions,'exam_operations',v_ops,
    'new_mastery_allowed',false,
    'mentor_verified_readiness',coalesce((private.exam_prep_mentor_verified_readiness_status_v1(v_uid,v_program,p_component_code)->>'mentor_verified')::boolean,false),
    'note','Final Calibration is component-specific taper/logistics support. It is not a predicted Cambridge grade and does not create mastery from last-minute work.'
  );
end;
$$;
revoke execute on function public.get_exam_prep_final_calibration_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_final_calibration_safe_v1(text) to authenticated,service_role;

do $$
declare v_calendar_rows int; v_items int; v_approved int; v_def text;
begin
  select count(*) into v_calendar_rows from private.exam_prep_exam_calendar where status='final_verified';
  if v_calendar_rows<>0 then raise exception 'P2-06 release must not invent a 2027 final timetable row'; end if;
  select count(*) into v_items from private.exam_prep_exam_ops_checklist_items where active;
  if v_items<>7 then raise exception 'P2-06 expected seven active exam-ops checklist items got %',v_items; end if;
  select count(*) into v_approved from private.exam_prep_stage5_thresholds where status='approved';
  if v_approved<>0 then raise exception 'P2-06 release must not approve Stage-5 thresholds'; end if;
  select pg_get_functiondef('public.get_exam_prep_final_calibration_safe_v1(text)'::regprocedure) into v_def;
  if position('order by derived_at desc' in lower(v_def))=0 or position('exam_operations' in lower(v_def))=0 then
    raise exception 'P2-06 final calibration integration missing';
  end if;
end $$;

commit;
