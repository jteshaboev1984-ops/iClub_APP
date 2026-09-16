begin;

-- Freeze the exact learner-safe understanding-check versions at session-item creation.
-- This prevents an already-started learning session from changing underneath the learner
-- if a companion check is later retired/re-versioned. Existing response/history rows are
-- not rewritten; active legacy sessions are pinned to the currently published versions.

alter table private.exam_prep_session_items
  add column if not exists understanding_check_versions jsonb;

alter table private.exam_prep_session_items
  drop constraint if exists exam_prep_session_items_understanding_check_versions_shape;
alter table private.exam_prep_session_items
  add constraint exam_prep_session_items_understanding_check_versions_shape
  check (
    understanding_check_versions is null
    or jsonb_typeof(understanding_check_versions)='array'
  );

create or replace function private.exam_prep_written_understanding_version_snapshot_v1(
  p_written_task_id bigint
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object('check_order',c.check_order,'check_version',c.check_version)
      order by c.check_order
    ),
    '[]'::jsonb
  )
  from private.exam_prep_written_understanding_checks c
  where c.written_task_id=p_written_task_id
    and c.lifecycle_state='published'
    and c.qa_math_status='pass'
    and c.qa_language_status='pass'
    and c.qa_technical_status='pass';
$$;
revoke all on function private.exam_prep_written_understanding_version_snapshot_v1(bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_written_understanding_version_snapshot_v1(bigint) to service_role;

create or replace function private.exam_prep_pin_written_understanding_snapshot_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if new.item_kind='written' and new.written_task_id is not null and new.understanding_check_versions is null then
    new.understanding_check_versions:=private.exam_prep_written_understanding_version_snapshot_v1(new.written_task_id);
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_pin_written_understanding_snapshot_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_pin_written_understanding_snapshot_v1() to service_role;

drop trigger if exists exam_prep_pin_written_understanding_snapshot_v1 on private.exam_prep_session_items;
create trigger exam_prep_pin_written_understanding_snapshot_v1
before insert on private.exam_prep_session_items
for each row execute function private.exam_prep_pin_written_understanding_snapshot_v1();

-- Only active sessions are backfilled. This preserves the exact currently observable
-- behavior for learners who may resume an already-started session, while old finalized
-- history remains untouched.
update private.exam_prep_session_items si
set understanding_check_versions=private.exam_prep_written_understanding_version_snapshot_v1(si.written_task_id)
from private.exam_prep_sessions s
where s.id=si.session_id
  and s.status='active'
  and si.item_kind='written'
  and si.written_task_id is not null
  and si.understanding_check_versions is null;

create or replace function private.exam_prep_written_understanding_payload_snapshot_v1(
  p_written_task_id bigint,
  p_language text,
  p_snapshot jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_lang text;
  v_rows jsonb;
  v_expected int;
  v_resolved int;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_written_task_id is null then return '[]'::jsonb; end if;

  -- Null means a pre-snapshot session: preserve the previous current-content behavior.
  if p_snapshot is null then
    return private.exam_prep_written_understanding_payload_v1(p_written_task_id,v_lang);
  end if;
  if jsonb_typeof(p_snapshot)<>'array' then raise exception 'exam_prep_written_understanding_snapshot_invalid'; end if;
  v_expected:=jsonb_array_length(p_snapshot);
  if v_expected=0 then return '[]'::jsonb; end if;

  select count(*)::int,
         coalesce(jsonb_agg(jsonb_build_object(
           'check_order',c.check_order,
           'check_version',c.check_version,
           'check_kind',c.check_kind,
           'prompt',case v_lang when 'ru' then c.prompt_ru when 'uz' then c.prompt_uz else c.prompt_en end,
           'options',case v_lang when 'ru' then c.options_ru when 'uz' then c.options_uz else c.options_en end
         ) order by s.ord),'[]'::jsonb)
    into v_resolved,v_rows
  from jsonb_array_elements(p_snapshot) with ordinality s(value,ord)
  join private.exam_prep_written_understanding_checks c
    on c.written_task_id=p_written_task_id
   and c.check_order=nullif(s.value->>'check_order','')::int
   and c.check_version=nullif(btrim(coalesce(s.value->>'check_version','')),'')
   and c.lifecycle_state in ('published','retired')
   and c.qa_math_status='pass'
   and c.qa_language_status='pass'
   and c.qa_technical_status='pass';

  if v_resolved<>v_expected then
    raise exception 'exam_prep_written_understanding_snapshot_unresolvable expected %, resolved %',v_expected,v_resolved;
  end if;
  if v_rows::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'exam_prep_written_understanding_snapshot_private_metadata';
  end if;
  return v_rows;
end;
$$;
revoke all on function private.exam_prep_written_understanding_payload_snapshot_v1(bigint,text,jsonb) from public,anon,authenticated;
grant execute on function private.exam_prep_written_understanding_payload_snapshot_v1(bigint,text,jsonb) to service_role;

create or replace function public.get_exam_prep_session_safe_v1(p_session_id uuid, p_language text default 'en')
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_lang text;
  v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  select coalesce(jsonb_agg(item_payload order by item_order),'[]'::jsonb) into v_items
  from (
    select si.item_order,
      jsonb_strip_nulls(jsonb_build_object(
        'item_order',si.item_order,
        'item_kind',si.item_kind,
        'primary_skill_code',si.primary_skill_code,
        'reserve_role',si.reserve_role,
        'answered',(r.id is not null),
        'response_id',r.id,
        'selected_answer',r.selected_answer,
        'is_correct',case
          when r.id is not null and private.exam_prep_active_feedback_allowed_v1(v_s.id,si.item_order) then r.is_correct
          else null
        end,
        'feedback_deferred',case
          when r.id is not null and r.response_kind='machine' and not private.exam_prep_active_feedback_allowed_v1(v_s.id,si.item_order) then true
          else null
        end,
        'learner_artifact',case when si.item_kind='written' then r.learner_artifact else null end,
        'qtype',case when si.item_kind='question' then q.qtype else null end,
        'difficulty',case when si.item_kind='question' then q.difficulty else null end,
        'time_limit_sec',case when si.item_kind='question' then q.time_limit_sec else null end,
        'text',case when si.item_kind='question' then case v_lang when 'ru' then q.question_text_ru when 'uz' then q.question_text_uz else q.question_text_en end else null end,
        'options',case when si.item_kind='question' and q.qtype='mcq' then coalesce(nullif(case v_lang when 'ru' then q.options_text_ru when 'uz' then q.options_text_uz else q.options_text_en end,''),'[]')::jsonb else null end,
        'written_prompt',case when si.item_kind='written' then case v_lang when 'ru' then wt.prompt_ru when 'uz' then wt.prompt_uz else wt.prompt_en end else null end,
        'written_max_marks',case when si.item_kind='written' then nullif(wt.rubric_json->>'max_marks','')::int else null end,
        'understanding_checks',case when si.item_kind='written' then private.exam_prep_written_understanding_payload_snapshot_v1(si.written_task_id,v_lang,si.understanding_check_versions) else null end
      )) as item_payload
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    left join private.exam_prep_written_tasks wt on wt.id=si.written_task_id
    left join private.exam_prep_responses r on r.session_id=si.session_id and r.item_order=si.item_order
    where si.session_id=v_s.id
  ) x;

  return jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'component_code',v_s.component_code,
    'session_type',v_s.session_type,
    'assessment_version',v_s.assessment_version,
    'total_items',v_s.total_items,
    'started_at',v_s.started_at,
    'finalized_at',v_s.finalized_at,
    'items',v_items
  );
end; $$;
revoke execute on function public.get_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

-- Migration acceptance: active written items are pinned, future inserts have a trigger,
-- and pinned learner payloads expose no private evaluation metadata.
do $$
declare
  v_task bigint;
  v_snapshot jsonb;
  v_payload jsonb;
  v_bad int;
begin
  select id into v_task
  from private.exam_prep_written_tasks
  where task_key='P1CIR01-W01' and component_code='P1' and lifecycle_state='published'
  order by id limit 1;
  if v_task is null then raise exception 'written-session-snapshot: reference task missing'; end if;

  v_snapshot:=private.exam_prep_written_understanding_version_snapshot_v1(v_task);
  if jsonb_array_length(v_snapshot)<>3 then raise exception 'written-session-snapshot: reference snapshot count mismatch'; end if;
  v_payload:=private.exam_prep_written_understanding_payload_snapshot_v1(v_task,'en',v_snapshot);
  if jsonb_array_length(v_payload)<>3 then raise exception 'written-session-snapshot: pinned payload count mismatch'; end if;
  if v_payload::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'written-session-snapshot: private metadata leaked';
  end if;

  select count(*)::int into v_bad
  from private.exam_prep_session_items si
  join private.exam_prep_sessions s on s.id=si.session_id
  where s.status='active'
    and si.item_kind='written'
    and si.written_task_id is not null
    and si.understanding_check_versions is null;
  if v_bad<>0 then raise exception 'written-session-snapshot: active written items left unpinned: %',v_bad; end if;
end $$;

commit;
