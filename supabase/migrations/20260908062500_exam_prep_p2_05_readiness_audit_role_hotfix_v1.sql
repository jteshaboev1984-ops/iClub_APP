-- P2-05 Mentor Verified Readiness audit-role hotfix v1.
-- A qualified second checker may be either an academic moderator or a lead mentor.
-- Record the actual qualified role instead of labelling every sign-off as academic_moderator.

begin;

create or replace function private.exam_prep_materialize_readiness_signoff_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_r private.exam_prep_mentor_reviews%rowtype;
  v_q private.exam_prep_mentor_queue_items%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_state jsonb;
  v_expected text;
  v_assignment bigint;
  v_mentor uuid;
  v_signoff uuid;
  v_actor_role text;
begin
  select * into v_r from private.exam_prep_mentor_reviews where id=new.review_id;
  if v_r.id is null then return new; end if;
  select * into v_q from private.exam_prep_mentor_queue_items where id=v_r.queue_item_id;
  if v_q.id is null or v_q.queue_type<>'readiness' then return new; end if;
  if v_r.decision_code<>'confirm' or new.outcome<>'confirmed' then return new; end if;

  if new.reviewer_user_id=v_r.mentor_user_id then raise exception 'exam_prep_second_check_must_be_independent'; end if;
  if private.exam_prep_has_staff_role_v1(new.reviewer_user_id,array['academic_moderator']) then
    v_actor_role:='academic_moderator';
  elsif private.exam_prep_has_staff_role_v1(new.reviewer_user_id,array['lead_mentor']) then
    v_actor_role:='lead_mentor';
  else
    raise exception 'exam_prep_moderator_role_required' using errcode='42501';
  end if;

  select assignment_id,mentor_user_id into v_assignment,v_mentor
  from private.exam_prep_active_mentor_assignment_v1(v_r.learner_user_id,v_r.component_code);
  if v_assignment is null or v_assignment<>v_r.assignment_id or v_mentor<>v_r.mentor_user_id then
    raise exception 'exam_prep_readiness_assignment_not_active' using errcode='42501';
  end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_r.learner_user_id;
  if v_profile.program_version_id is null then raise exception 'exam_prep_profile_required'; end if;

  v_state:=private.exam_prep_readiness_review_snapshot_v1(v_r.learner_user_id,v_profile.program_version_id,v_r.component_code);
  v_expected:=nullif(v_r.review_scope->>'readiness_fingerprint','');
  if not coalesce((v_state->>'ready')::boolean,false) or v_expected is null then raise exception 'exam_prep_readiness_second_check_stale'; end if;
  if v_expected<>(v_state->>'fingerprint') then raise exception 'exam_prep_readiness_evidence_changed'; end if;

  insert into private.exam_prep_readiness_signoffs(
    learner_user_id,program_version_id,component_code,assignment_id,mentor_user_id,moderator_user_id,
    review_id,second_check_id,readiness_fingerprint,app_readiness_snapshot
  ) values(
    v_r.learner_user_id,v_profile.program_version_id,v_r.component_code,v_r.assignment_id,
    v_r.mentor_user_id,new.reviewer_user_id,v_r.id,new.id,v_expected,v_state->'snapshot'
  ) on conflict(learner_user_id,program_version_id,component_code,readiness_fingerprint) do nothing
  returning id into v_signoff;

  if v_signoff is null then
    select s.id into v_signoff from private.exam_prep_readiness_signoffs s
    where s.learner_user_id=v_r.learner_user_id and s.program_version_id=v_profile.program_version_id
      and s.component_code=v_r.component_code and s.readiness_fingerprint=v_expected;
  end if;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,
    target_user_id,component_code,before_state,after_state,metadata
  ) values(
    'math_as_p1_p5',new.reviewer_user_id,v_actor_role,'mentor_verified_readiness_confirmed',
    'private.exam_prep_readiness_signoffs',v_signoff::text,v_r.learner_user_id,v_r.component_code,
    jsonb_build_object('review_id',v_r.id,'mentor_decision',v_r.decision_code),
    jsonb_build_object('mentor_verified_readiness',true,'readiness_fingerprint',v_expected),
    jsonb_build_object('assignment_id',v_r.assignment_id,'second_check_id',new.id)
  );

  return new;
end;
$$;

revoke all on function private.exam_prep_materialize_readiness_signoff_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_materialize_readiness_signoff_v1() to service_role;

do $$ declare v_def text; begin
  select pg_get_functiondef('private.exam_prep_materialize_readiness_signoff_v1()'::regprocedure) into v_def;
  if position('v_actor_role' in v_def)=0 or position('lead_mentor' in v_def)=0 or position('academic_moderator' in v_def)=0 then
    raise exception 'P2-05 readiness audit-role hotfix missing';
  end if;
end $$;

commit;
