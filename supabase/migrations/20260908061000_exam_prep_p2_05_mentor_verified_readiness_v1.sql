-- P2-05 Mentor Verified Readiness v1.
-- Adds an optional, assignment-scoped human confirmation above deterministic App Readiness.
-- Core/AI progression remains independent of Mentor Care. No raw responses, evidence, mastery or legacy rows are rewritten.
-- Controlled-beta READY sign-offs require an independent second check and are bound to the exact current readiness evidence fingerprint.

begin;

create table if not exists private.exam_prep_readiness_signoffs (
  id uuid primary key default gen_random_uuid(),
  learner_user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  assignment_id bigint not null references private.exam_prep_mentor_assignments(id) on delete restrict,
  mentor_user_id uuid not null references public.users(id) on delete restrict,
  moderator_user_id uuid not null references public.users(id) on delete restrict,
  review_id uuid not null unique references private.exam_prep_mentor_reviews(id) on delete restrict,
  second_check_id uuid not null unique references private.exam_prep_mentor_second_checks(id) on delete restrict,
  readiness_fingerprint text not null check(char_length(readiness_fingerprint)=32),
  app_readiness_snapshot jsonb not null,
  created_at timestamptz not null default now(),
  unique(learner_user_id,program_version_id,component_code,readiness_fingerprint),
  check(mentor_user_id<>moderator_user_id)
);

create index if not exists exam_prep_readiness_signoffs_lookup_idx
  on private.exam_prep_readiness_signoffs(learner_user_id,program_version_id,component_code,created_at desc);

alter table private.exam_prep_readiness_signoffs enable row level security;
revoke all on private.exam_prep_readiness_signoffs from public,anon,authenticated;
grant all on private.exam_prep_readiness_signoffs to service_role;

drop trigger if exists exam_prep_readiness_signoffs_immutable_v1 on private.exam_prep_readiness_signoffs;
create trigger exam_prep_readiness_signoffs_immutable_v1
before update or delete on private.exam_prep_readiness_signoffs
for each row execute function private.exam_prep_block_immutable_mutation_v1();

create or replace function private.exam_prep_readiness_review_snapshot_v1(
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
  v_ready jsonb;
  v_snapshot jsonb;
  v_fingerprint text;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(p_user_id,p_program_version_id,p_component_code);
  v_snapshot:=jsonb_build_object(
    'program_version_id',p_program_version_id,
    'component_code',p_component_code,
    'ready',coalesce((v_ready->>'ready')::boolean,false),
    'rule_version',v_ready->>'rule_version',
    'exam_series',v_ready->>'exam_series',
    'target_grade',v_ready->>'target_grade',
    'threshold_version',v_ready->>'threshold_version',
    'min_in_time_score_pct',v_ready->'min_in_time_score_pct',
    'max_unattempted_share',v_ready->'max_unattempted_share',
    'max_after_time_share',v_ready->'max_after_time_share',
    'last_three_count',coalesce((v_ready->>'last_three_count')::int,0),
    'last_three_evaluation',coalesce(v_ready->'last_three_evaluation','[]'::jsonb),
    'below_l3_count',coalesce((v_ready->>'below_l3_count')::int,0),
    'unresolved_correction_case_count',coalesce((v_ready->>'unresolved_correction_case_count')::int,0),
    'score_window_ready',coalesce((v_ready->>'score_window_ready')::boolean,false),
    'unattempted_gate_ready',coalesce((v_ready->>'unattempted_gate_ready')::boolean,false),
    'after_time_gate_ready',coalesce((v_ready->>'after_time_gate_ready')::boolean,false),
    'reason_code',v_ready->>'reason_code'
  );

  if coalesce((v_ready->>'ready')::boolean,false) then
    v_fingerprint:=md5(v_snapshot::text);
  end if;

  return jsonb_build_object(
    'ready',coalesce((v_ready->>'ready')::boolean,false),
    'fingerprint',v_fingerprint,
    'snapshot',v_snapshot
  );
end;
$$;
revoke all on function private.exam_prep_readiness_review_snapshot_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_readiness_review_snapshot_v1(uuid,bigint,text) to service_role;

create or replace function private.exam_prep_guard_readiness_mentor_review_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_q private.exam_prep_mentor_queue_items%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_state jsonb;
begin
  select * into v_q from private.exam_prep_mentor_queue_items where id=new.queue_item_id;
  if v_q.id is null or v_q.queue_type<>'readiness' then return new; end if;

  if new.learner_user_id<>v_q.learner_user_id
     or new.component_code<>v_q.component_code
     or new.assignment_id<>v_q.assignment_id
     or new.mentor_user_id<>v_q.mentor_user_id then
    raise exception 'exam_prep_readiness_review_scope_mismatch';
  end if;
  if new.verified_level is not null then raise exception 'exam_prep_readiness_is_not_skill_level'; end if;
  if new.decision_code not in ('confirm','reject','hold','needs_retest','escalate') then
    raise exception 'exam_prep_bad_readiness_decision';
  end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_q.learner_user_id;
  if v_profile.program_version_id is null then raise exception 'exam_prep_profile_required'; end if;

  v_state:=private.exam_prep_readiness_review_snapshot_v1(
    v_q.learner_user_id,v_profile.program_version_id,v_q.component_code
  );
  if new.decision_code='confirm' and not coalesce((v_state->>'ready')::boolean,false) then
    raise exception 'exam_prep_readiness_confirmation_requires_app_readiness';
  end if;

  new.requires_second_check:=true;
  new.review_status:='pending_second_check';
  new.review_scope:=(coalesce(new.review_scope,'{}'::jsonb)-'readiness_fingerprint'-'readiness_snapshot')
    || jsonb_build_object(
      'readiness_fingerprint',v_state->>'fingerprint',
      'readiness_snapshot',v_state->'snapshot',
      'server_bound',true
    );
  new.decision_payload:=(coalesce(new.decision_payload,'{}'::jsonb)-'readiness_fingerprint')
    || jsonb_build_object(
      'decision_code',new.decision_code,
      'verified_level',null,
      'readiness_fingerprint',v_state->>'fingerprint',
      'mentor_verified_readiness',false
    );
  return new;
end;
$$;
revoke all on function private.exam_prep_guard_readiness_mentor_review_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_guard_readiness_mentor_review_v1() to service_role;

drop trigger if exists exam_prep_guard_readiness_mentor_review_v1 on private.exam_prep_mentor_reviews;
create trigger exam_prep_guard_readiness_mentor_review_v1
before insert on private.exam_prep_mentor_reviews
for each row execute function private.exam_prep_guard_readiness_mentor_review_v1();

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
begin
  select * into v_r from private.exam_prep_mentor_reviews where id=new.review_id;
  if v_r.id is null then return new; end if;
  select * into v_q from private.exam_prep_mentor_queue_items where id=v_r.queue_item_id;
  if v_q.id is null or v_q.queue_type<>'readiness' then return new; end if;
  if v_r.decision_code<>'confirm' or new.outcome<>'confirmed' then return new; end if;

  if new.reviewer_user_id=v_r.mentor_user_id then raise exception 'exam_prep_second_check_must_be_independent'; end if;
  if not private.exam_prep_has_staff_role_v1(new.reviewer_user_id,array['lead_mentor','academic_moderator']) then
    raise exception 'exam_prep_moderator_role_required' using errcode='42501';
  end if;

  select assignment_id,mentor_user_id into v_assignment,v_mentor
  from private.exam_prep_active_mentor_assignment_v1(v_r.learner_user_id,v_r.component_code);
  if v_assignment is null or v_assignment<>v_r.assignment_id or v_mentor<>v_r.mentor_user_id then
    raise exception 'exam_prep_readiness_assignment_not_active' using errcode='42501';
  end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_r.learner_user_id;
  if v_profile.program_version_id is null then raise exception 'exam_prep_profile_required'; end if;

  v_state:=private.exam_prep_readiness_review_snapshot_v1(
    v_r.learner_user_id,v_profile.program_version_id,v_r.component_code
  );
  v_expected:=nullif(v_r.review_scope->>'readiness_fingerprint','');
  if not coalesce((v_state->>'ready')::boolean,false) or v_expected is null then
    raise exception 'exam_prep_readiness_second_check_stale';
  end if;
  if v_expected<>(v_state->>'fingerprint') then
    raise exception 'exam_prep_readiness_evidence_changed';
  end if;

  insert into private.exam_prep_readiness_signoffs(
    learner_user_id,program_version_id,component_code,assignment_id,mentor_user_id,moderator_user_id,
    review_id,second_check_id,readiness_fingerprint,app_readiness_snapshot
  ) values(
    v_r.learner_user_id,v_profile.program_version_id,v_r.component_code,v_r.assignment_id,
    v_r.mentor_user_id,new.reviewer_user_id,v_r.id,new.id,v_expected,v_state->'snapshot'
  )
  on conflict(learner_user_id,program_version_id,component_code,readiness_fingerprint) do nothing
  returning id into v_signoff;

  if v_signoff is null then
    select s.id into v_signoff
    from private.exam_prep_readiness_signoffs s
    where s.learner_user_id=v_r.learner_user_id
      and s.program_version_id=v_profile.program_version_id
      and s.component_code=v_r.component_code
      and s.readiness_fingerprint=v_expected;
  end if;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,
    target_user_id,component_code,before_state,after_state,metadata
  ) values(
    'math_as_p1_p5',new.reviewer_user_id,'academic_moderator','mentor_verified_readiness_confirmed',
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

drop trigger if exists exam_prep_materialize_readiness_signoff_v1 on private.exam_prep_mentor_second_checks;
create trigger exam_prep_materialize_readiness_signoff_v1
after insert on private.exam_prep_mentor_second_checks
for each row execute function private.exam_prep_materialize_readiness_signoff_v1();

create or replace function private.exam_prep_maybe_recommend_readiness_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_state jsonb;
  v_fingerprint text;
  v_assignment bigint;
  v_mentor uuid;
begin
  if new.component_code not in ('P1','P5') or coalesce(new.operational_stage,0)<6 then return new; end if;

  select assignment_id,mentor_user_id into v_assignment,v_mentor
  from private.exam_prep_active_mentor_assignment_v1(new.user_id,new.component_code);
  if v_assignment is null then return new; end if;

  v_state:=private.exam_prep_readiness_review_snapshot_v1(new.user_id,new.program_version_id,new.component_code);
  if not coalesce((v_state->>'ready')::boolean,false) then return new; end if;
  v_fingerprint:=nullif(v_state->>'fingerprint','');
  if v_fingerprint is null then return new; end if;

  insert into private.exam_prep_human_review_recommendations(
    learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
  ) values(
    new.user_id,new.component_code,'readiness','readiness_fingerprint',
    concat(new.user_id::text,':',new.program_version_id::text,':',new.component_code,':',v_fingerprint),
    'Deterministic component App Readiness is complete. Assigned Mentor Care may issue a separate human-confirmed readiness decision after evidence review and independent second check.'
  ) on conflict(source_object_type,source_object_id,recommendation_type) do nothing;

  return new;
end;
$$;
revoke all on function private.exam_prep_maybe_recommend_readiness_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_maybe_recommend_readiness_v1() to service_role;

drop trigger if exists exam_prep_maybe_recommend_readiness_v1 on private.exam_prep_stage_states;
create trigger exam_prep_maybe_recommend_readiness_v1
after insert or update on private.exam_prep_stage_states
for each row execute function private.exam_prep_maybe_recommend_readiness_v1();

create or replace function private.exam_prep_mentor_verified_readiness_status_v1(
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
  v_state jsonb;
  v_fingerprint text;
  v_service boolean:=false;
  v_signoff private.exam_prep_readiness_signoffs%rowtype;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_state:=private.exam_prep_readiness_review_snapshot_v1(p_user_id,p_program_version_id,p_component_code);
  v_fingerprint:=nullif(v_state->>'fingerprint','');
  select exists(select 1 from private.exam_prep_active_mentor_assignment_v1(p_user_id,p_component_code)) into v_service;

  if coalesce((v_state->>'ready')::boolean,false) and v_fingerprint is not null then
    select * into v_signoff
    from private.exam_prep_readiness_signoffs s
    where s.learner_user_id=p_user_id
      and s.program_version_id=p_program_version_id
      and s.component_code=p_component_code
      and s.readiness_fingerprint=v_fingerprint
    order by s.created_at desc,s.id desc
    limit 1;
  end if;

  return jsonb_build_object(
    'component_code',p_component_code,
    'service_available',v_service,
    'mentor_verified',v_signoff.id is not null,
    'confirmed_at',v_signoff.created_at,
    'reason_code',case
      when not coalesce((v_state->>'ready')::boolean,false) then 'app_readiness_not_ready'
      when v_signoff.id is not null then 'mentor_verified'
      when v_service then 'human_confirmation_pending'
      else 'mentor_care_not_active'
    end,
    'current_evidence_bound',v_signoff.id is not null
  );
end;
$$;
revoke all on function private.exam_prep_mentor_verified_readiness_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_mentor_verified_readiness_status_v1(uuid,bigint,text) to service_role;

create or replace function public.get_exam_prep_mentor_verified_readiness_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;
  return private.exam_prep_mentor_verified_readiness_status_v1(v_uid,v_program,p_component_code);
end;
$$;
revoke execute on function public.get_exam_prep_mentor_verified_readiness_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_mentor_verified_readiness_safe_v1(text) to authenticated,service_role;

create or replace function public.get_exam_prep_readiness_review_packet_safe_v1(p_queue_item_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_q private.exam_prep_mentor_queue_items%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_state jsonb;
  v_allowed boolean:=false;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  select * into v_q from private.exam_prep_mentor_queue_items where id=p_queue_item_id;
  if v_q.id is null or v_q.queue_type<>'readiness' then raise exception 'exam_prep_readiness_queue_not_found' using errcode='P0002'; end if;

  if v_q.mentor_user_id=v_uid and exists(
    select 1 from private.exam_prep_active_mentor_assignment_v1(v_q.learner_user_id,v_q.component_code) a
    where a.assignment_id=v_q.assignment_id and a.mentor_user_id=v_uid
  ) then
    v_allowed:=true;
  elsif v_q.status='pending_second_check'
    and private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator'])
    and exists(
      select 1 from private.exam_prep_mentor_reviews r
      where r.queue_item_id=v_q.id and r.review_status='pending_second_check' and r.mentor_user_id<>v_uid
    ) then
    v_allowed:=true;
  end if;
  if not v_allowed then raise exception 'exam_prep_readiness_review_access_denied' using errcode='42501'; end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_q.learner_user_id;
  if v_profile.program_version_id is null then raise exception 'exam_prep_profile_required'; end if;
  v_state:=private.exam_prep_readiness_review_snapshot_v1(v_q.learner_user_id,v_profile.program_version_id,v_q.component_code);

  return jsonb_build_object(
    'queue_item_id',v_q.id,
    'learner_user_id',v_q.learner_user_id,
    'component_code',v_q.component_code,
    'priority_class',v_q.priority_class,
    'status',v_q.status,
    'requires_second_check',true,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'app_readiness',v_state->'snapshot',
    'current_app_readiness_ready',coalesce((v_state->>'ready')::boolean,false),
    'current_evidence_fingerprint',v_state->>'fingerprint',
    'raw_responses_editable',false
  );
end;
$$;
revoke execute on function public.get_exam_prep_readiness_review_packet_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_readiness_review_packet_safe_v1(uuid) to authenticated,service_role;

-- Preserve the current learner-facing Cambridge threshold reference while surfacing the separate human status.
create or replace function public.get_exam_prep_readiness_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_target_grade text;
  v_result jsonb;
  v_reference jsonb;
  v_human jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id,target_grade into v_program,v_target_grade
  from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  v_result:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  v_reference:=private.exam_prep_latest_threshold_reference_v1(v_program,p_component_code,v_target_grade);
  v_human:=private.exam_prep_mentor_verified_readiness_status_v1(v_uid,v_program,p_component_code);

  return (v_result - 'threshold_version') || jsonb_build_object(
    'threshold_reference',v_reference,
    'mentor_verified_readiness',coalesce((v_human->>'mentor_verified')::boolean,false),
    'mentor_verified_confirmed_at',v_human->'confirmed_at',
    'mentor_care_service_available',coalesce((v_human->>'service_available')::boolean,false),
    'mentor_verified_status',v_human->>'reason_code'
  );
end;
$$;
revoke execute on function public.get_exam_prep_readiness_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_readiness_safe_v1(text) to authenticated,service_role;

do $$
declare
  v_rls boolean;
  v_def text;
  v_approved int;
begin
  select c.relrowsecurity into v_rls
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='private' and c.relname='exam_prep_readiness_signoffs';
  if not coalesce(v_rls,false) then raise exception 'P2-05 Mentor Verified: readiness signoff RLS missing'; end if;

  if to_regprocedure('public.get_exam_prep_mentor_verified_readiness_safe_v1(text)') is null
     or to_regprocedure('public.get_exam_prep_readiness_review_packet_safe_v1(uuid)') is null then
    raise exception 'P2-05 Mentor Verified: safe RPC missing';
  end if;

  select pg_get_functiondef('private.exam_prep_materialize_readiness_signoff_v1()'::regprocedure) into v_def;
  if position('exam_prep_readiness_evidence_changed' in v_def)=0
     or position('lead_mentor' in v_def)=0
     or position('academic_moderator' in v_def)=0 then
    raise exception 'P2-05 Mentor Verified: independent stale-evidence guard missing';
  end if;

  select count(*) into v_approved from private.exam_prep_stage5_thresholds where status='approved';
  if v_approved<>0 then
    raise exception 'P2-05 Mentor Verified: this release must not approve Stage-5 thresholds';
  end if;
end $$;

commit;
