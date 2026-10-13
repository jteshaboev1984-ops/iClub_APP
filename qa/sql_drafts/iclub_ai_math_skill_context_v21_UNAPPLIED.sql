-- iClub AI Layer v2.1 — SQL DRAFT. Never import into supabase/migrations.
-- P2/P4: read-only *proof* that a mathematical skill/source belongs to the
-- logged-in learner's FINALIZED P1/P5 session. Does not return textbook content.
-- Does not touch existing exam-prep-ai functions, progress or learner status.
-- Service-role ONLY. The caller MUST derive p_user_id from a verified JWT.
-- Invoke again directly before model call and before delivery.
--
-- THIS DRAFT FAILS ON PRODUCTION DATABASES EVEN IF RUN MANUALLY.
DO $iclub_ai_v21_math_scratch_only$
BEGIN
  IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$' THEN
    RAISE EXCEPTION 'BLOCKED: iClub AI v2.1 Math contract may only run in scratch DB';
  END IF;
  IF inet_server_addr() IS NOT NULL
     AND (inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet) AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
    RAISE EXCEPTION 'BLOCKED: iClub AI v2.1 Math contract requires local PostgreSQL';
  END IF;
END
$iclub_ai_v21_math_scratch_only$;

create or replace function public.get_iclub_ai_math_skill_context_service_v2(
  p_user_id uuid,
  p_session_id uuid,
  p_skill_code text,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_component text;
  v_source_key text;
  v_source_version text;
  v_source_hash text;
  v_tutor_version text;
  v_tutor_hash text;
begin
  -- Fail CLOSED. All identifiers are untrusted until checked by this function.
  if p_user_id is null or p_session_id is null
    or p_locale is null or p_locale not in ('ru','uz','en')
    or p_skill_code is null
    or p_skill_code !~ '^P[15]-[A-Z0-9]+-[0-9]{2}$' then
    return jsonb_build_object('allowed',false,'reason','invalid_context');
  end if;

  -- Existing global-ai kill switch is the hard stop; the existing working
  -- Mathematics Exam Prep is NOT gated by these new flags.
  if not exists(
    select 1 from private.iclub_global_ai_runtime_config r
    where r.id=1
      and r.kill_switch=false
      and r.gateway_enabled=true
  ) then
    return jsonb_build_object('allowed',false,'reason','gateway_disabled');
  end if;

  -- Do not leak whether a session ID belongs to someone else.
  select s.component_code
    into v_component
  from private.exam_prep_sessions s
  where s.id=p_session_id and s.user_id=p_user_id
    and s.status='finalized' and s.finalized_at is not null
    and s.component_code in ('P1','P5')
  limit 1;

  if v_component is null then
    return jsonb_build_object('allowed',false,'reason','context_not_authorized');
  end if;
  if p_skill_code not like v_component||'-%' then
    return jsonb_build_object('allowed',false,'reason','skill_component_mismatch');
  end if;

  -- Preserve the deployed active-assessment guard (Tours + Math).
  if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
    return jsonb_build_object('allowed',false,'reason','active_assessment');
  end if;

  -- A client-selected skill is insufficient. It must be in an actual session
  -- item and have app-VERIFIED, owner-bound evidence in that same session.
  if not exists(
    select 1 from private.exam_prep_session_items i
    where i.session_id=p_session_id
      and i.primary_skill_code=p_skill_code
  ) or not exists(
    select 1 from private.exam_prep_evidence_events e
    where e.session_id=p_session_id
      and e.user_id=p_user_id
      and e.component_code=v_component
      and e.skill_code=p_skill_code
      and e.verification_status='app_verified'
  ) then
    return jsonb_build_object('allowed',false,'reason','skill_evidence_unverified');
  end if;

  -- Pre-existing approved Tutor variant. Do not use retired versions.
  select t.source_card_key,t.content_version,t.content_hash
    into v_source_key,v_tutor_version,v_tutor_hash
  from private.exam_prep_ai_tutor_cards t
  where t.component_code=v_component
    and t.skill_code=p_skill_code
    and t.locale=p_locale
    and t.content_version='tutor_v3_learner_first'
    and t.approval_status='approved'
    and t.is_runtime_allowed=true
    and t.source_card_key is not null
    and length(t.content_hash)=32
  limit 1;

  if v_source_key is null then
    return jsonb_build_object('allowed',false,'reason','tutor_source_not_ready');
  end if;

  -- Always check the original, rights-cleared source row independently.
  select c.source_version,c.content_hash
    into v_source_version,v_source_hash
  from private.exam_prep_ai_source_cards c
  where c.source_card_key=v_source_key
    and c.component_code=v_component
    and c.skill_code=p_skill_code
    and c.locale=p_locale
    and c.card_type='theory'
    and c.approval_status='approved'
    and c.rights_status='original_iclub'
    and c.is_runtime_allowed=true
    and length(c.content_hash)=64
  limit 1;

  if v_source_version is null then
    return jsonb_build_object('allowed',false,'reason','source_not_approved');
  end if;

  -- This is only source admission metadata for the SERVER.
  -- It cannot authorize a tariff debit without release gate + entitlement.
  return jsonb_build_object(
    'allowed',true,
    'subject','mathematics',
    'scope','exam_prep',
    'component',v_component,
    'skill_code',p_skill_code,
    'locale',p_locale,
    'source_card_key',v_source_key,
    'source_version',v_source_version,
    'source_hash',v_source_hash,
    'tutor_content_version',v_tutor_version,
    'tutor_content_hash',v_tutor_hash,
    'academic_state_changed',false
  );
end;
$$;

revoke all on function public.get_iclub_ai_math_skill_context_service_v2(uuid,uuid,text,text)
from public,anon,authenticated;
grant execute on function public.get_iclub_ai_math_skill_context_service_v2(uuid,uuid,text,text)
to service_role;

-- NO-GO: The surrounding Edge MUST validate a JWT; perform global guard,
-- scoped release/cohort/tariff checks; call this again before provider/delivery;
-- verify the live tutor/source hashes; never trust client status/subject.
-- Zero production DDL/DML, zero API route or deployment as part of this draft.
