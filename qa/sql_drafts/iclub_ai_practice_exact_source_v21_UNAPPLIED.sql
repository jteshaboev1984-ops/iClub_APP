-- iClub AI Layer v2.1 — Practice Economics/Chemistry exact-question admission.
-- QA / UNAPPLIED, NOT in supabase/migrations. NO production execution.
-- Never accept the browser's subject/topic/completion/answer-key as authority.
-- This proof returns metadata ONLY, and does not turn on Global AI.
DO $iclub_ai_v21_practice_scratch_only$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$' THEN
   RAISE EXCEPTION 'BLOCKED: Practice AI v2.1 SQL is SCRATCH-ONLY';
 END IF;
 IF inet_server_addr() IS NOT NULL AND
  (inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet) AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
   RAISE EXCEPTION 'BLOCKED: only localhost PostgreSQL';
 END IF;
END
$iclub_ai_v21_practice_scratch_only$;

create or replace function public.get_iclub_ai_practice_question_source_service_v2(
 p_user_id uuid,
 p_session_id bigint,
 p_question_id bigint,
 p_locale text
)
returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
 v_subject_key text;
 v_source_key text;
 v_source_hash text;
 v_source_version text;
 v_source_candidates integer;
begin
 if p_user_id is null or p_session_id is null or p_session_id<=0
    or p_question_id is null or p_question_id<=0
    or p_locale is null or p_locale not in ('ru','uz','en') then
  return jsonb_build_object('allowed',false,'reason','invalid_context');
 end if;

 -- Independent from original Practice AI policy; the NEW unified AI
 -- will also require its own topic/feature/locale release and cohort gate.
 if not exists (
  select 1 from private.iclub_global_ai_runtime_config cfg
  where cfg.id=1 and cfg.kill_switch=false and cfg.gateway_enabled=true
 ) then
  return jsonb_build_object('allowed',false,'reason','gateway_disabled');
 end if;
 if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
  return jsonb_build_object('allowed',false,'reason','active_assessment');
 end if;

 -- The subject is derived from existing, owner-bound completed Practice.
 select subj.subject_key into v_subject_key
 from public.practice_sessions_v4 s
 join public.subjects subj on subj.id=s.subject_id
 where s.id=p_session_id
   and s.user_id=p_user_id
   and s.status='finalized'
   and s.finalized_at is not null
   and subj.is_active=true
   and subj.subject_key in ('economics','chemistry')
   and p_question_id=any(s.question_ids)
   and exists (
     select 1 from public.practice_session_answers_v4 a
     where a.session_id=s.id and a.question_id=p_question_id
   )
 limit 1;
 if v_subject_key is null then
  -- Do not distinguish foreign learner from unfinished/missing attempt.
  return jsonb_build_object('allowed',false,'reason','practice_context_not_authorized');
 end if;

 -- No generic topic fallback for a specific question. Most Economics
 -- approved cards have NULL question_id. They do NOT satisfy this proof.
 -- Multiple current approved versions are ALSO unsafe: fail closed rather than
 -- silently choose the latest explanation for a real learner.
 select count(*) into v_source_candidates
 from private.practice_ai_source_cards c
 where c.subject_key=v_subject_key
   and c.question_id=p_question_id
   and c.locale=p_locale
   and c.card_type='answer_explanation'
   and c.approval_status='approved'
   and c.rights_status='original_iclub'
   and c.is_runtime_allowed=true
   and length(c.content_hash)=64;
 if v_source_candidates<>1 then
  return jsonb_build_object('allowed',false,'reason','exact_source_not_ready');
 end if;

 select c.source_card_key,c.content_hash,c.source_version
 into v_source_key,v_source_hash,v_source_version
 from private.practice_ai_source_cards c
 where c.subject_key=v_subject_key
   and c.question_id=p_question_id
   and c.locale=p_locale
   and c.card_type='answer_explanation'
   and c.approval_status='approved'
   and c.rights_status='original_iclub'
   and c.is_runtime_allowed=true
   and length(c.content_hash)=64
 order by c.approved_at desc nulls last,c.source_card_key
 limit 1;
 if v_source_key is null then
  return jsonb_build_object('allowed',false,'reason','exact_source_not_ready');
 end if;

 -- This metadata is for the authenticated server ONLY. A separate
 -- release/QA/cohort/access check is required before ANY model/billing.
 return jsonb_build_object(
  'allowed',true,
  'subject',v_subject_key,
  'scope','practice',
  'question_id',p_question_id,
  'locale',p_locale,
  'source_card_key',v_source_key,
  'source_hash',v_source_hash,
  'source_version',v_source_version,
  'academic_state_changed',false
 );
end;
$$;

revoke all on function public.get_iclub_ai_practice_question_source_service_v2(uuid,bigint,bigint,text)
from public,anon,authenticated;
grant execute on function public.get_iclub_ai_practice_question_source_service_v2(uuid,bigint,bigint,text)
to service_role;

-- NOT a general lesson route. No automatic Biology/Informatics/SAT enablement.
-- Generic question_id=NULL sources and result_context are governed separately.
-- Not callable from browser; Edge user_id MUST come from verified JWT.
