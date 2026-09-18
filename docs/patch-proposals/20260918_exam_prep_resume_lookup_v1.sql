-- REVIEW PROPOSAL ONLY. Not in supabase/migrations; do not apply to production.
-- Validated against read-only schema inventory on 2026-09-18.
-- This is a discovery endpoint, NOT a session starter or academic state mutation.
-- A separate isolated DB test and owner sign-off are mandatory before promotion.

create or replace function public.get_exam_prep_active_plan_session_safe_v1(
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_session_id uuid;
  v_session private.exam_prep_sessions%rowtype;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_count integer;
  v_answered integer;
  v_first_unanswered smallint;
  v_plan_status text;
  v_plan_week smallint;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1', 'P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select p.program_version_id into v_program
  from private.exam_prep_exam_profiles p
  where p.user_id = v_uid;
  if v_program is null then
    raise exception 'exam_prep_profile_required';
  end if;

  -- Search ALL plan versions and weeks; the former plan may be superseded.
  -- Do not reveal diagnostic, timed, full-paper, other-user or other-program sessions.
  select count(*)::integer, min(s.id)
    into v_count, v_session_id
  from private.exam_prep_sessions s
  join private.exam_prep_session_authorizations a
    on a.id = s.authorization_id
   and a.user_id = v_uid
   and a.component_code = p_component_code
   and a.academic_credit is true
   and a.plan_id is not null
   and a.consumed_session_id = s.id
  where s.user_id = v_uid
    and s.component_code = p_component_code
    and s.program_version_id = v_program
    and s.status = 'active'
    and s.session_type in ('learning', 'mixed', 'retest');

  if v_count = 0 then
    return jsonb_build_object(
      'contract_version', 'active_plan_session_v1',
      'component_code', p_component_code,
      'status', 'none',
      'active_session_count', 0
    );
  end if;
  if v_count <> 1 then
    -- Do not silently pick one of several active sessions or start a replacement.
    return jsonb_build_object(
      'contract_version', 'active_plan_session_v1',
      'component_code', p_component_code,
      'status', 'multiple_active',
      'active_session_count', v_count
    );
  end if;

  select * into strict v_session
  from private.exam_prep_sessions s
  where s.id = v_session_id and s.user_id = v_uid
    and s.component_code = p_component_code
    and s.program_version_id = v_program and s.status = 'active';

  select * into strict v_auth
  from private.exam_prep_session_authorizations a
  where a.id = v_session.authorization_id and a.user_id = v_uid
    and a.component_code = p_component_code and a.academic_credit is true
    and a.status = 'consumed' and a.consumed_session_id = v_session.id
    and a.plan_id is not null;

  select count(r.id)::integer,
         min(si.item_order) filter (where r.id is null)
    into v_answered, v_first_unanswered
  from private.exam_prep_session_items si
  left join private.exam_prep_responses r
    on r.session_id = si.session_id
   and r.item_order = si.item_order
   and r.user_id = v_uid
  where si.session_id = v_session.id;

  select p.status, p.active_week_no into v_plan_status, v_plan_week
  from private.exam_prep_weekly_plans p
  where p.id = v_auth.plan_id and p.user_id = v_uid
    and p.program_version_id = v_program
    and p.component_code = p_component_code;

  -- No answer text, question IDs, protected content, scores or peer data in discovery.
  -- Rehydrate questions only through existing authenticated get_session RPC.
  return jsonb_build_object(
    'contract_version', 'active_plan_session_v1',
    'component_code', p_component_code,
    'status', case when v_first_unanswered is null
                   then 'ready_to_finalize' else 'resume' end,
    'active_session_count', 1,
    'session_id', v_session.id,
    'session_type', v_session.session_type,
    'answered_items', v_answered,
    'total_items', v_session.total_items,
    'first_unanswered_item_order', v_first_unanswered,
    'source_plan_id', v_auth.plan_id,
    'source_plan_priority_order', v_auth.plan_priority_order,
    'source_plan_status', coalesce(v_plan_status, 'unavailable'),
    'source_plan_week', v_plan_week,
    'resume_independent_of_current_plan', true
  );
end;
$function$;

revoke all on function public.get_exam_prep_active_plan_session_safe_v1(text) from public;
revoke all on function public.get_exam_prep_active_plan_session_safe_v1(text) from anon;
grant execute on function public.get_exam_prep_active_plan_session_safe_v1(text) to authenticated;
