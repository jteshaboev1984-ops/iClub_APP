-- Reviewed RU/UZ written learning criteria without rewriting immutable source rubrics.
-- Safe for active users: ADD ONLY; both P1/P5 remain OFF until reviewed coverage complete.
-- Approved source English and existing response/score/evidence rows are never modified.
begin;
set local lock_timeout='4s';
set local statement_timeout='60s';

create table if not exists private.exam_prep_written_criteria_locale_v1 (
  written_task_id bigint not null references private.exam_prep_written_tasks(id) on delete restrict,
  task_version text not null,
  criterion_id text not null check (length(btrim(criterion_id)) between 1 and 120),
  language text not null check (language in ('ru','uz')),
  source_rule_md5 text not null check (source_rule_md5 ~ '^[a-f0-9]{32}$'),
  translated_rule text not null check (length(btrim(translated_rule)) between 2 and 1000),
  review_state text not null default 'draft' check (review_state in ('draft','approved')),
  academic_review_ref text,
  language_review_ref text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (written_task_id,task_version,criterion_id,language),
  constraint exam_prep_written_criteria_locale_review_gate_v1
    check (review_state<>'approved' or
      (nullif(btrim(academic_review_ref),'') is not null
       and nullif(btrim(language_review_ref),'') is not null
       and reviewed_at is not null))
);
alter table private.exam_prep_written_criteria_locale_v1 enable row level security;
revoke all on private.exam_prep_written_criteria_locale_v1 from public,anon,authenticated;
grant select,insert,update on private.exam_prep_written_criteria_locale_v1 to service_role;

-- An approved translation may never be silently rewritten or deleted.
-- Corrections require a new task version and a new independent approval.
create or replace function private.exam_prep_lock_approved_written_locale_v1()
returns trigger language plpgsql security definer set search_path='' as $fn$
begin
  if old.review_state='approved' then
    raise exception 'exam_prep_approved_translation_immutable' using errcode='42501';
  end if;
  if tg_op='DELETE' then return old;end if;
  return new;
end $fn$;
revoke all on function private.exam_prep_lock_approved_written_locale_v1()
  from public,anon,authenticated;
drop trigger if exists exam_prep_lock_approved_written_locale_v1
 on private.exam_prep_written_criteria_locale_v1;
create trigger exam_prep_lock_approved_written_locale_v1
 before update or delete on private.exam_prep_written_criteria_locale_v1
 for each row execute function private.exam_prep_lock_approved_written_locale_v1();

-- Separate from legacy QA flags, whose existing 'pass' did not audit rubric locales.
-- Fail closed if ANY published, QA-passed task has a missing RU or UZ rule.
create or replace function private.exam_prep_require_written_locale_before_enable_v1()
returns trigger language plpgsql security definer set search_path='' as $fn$
begin
  if new.enabled is true then
    if not exists(
      select 1 from private.exam_prep_written_tasks w
      where w.component_code=new.component_code and w.lifecycle_state='published'
        and w.qa_math_status='pass' and w.qa_language_status='pass'
        and w.qa_technical_status='pass'
    ) then
      raise exception 'exam_prep_written_no_eligible_tasks' using errcode='23514';
    end if;
    if exists(
      select 1
      from private.exam_prep_written_tasks wt
      cross join lateral jsonb_array_elements(
        coalesce(wt.rubric_json->'criteria','[]'::jsonb)
      ) c(value)
      left join private.exam_prep_written_criteria_locale_v1 ru
        on ru.written_task_id=wt.id and ru.task_version=wt.task_version
        and ru.criterion_id=c.value->>'id' and ru.language='ru'
        and ru.review_state='approved' and ru.source_rule_md5=md5(c.value->>'rule')
      left join private.exam_prep_written_criteria_locale_v1 uz
        on uz.written_task_id=wt.id and uz.task_version=wt.task_version
        and uz.criterion_id=c.value->>'id' and uz.language='uz'
        and uz.review_state='approved' and uz.source_rule_md5=md5(c.value->>'rule')
      where wt.component_code=new.component_code and wt.lifecycle_state='published'
        and wt.qa_math_status='pass' and wt.qa_language_status='pass'
        and wt.qa_technical_status='pass'
        and (
          (nullif(btrim(coalesce(c.value->>'rule_ru','')),'') is null
            and ru.translated_rule is null)
          or
          (nullif(btrim(coalesce(c.value->>'rule_uz','')),'') is null
            and uz.translated_rule is null)
        )
      limit 1
    ) then
      raise exception 'exam_prep_written_locale_approvals_incomplete'
        using errcode='23514';
    end if;
  end if;
  return new;
end $fn$;
revoke all on function private.exam_prep_require_written_locale_before_enable_v1()
 from public,anon,authenticated;
drop trigger if exists exam_prep_require_written_locale_before_enable_v1
 on private.exam_prep_written_learning_config_v1;
create trigger exam_prep_require_written_locale_before_enable_v1
 before insert or update of enabled
 on private.exam_prep_written_learning_config_v1
 for each row execute function private.exam_prep_require_written_locale_before_enable_v1();

-- Preserve original authenticated ownership, sequential-item and anti-leak checks.
create or replace function public.get_exam_prep_written_criteria_safe_v1(
  p_session_id uuid,p_item_order integer,p_language text default 'en'
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_wt private.exam_prep_written_tasks%rowtype;
  v_total integer;
  v_approved integer;
  v_rubric jsonb;
  v_requirements jsonb;
  v_lang text:=lower(coalesce(p_language,'en'));
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if v_lang not in ('ru','uz','en') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type<>'learning' or v_s.status<>'active'
     or not private.exam_prep_written_learning_can_use_v1(v_uid,p_session_id)
  then raise exception 'exam_prep_written_criteria_unavailable' using errcode='42501'; end if;
  select * into v_i from private.exam_prep_session_items
    where session_id=v_s.id and item_order=p_item_order and item_kind='written';
  if v_i.item_order is null then raise exception 'exam_prep_written_item_not_found' using errcode='P0002'; end if;
  -- Criteria belong to the current unfinished step only; do not expose future rubrics.
  if exists(
    select 1 from private.exam_prep_session_items si
    where si.session_id=p_session_id and si.item_order<p_item_order
      and not exists(select 1 from private.exam_prep_responses r
        where r.session_id=p_session_id and r.item_order=si.item_order)
      and not exists(select 1 from private.exam_prep_written_step_advances_v1 a
        where a.session_id=p_session_id and a.item_order=si.item_order)
  ) or exists(
    select 1 from private.exam_prep_responses r
    where r.session_id=p_session_id and r.item_order=p_item_order
  ) or exists(
    select 1 from private.exam_prep_written_step_advances_v1 a
    where a.session_id=p_session_id and a.item_order=p_item_order
  ) then raise exception 'exam_prep_written_criteria_not_current' using errcode='42501'; end if;
  select * into v_wt
  from private.exam_prep_written_tasks wt
  where wt.id=v_i.written_task_id
    and wt.component_code=v_s.component_code
    and v_i.item_version='written:'||wt.task_version
    and wt.lifecycle_state='published'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_wt.id is null then
    return jsonb_build_object('available',false,'item_order',p_item_order,
      'reason','source_not_available');
  end if;
  v_rubric:=private.exam_prep_localized_written_rubric_v1(v_wt.rubric_json,v_lang);
  if v_rubric is null or v_rubric->>'localization_status'='unavailable' then
    -- Never silently pretend the English mark scheme is translated.
    -- Only completely approved, source-version-pinned RU/UZ criteria may appear.
    if v_lang in ('ru','uz') then
      select count(*)::integer,count(loc.translated_rule)::integer,
        coalesce(jsonb_agg(loc.translated_rule order by c.ordinality)
          filter(where loc.translated_rule is not null),'[]'::jsonb)
      into v_total,v_approved,v_requirements
      from jsonb_array_elements(coalesce(v_wt.rubric_json->'criteria','[]'::jsonb))
        with ordinality c(value,ordinality)
      left join private.exam_prep_written_criteria_locale_v1 loc
        on loc.written_task_id=v_wt.id
        and loc.task_version=v_wt.task_version
        and loc.criterion_id=c.value->>'id'
        and loc.language=v_lang
        and loc.review_state='approved'
        and loc.source_rule_md5=md5(c.value->>'rule');
      if v_total>0 and v_total=v_approved then
        return jsonb_build_object('available',true,'item_order',p_item_order,
          'requirements',v_requirements,'source_language',v_lang);
      end if;
      return jsonb_build_object('available',false,'item_order',p_item_order,
        'reason','localization_pending');
    end if;
    return jsonb_build_object('available',false,'item_order',p_item_order,
      'reason','source_not_available');
  end if;
  select coalesce(jsonb_agg(btrim(c.value->>'rule') order by c.ordinality),'[]'::jsonb)
    into v_requirements
  from jsonb_array_elements(coalesce(v_rubric->'criteria','[]'::jsonb))
    with ordinality c(value,ordinality)
  where nullif(btrim(coalesce(c.value->>'rule','')),'') is not null;
  return jsonb_build_object('available',jsonb_array_length(v_requirements)>0,
    'item_order',p_item_order,'requirements',v_requirements);
end $fn$;
revoke all on function public.get_exam_prep_written_criteria_safe_v1(uuid,integer,text)
  from public,anon;
grant execute on function public.get_exam_prep_written_criteria_safe_v1(uuid,integer,text)
  to authenticated,service_role;


comment on table private.exam_prep_written_criteria_locale_v1 is
  'Private QA-reviewed per-task/version/criterion RU/UZ rubric text. Never changes submitted answers, marks, English source or historical sessions.';
commit;
