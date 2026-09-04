-- P1-02: governed annual content runway contract.
-- Additive/fail-closed. No legacy row is reinterpreted or activated.
-- A learner-facing learning priority requires BOTH a fully governed content floor and an active runway schedule window.

begin;

create table if not exists private.exam_prep_content_runway_releases (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  runway_version text not null,
  release_key text not null,
  component_code text not null check(component_code in ('P1','P5')),
  active_week_from smallint not null check(active_week_from>=1),
  active_week_through smallint not null check(active_week_through>=active_week_from),
  schedule_status text not null default 'active' check(schedule_status in ('active','retired')),
  release_note text not null,
  created_at timestamptz not null default now(),
  retired_at timestamptz null,
  unique(program_version_id,runway_version,release_key,component_code)
);

create table if not exists private.exam_prep_content_runway_release_skills (
  release_id bigint not null references private.exam_prep_content_runway_releases(id) on delete cascade,
  skill_code text not null,
  required_for_release boolean not null default true,
  created_at timestamptz not null default now(),
  primary key(release_id,skill_code)
);

create index if not exists exam_prep_runway_release_window_idx
  on private.exam_prep_content_runway_releases(program_version_id,component_code,active_week_from,active_week_through)
  where schedule_status='active';
create index if not exists exam_prep_runway_release_skills_skill_idx
  on private.exam_prep_content_runway_release_skills(skill_code,release_id);

do $$ declare t text; begin
  foreach t in array array['exam_prep_content_runway_releases','exam_prep_content_runway_release_skills'] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

grant usage,select on sequence private.exam_prep_content_runway_releases_id_seq to service_role;

do $$ begin
  execute 'create trigger exam_prep_content_runway_releases_audit_v1 after insert or update or delete on private.exam_prep_content_runway_releases for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_content_runway_release_skills_audit_v1 after insert or update or delete on private.exam_prep_content_runway_release_skills for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;

create or replace function private.exam_prep_validate_runway_skill_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_r private.exam_prep_content_runway_releases%rowtype;
begin
  select * into v_r from private.exam_prep_content_runway_releases where id=new.release_id;
  if v_r.id is null then raise exception 'exam_prep_runway_release_not_found'; end if;
  if not exists(
    select 1 from private.exam_prep_syllabus_nodes s
    where s.program_version_id=v_r.program_version_id
      and s.component_code=v_r.component_code
      and s.skill_code=new.skill_code
  ) then
    raise exception 'exam_prep_runway_skill_component_mismatch: % / %',v_r.component_code,new.skill_code;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_validate_runway_skill_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_validate_runway_skill_v1 on private.exam_prep_content_runway_release_skills;
create trigger exam_prep_validate_runway_skill_v1
before insert or update of release_id,skill_code on private.exam_prep_content_runway_release_skills
for each row execute function private.exam_prep_validate_runway_skill_v1();

-- Exact beta-floor evaluation for one skill inside one content version.
create or replace function private.exam_prep_content_skill_floor_in_version_v1(
  p_content_version_id bigint,
  p_skill_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_cv private.exam_prep_content_versions%rowtype;
  v_component text;
  v_diag int:=0; v_learning int:=0; v_retest int:=0; v_mixed int:=0; v_unseen int:=0;
  v_written int:=0; v_rules int:=0; v_bad_q int:=0; v_bad_qa int:=0;
  v_holdout_total int:=0; v_holdout_withheld int:=0; v_holdout_pct numeric:=0;
  v_learning_assessment boolean:=false; v_diag_assessment boolean:=false; v_retest_assessment boolean:=false; v_mixed_assessment boolean:=false;
  v_ready boolean:=false;
begin
  select * into v_cv from private.exam_prep_content_versions where id=p_content_version_id;
  if v_cv.id is null then return jsonb_build_object('ready',false,'reason','content_version_not_found'); end if;
  v_component:=v_cv.component_code;
  if not exists(select 1 from private.exam_prep_syllabus_nodes s where s.program_version_id=v_cv.program_version_id and s.component_code=v_component and s.skill_code=p_skill_code) then
    return jsonb_build_object('ready',false,'reason','skill_component_mismatch');
  end if;

  select
    count(*) filter(where m.reserve_role='diagnostic' and m.lifecycle_state='reserve' and m.exposure_state='withheld'),
    count(*) filter(where m.reserve_role='learning' and m.lifecycle_state='published' and m.exposure_state='released'),
    count(*) filter(where m.reserve_role='retest' and m.lifecycle_state='reserve' and m.exposure_state='withheld'),
    count(*) filter(where m.reserve_role='mixed' and m.lifecycle_state='reserve' and m.exposure_state='withheld'),
    count(*) filter(where m.reserve_role='unseen' and m.lifecycle_state='reserve' and m.exposure_state='withheld'),
    count(*) filter(where not (
      m.copyright_status='pass' and m.qa_scope_status='pass' and m.qa_math_status='pass' and
      m.qa_language_status='pass' and m.qa_technical_status='pass'
    ))
  into v_diag,v_learning,v_retest,v_mixed,v_unseen,v_bad_qa
  from private.exam_prep_question_content_meta m
  where m.content_version_id=v_cv.id and m.primary_skill_code=p_skill_code
    and m.lifecycle_state in ('published','reserve');

  select count(*) into v_written
  from private.exam_prep_written_tasks w
  where w.content_version_id=v_cv.id and w.component_code=v_component and w.primary_skill_code=p_skill_code
    and w.lifecycle_state='published'
    and w.copyright_status='pass' and w.qa_math_status='pass' and w.qa_language_status='pass' and w.qa_technical_status='pass'
    and jsonb_typeof(w.rubric_json)='object' and coalesce(nullif(w.rubric_json->>'max_marks','')::int,0)>0;

  select count(*) into v_rules
  from private.exam_prep_diagnostic_rules r
  join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv.id and m.primary_skill_code=p_skill_code and m.reserve_role='diagnostic'
    and r.status='approved' and r.answer_kind='mcq_option' and r.answer_match<>q.correct_answer
    and nullif(trim(r.feedback_en),'') is not null and nullif(trim(r.feedback_ru),'') is not null and nullif(trim(r.feedback_uz),'') is not null
    and nullif(trim(r.next_action_en),'') is not null and nullif(trim(r.next_action_ru),'') is not null and nullif(trim(r.next_action_uz),'') is not null;

  select count(*) into v_bad_q
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv.id and m.primary_skill_code=p_skill_code and m.lifecycle_state in ('published','reserve') and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
      coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,''))) <> m.question_snapshot_md5
  );

  select count(*),count(*) filter(where m.lifecycle_state='reserve' and m.exposure_state='withheld')
    into v_holdout_total,v_holdout_withheld
  from private.exam_prep_question_content_meta m
  where m.content_version_id=v_cv.id and m.primary_skill_code=p_skill_code
    and m.reserve_role in ('retest','mixed','unseen') and m.lifecycle_state in ('published','reserve');
  v_holdout_pct:=case when v_holdout_total=0 then 0 else (100.0*v_holdout_withheld/v_holdout_total) end;

  select exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.component_code=v_component and a.assessment_type='diagnostic' and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code and ai.reserve_role='diagnostic' and ai.is_holdout)
  ) into v_diag_assessment;
  select exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.component_code=v_component and a.assessment_type='learning' and a.status='published'
      and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code and ai.question_id is not null and ai.reserve_role='learning')>=3
      and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code and ai.written_task_id is not null and ai.reserve_role='written')>=1
      and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>p_skill_code)
  ) into v_learning_assessment;
  select exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.component_code=v_component and a.assessment_type='retest' and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code and ai.reserve_role='retest' and ai.is_holdout)
  ) into v_retest_assessment;
  select exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.component_code=v_component and a.assessment_type='mixed' and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code and ai.reserve_role='mixed' and ai.is_holdout)
  ) into v_mixed_assessment;

  v_ready := v_diag>=1 and v_learning>=3 and v_retest>=2 and v_mixed>=1 and v_written>=1
    and v_rules>=3*v_diag and v_bad_q=0 and v_bad_qa=0 and v_holdout_pct>=20
    and v_diag_assessment and v_learning_assessment and v_retest_assessment and v_mixed_assessment;

  return jsonb_build_object(
    'ready',v_ready,'content_version_id',v_cv.id,'content_version',v_cv.content_version,
    'component_code',v_component,'skill_code',p_skill_code,
    'counts',jsonb_build_object('diagnostic',v_diag,'learning',v_learning,'retest',v_retest,'mixed',v_mixed,'unseen',v_unseen,'written',v_written,'diagnostic_rules',v_rules),
    'holdout',jsonb_build_object('eligible',v_holdout_total,'withheld',v_holdout_withheld,'percent',round(v_holdout_pct,1)),
    'assessments',jsonb_build_object('diagnostic',v_diag_assessment,'learning',v_learning_assessment,'retest',v_retest_assessment,'mixed',v_mixed_assessment),
    'bad_question_rows',v_bad_q,'bad_qa_rows',v_bad_qa
  );
end;
$$;
revoke all on function private.exam_prep_content_skill_floor_in_version_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_content_skill_floor_in_version_v1(bigint,text) to service_role;

-- Future content cannot transition to PUBLISHED unless every governed skill in that version meets the full beta floor.
create or replace function private.exam_prep_content_version_publish_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_skill text; v_floor jsonb; v_n int;
begin
  if new.status<>'published' or old.status is not distinct from new.status then return new; end if;
  select count(distinct m.primary_skill_code) into v_n
  from private.exam_prep_question_content_meta m where m.content_version_id=new.id and m.lifecycle_state in ('published','reserve');
  if v_n<1 then raise exception 'exam_prep_content_publish_empty_version'; end if;
  for v_skill in
    select distinct m.primary_skill_code from private.exam_prep_question_content_meta m
    where m.content_version_id=new.id and m.lifecycle_state in ('published','reserve')
  loop
    v_floor:=private.exam_prep_content_skill_floor_in_version_v1(new.id,v_skill);
    if coalesce((v_floor->>'ready')::boolean,false) is not true then
      raise exception 'exam_prep_content_publish_floor_not_met skill=% detail=%',v_skill,v_floor::text;
    end if;
  end loop;
  return new;
end;
$$;
revoke all on function private.exam_prep_content_version_publish_guard_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_content_version_publish_guard_v1 on private.exam_prep_content_versions;
create trigger exam_prep_content_version_publish_guard_v1
before update of status on private.exam_prep_content_versions
for each row execute function private.exam_prep_content_version_publish_guard_v1();

-- Cross-version readiness: a skill is ready if at least one PUBLISHED version independently satisfies the full floor.
create or replace function private.exam_prep_skill_content_ready_v1(
  p_program_version_id bigint,p_component_code text,p_skill_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1 from private.exam_prep_content_versions cv
    where cv.program_version_id=p_program_version_id and cv.component_code=p_component_code and cv.status='published'
      and coalesce((private.exam_prep_content_skill_floor_in_version_v1(cv.id,p_skill_code)->>'ready')::boolean,false)
  );
$$;
revoke all on function private.exam_prep_skill_content_ready_v1(bigint,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_content_ready_v1(bigint,text,text) to service_role;

create or replace function private.exam_prep_skill_runway_ready_for_week_v1(
  p_program_version_id bigint,p_component_code text,p_skill_code text,p_active_week_no smallint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.exam_prep_skill_content_ready_v1(p_program_version_id,p_component_code,p_skill_code)
    and exists(
      select 1
      from private.exam_prep_content_runway_releases r
      join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
      where r.program_version_id=p_program_version_id and r.component_code=p_component_code and r.schedule_status='active'
        and p_active_week_no between r.active_week_from and r.active_week_through
        and rs.skill_code=p_skill_code
    );
$$;
revoke all on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) to service_role;

-- Fail closed if any code path attempts to insert a normal learning priority outside the governed runway.
create or replace function private.exam_prep_weekly_learning_runway_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_plan private.exam_prep_weekly_plans%rowtype;
begin
  if new.item_type<>'learning' then return new; end if;
  if new.skill_code is null then raise exception 'exam_prep_runway_learning_skill_required'; end if;
  select * into v_plan from private.exam_prep_weekly_plans where id=new.plan_id;
  if v_plan.id is null then raise exception 'exam_prep_runway_plan_not_found'; end if;
  if not private.exam_prep_skill_runway_ready_for_week_v1(v_plan.program_version_id,v_plan.component_code,new.skill_code,v_plan.active_week_no) then
    raise exception 'exam_prep_learning_content_outside_ready_runway: component=% skill=% aw=%',v_plan.component_code,new.skill_code,v_plan.active_week_no;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_weekly_learning_runway_guard_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_weekly_learning_runway_guard_v1 on private.exam_prep_weekly_plan_items;
create trigger exam_prep_weekly_learning_runway_guard_v1
before insert or update of plan_id,item_type,skill_code on private.exam_prep_weekly_plan_items
for each row execute function private.exam_prep_weekly_learning_runway_guard_v1();

-- AW1-4 opening release registry. Readiness is derived; these rows do not publish or activate content.
with pv as (
  select id from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_content_runway_releases(program_version_id,runway_version,release_key,component_code,active_week_from,active_week_through,schedule_status,release_note)
select pv.id,'annual_runway_v1','aw01_04_foundations','P1',1,4,'active','AW1-4 governed opening runway: Quadratics/Functions; target 10-15% component coverage.' from pv
union all
select pv.id,'annual_runway_v1','aw01_04_foundations','P5',1,4,'active','AW1-4 governed opening runway: Representation of Data; target 10-15% component coverage.' from pv
on conflict(program_version_id,runway_version,release_key,component_code) do nothing;

with rel as (
  select r.id,r.component_code from private.exam_prep_content_runway_releases r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
    and r.runway_version='annual_runway_v1' and r.release_key='aw01_04_foundations'
), skills(component_code,skill_code) as (values
  ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
  ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
)
insert into private.exam_prep_content_runway_release_skills(release_id,skill_code,required_for_release)
select rel.id,s.skill_code,true from rel join skills s using(component_code)
on conflict(release_id,skill_code) do update set required_for_release=excluded.required_for_release;

-- Server-only operational runway report. No answer keys, learner records or private rubric bodies are returned.
create or replace function public.get_exam_prep_content_runway_v1(p_active_week_no smallint default 1)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_program bigint; v_releases jsonb; v_components jsonb; v_global_hard boolean; v_global_target boolean;
begin
  if p_active_week_no is null or p_active_week_no<1 then raise exception 'exam_prep_bad_active_week'; end if;
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  if v_program is null then raise exception 'exam_prep_program_version_missing'; end if;

  with rs as (
    select r.id,r.release_key,r.component_code,r.active_week_from,r.active_week_through,
      count(s.skill_code) filter(where s.required_for_release) as required_skills,
      count(s.skill_code) filter(where s.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,r.component_code,s.skill_code)) as ready_skills
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills s on s.release_id=r.id
    where r.program_version_id=v_program and r.schedule_status='active'
    group by r.id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'release_key',release_key,'component_code',component_code,'active_week_from',active_week_from,'active_week_through',active_week_through,
    'required_skills',required_skills,'ready_skills',ready_skills,'release_ready',(required_skills>0 and ready_skills=required_skills)
  ) order by active_week_from,component_code),'[]'::jsonb) into v_releases from rs;

  with comps(component_code) as (values('P1'::text),('P5'::text)), x as (
    select c.component_code,
      coalesce(max(r.active_week_through) filter(where z.release_ready and r.active_week_from<=p_active_week_no),p_active_week_no-1) as ready_through_aw
    from comps c
    left join private.exam_prep_content_runway_releases r on r.program_version_id=v_program and r.component_code=c.component_code and r.schedule_status='active'
    left join lateral (
      select count(*) filter(where s.required_for_release)>0
        and count(*) filter(where s.required_for_release)=count(*) filter(where s.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,r.component_code,s.skill_code)) as release_ready
      from private.exam_prep_content_runway_release_skills s where s.release_id=r.id
    ) z on true
    group by c.component_code
  )
  select jsonb_object_agg(component_code,jsonb_build_object(
    'ready_through_aw',ready_through_aw,
    'ahead_weeks',greatest(0,ready_through_aw-p_active_week_no+1),
    'hard_floor_2w_green',greatest(0,ready_through_aw-p_active_week_no+1)>=2,
    'target_4w_green',greatest(0,ready_through_aw-p_active_week_no+1)>=4
  )) into v_components from x;

  v_global_hard:=coalesce((v_components#>>'{P1,hard_floor_2w_green}')::boolean,false) and coalesce((v_components#>>'{P5,hard_floor_2w_green}')::boolean,false);
  v_global_target:=coalesce((v_components#>>'{P1,target_4w_green}')::boolean,false) and coalesce((v_components#>>'{P5,target_4w_green}')::boolean,false);

  return jsonb_build_object(
    'runway_version','annual_runway_v1','active_week_no',p_active_week_no,'hard_floor_weeks',2,'target_weeks',4,
    'components',v_components,'hard_floor_green',v_global_hard,'target_4w_green',v_global_target,'releases',v_releases
  );
end;
$$;
revoke all on function public.get_exam_prep_content_runway_v1(smallint) from public,anon,authenticated;
grant execute on function public.get_exam_prep_content_runway_v1(smallint) to service_role;

-- Retroactive proof for already-published governed content and fail-closed feature state.
do $$
declare v_cv record; v_skill text; v_floor jsonb; v_bad int;
begin
  for v_cv in select id,content_version from private.exam_prep_content_versions where status='published' loop
    for v_skill in select distinct primary_skill_code from private.exam_prep_question_content_meta where content_version_id=v_cv.id and lifecycle_state in ('published','reserve') loop
      v_floor:=private.exam_prep_content_skill_floor_in_version_v1(v_cv.id,v_skill);
      if coalesce((v_floor->>'ready')::boolean,false) is not true then
        raise exception 'P1-02 existing published content fails floor: version=% skill=% detail=%',v_cv.content_version,v_skill,v_floor::text;
      end if;
    end loop;
  end loop;

  select count(*) into v_bad from private.exam_prep_feature_config
  where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then raise exception 'P1-02 contract must remain fail-closed'; end if;
end;
$$;

commit;
