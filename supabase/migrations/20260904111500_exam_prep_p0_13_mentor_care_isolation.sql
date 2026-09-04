-- P0-13: limited-seat Mentor Care isolation.
-- Mentor Care is an optional human-verification/service layer above Core.
-- No raw response/evidence/mastery rewrite. Queue creation requires active entitlement + active assignment + active staff role.
-- Unassigned/waitlisted/paused learners may keep human-review recommendation metadata but create no routine queue/SLA work.

begin;

create table if not exists private.exam_prep_staff_roles (
  user_id uuid not null references public.users(id) on delete cascade,
  role_code text not null check(role_code in ('mentor','lead_mentor','academic_moderator','mentor_ops','safeguarding_lead')),
  role_status text not null default 'active' check(role_status in ('active','inactive')),
  valid_from timestamptz not null default now(),
  valid_until timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  primary key(user_id,role_code),
  check(valid_until is null or valid_until>valid_from)
);

create table if not exists private.exam_prep_human_review_recommendations (
  id uuid primary key default gen_random_uuid(),
  learner_user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text null,
  recommendation_type text not null check(recommendation_type in (
    'written_mastery','failed_retest','graph_review','mixed_timed_review',
    'placement_confirmation','placement_advanced_skip','stage_gate','readiness','override_review'
  )),
  evidence_id uuid null references private.exam_prep_evidence_events(id) on delete restrict,
  correction_case_id uuid null references private.exam_prep_correction_cases(id) on delete restrict,
  source_object_type text not null,
  source_object_id text not null,
  human_review_recommended boolean not null default true,
  recommendation_reason text not null,
  created_at timestamptz not null default now(),
  unique(source_object_type,source_object_id,recommendation_type)
);

create table if not exists private.exam_prep_mentor_queue_items (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references private.exam_prep_human_review_recommendations(id) on delete restrict,
  assignment_id bigint not null references private.exam_prep_mentor_assignments(id) on delete restrict,
  learner_user_id uuid not null references public.users(id) on delete cascade,
  mentor_user_id uuid not null references public.users(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text null,
  queue_type text not null check(queue_type in (
    'written_mastery','failed_retest','graph_review','mixed_timed_review',
    'placement_confirmation','placement_advanced_skip','stage_gate','readiness','override_review'
  )),
  priority_class text not null check(priority_class in ('P0','P1','P2','P3')),
  status text not null default 'open' check(status in ('open','in_review','pending_second_check','resolved','withdrawn')),
  requires_second_check boolean not null default false,
  requested_decision text not null,
  opened_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz null,
  check(learner_user_id<>mentor_user_id)
);
create unique index if not exists exam_prep_one_queue_item_per_recommendation_idx
  on private.exam_prep_mentor_queue_items(recommendation_id)
  where status<>'withdrawn';
create index if not exists exam_prep_mentor_queue_by_mentor_idx
  on private.exam_prep_mentor_queue_items(mentor_user_id,status,priority_class,opened_at);

create table if not exists private.exam_prep_mentor_reviews (
  id uuid primary key default gen_random_uuid(),
  queue_item_id uuid not null references private.exam_prep_mentor_queue_items(id) on delete restrict,
  assignment_id bigint not null references private.exam_prep_mentor_assignments(id) on delete restrict,
  learner_user_id uuid not null references public.users(id) on delete cascade,
  mentor_user_id uuid not null references public.users(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text null,
  decision_code text not null check(decision_code in ('verified','partial','insufficient','needs_retest','hold','confirm','reject','escalate')),
  verified_level smallint null check(verified_level in (4,5)),
  reason_code text not null,
  reason_text text not null,
  linked_evidence_ids uuid[] not null default '{}'::uuid[],
  before_snapshot jsonb not null default '{}'::jsonb,
  decision_payload jsonb not null default '{}'::jsonb,
  review_scope jsonb not null default '{}'::jsonb,
  requires_second_check boolean not null default false,
  review_status text not null check(review_status in ('final','pending_second_check')),
  created_at timestamptz not null default now(),
  check((decision_code='verified') or verified_level is null),
  check(char_length(reason_text) between 10 and 4000)
);
create index if not exists exam_prep_mentor_reviews_queue_idx on private.exam_prep_mentor_reviews(queue_item_id,created_at desc);

create table if not exists private.exam_prep_mentor_second_checks (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references private.exam_prep_mentor_reviews(id) on delete restrict,
  queue_item_id uuid not null references private.exam_prep_mentor_queue_items(id) on delete restrict,
  reviewer_user_id uuid not null references public.users(id) on delete restrict,
  outcome text not null check(outcome in ('confirmed','rejected','needs_revision')),
  reason_text text not null,
  created_at timestamptz not null default now(),
  unique(review_id),
  check(char_length(reason_text) between 10 and 4000)
);

create table if not exists private.exam_prep_safeguarding_events (
  id uuid primary key default gen_random_uuid(),
  learner_user_id uuid not null references public.users(id) on delete cascade,
  assignment_id bigint null references private.exam_prep_mentor_assignments(id) on delete restrict,
  component_code text null check(component_code is null or component_code in ('P1','P5')),
  raised_by_user_id uuid not null references public.users(id) on delete restrict,
  severity text not null check(severity in ('concern','urgent','critical')),
  reason_code text not null,
  summary text not null,
  status text not null default 'open' check(status in ('open','triaged','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz null,
  check(char_length(summary) between 10 and 4000)
);

-- Private service objects: no direct learner/mentor table access. Safe RPCs expose decision-sized data only.
do $$ declare t text; begin
  foreach t in array array[
    'exam_prep_staff_roles','exam_prep_human_review_recommendations','exam_prep_mentor_queue_items',
    'exam_prep_mentor_reviews','exam_prep_mentor_second_checks','exam_prep_safeguarding_events'
  ] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

-- Human decisions and recommendation facts are append-only.
drop trigger if exists exam_prep_human_review_recommendations_immutable_v1 on private.exam_prep_human_review_recommendations;
create trigger exam_prep_human_review_recommendations_immutable_v1
before update or delete on private.exam_prep_human_review_recommendations
for each row execute function private.exam_prep_block_immutable_mutation_v1();

drop trigger if exists exam_prep_mentor_reviews_immutable_v1 on private.exam_prep_mentor_reviews;
create trigger exam_prep_mentor_reviews_immutable_v1
before update or delete on private.exam_prep_mentor_reviews
for each row execute function private.exam_prep_block_immutable_mutation_v1();

drop trigger if exists exam_prep_mentor_second_checks_immutable_v1 on private.exam_prep_mentor_second_checks;
create trigger exam_prep_mentor_second_checks_immutable_v1
before update or delete on private.exam_prep_mentor_second_checks
for each row execute function private.exam_prep_block_immutable_mutation_v1();

-- Mutable operational anchors remain fully audited.
drop trigger if exists exam_prep_staff_roles_audit_v1 on private.exam_prep_staff_roles;
create trigger exam_prep_staff_roles_audit_v1 after insert or update or delete on private.exam_prep_staff_roles
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_mentor_queue_items_audit_v1 on private.exam_prep_mentor_queue_items;
create trigger exam_prep_mentor_queue_items_audit_v1 after insert or update or delete on private.exam_prep_mentor_queue_items
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_safeguarding_events_audit_v1 on private.exam_prep_safeguarding_events;
create trigger exam_prep_safeguarding_events_audit_v1 after insert or update or delete on private.exam_prep_safeguarding_events
for each row execute function private.exam_prep_audit_row_change_v1();

create or replace function private.exam_prep_has_staff_role_v1(p_user_id uuid,p_roles text[])
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1 from private.exam_prep_staff_roles r
    where r.user_id=p_user_id
      and r.role_code=any(p_roles)
      and r.role_status='active'
      and r.valid_from<=now()
      and (r.valid_until is null or r.valid_until>now())
  );
$$;
revoke all on function private.exam_prep_has_staff_role_v1(uuid,text[]) from public,anon,authenticated;
grant execute on function private.exam_prep_has_staff_role_v1(uuid,text[]) to service_role;

create or replace function private.exam_prep_active_mentor_assignment_v1(
  p_learner_user_id uuid,p_component_code text
)
returns table(assignment_id bigint,mentor_user_id uuid)
language sql
stable
security definer
set search_path=''
as $$
  select a.id,a.mentor_user_id
  from private.exam_prep_mentor_assignments a
  join private.exam_prep_mentor_service_status s on s.learner_user_id=a.learner_user_id and s.service_status='assigned_active'
  join private.exam_prep_feature_entitlements e on e.user_id=a.learner_user_id
    and e.entitlement_status='active' and e.core_access and e.mentor_care_entitled
    and (e.valid_from is null or e.valid_from<=now()) and (e.valid_until is null or e.valid_until>now())
  join private.exam_prep_feature_config c on c.id=1 and not c.kill_switch and c.core_enabled and c.mentor_enabled and c.rollout_state<>'off'
  where a.learner_user_id=p_learner_user_id and a.component_code=p_component_code
    and a.assignment_status='active' and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
    and private.exam_prep_has_staff_role_v1(a.mentor_user_id,array['mentor','lead_mentor','academic_moderator'])
  order by a.valid_from desc
  limit 1;
$$;
revoke all on function private.exam_prep_active_mentor_assignment_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_active_mentor_assignment_v1(uuid,text) to service_role;

create or replace function private.exam_prep_maybe_enqueue_recommendation_v1(p_recommendation_id uuid)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_rec private.exam_prep_human_review_recommendations%rowtype;
  v_assignment bigint;
  v_mentor uuid;
  v_queue uuid;
  v_priority text;
  v_second boolean;
begin
  select * into v_rec from private.exam_prep_human_review_recommendations where id=p_recommendation_id;
  if v_rec.id is null then return null; end if;

  select assignment_id,mentor_user_id into v_assignment,v_mentor
  from private.exam_prep_active_mentor_assignment_v1(v_rec.learner_user_id,v_rec.component_code);
  if v_assignment is null then return null; end if;

  v_priority:=case
    when v_rec.recommendation_type in ('readiness','placement_advanced_skip','override_review') then 'P0'
    when v_rec.recommendation_type in ('failed_retest','placement_confirmation','stage_gate') then 'P1'
    when v_rec.recommendation_type in ('written_mastery','graph_review','mixed_timed_review') then 'P2'
    else 'P3' end;
  v_second:=v_rec.recommendation_type in ('readiness','placement_advanced_skip','override_review');

  insert into private.exam_prep_mentor_queue_items(
    recommendation_id,assignment_id,learner_user_id,mentor_user_id,component_code,skill_code,
    queue_type,priority_class,status,requires_second_check,requested_decision
  ) values(
    v_rec.id,v_assignment,v_rec.learner_user_id,v_mentor,v_rec.component_code,v_rec.skill_code,
    v_rec.recommendation_type,v_priority,'open',v_second,
    case v_rec.recommendation_type
      when 'written_mastery' then 'Verify written/method evidence under the governed iClub rubric.'
      when 'failed_retest' then 'Review failed delayed retest and choose the next corrective action.'
      when 'placement_advanced_skip' then 'Confirm/deny high-impact advanced placement with linked evidence.'
      when 'readiness' then 'Issue component-specific Mentor Verified readiness decision only if all human gates are satisfied.'
      else 'Resolve the named human-judgement question using linked evidence only.' end
  )
  on conflict(recommendation_id) where status<>'withdrawn' do nothing
  returning id into v_queue;
  return v_queue;
end;
$$;
revoke all on function private.exam_prep_maybe_enqueue_recommendation_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_maybe_enqueue_recommendation_v1(uuid) to service_role;

create or replace function private.exam_prep_recommendation_enqueue_trigger_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  perform private.exam_prep_maybe_enqueue_recommendation_v1(new.id);
  return new;
end;
$$;
revoke all on function private.exam_prep_recommendation_enqueue_trigger_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_recommendation_enqueue_v1 on private.exam_prep_human_review_recommendations;
create trigger exam_prep_recommendation_enqueue_v1
after insert on private.exam_prep_human_review_recommendations
for each row execute function private.exam_prep_recommendation_enqueue_trigger_v1();

-- Written evidence may recommend human verification for everyone, but only active Mentor Care assignment creates queue work.
create or replace function private.exam_prep_written_review_recommendation_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if new.evidence_type='written' and new.verification_status in ('self_reviewed','human_review_recommended') then
    insert into private.exam_prep_human_review_recommendations(
      learner_user_id,component_code,skill_code,recommendation_type,evidence_id,
      source_object_type,source_object_id,recommendation_reason
    ) values(
      new.user_id,new.component_code,new.skill_code,'written_mastery',new.id,
      'evidence_event',new.id::text,'Canonical written/method evidence may benefit from human verification; metadata alone does not create human authority.'
    ) on conflict(source_object_type,source_object_id,recommendation_type) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_written_review_recommendation_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_written_review_recommendation_v1 on private.exam_prep_evidence_events;
create trigger exam_prep_written_review_recommendation_v1
after insert on private.exam_prep_evidence_events
for each row execute function private.exam_prep_written_review_recommendation_v1();

-- A failed delayed retest is human-review-worthy only for actively assigned Mentor Care learners.
create or replace function private.exam_prep_failed_retest_recommendation_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if new.action_type='retest_failed' then
    insert into private.exam_prep_human_review_recommendations(
      learner_user_id,component_code,skill_code,recommendation_type,correction_case_id,
      source_object_type,source_object_id,recommendation_reason
    ) values(
      new.user_id,new.component_code,new.skill_code,'failed_retest',new.correction_case_id,
      'correction_action',new.id::text,'Failed delayed retest requires corrective reclassification where human service is actively assigned.'
    ) on conflict(source_object_type,source_object_id,recommendation_type) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_failed_retest_recommendation_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_failed_retest_recommendation_v1 on private.exam_prep_correction_actions;
create trigger exam_prep_failed_retest_recommendation_v1
after insert on private.exam_prep_correction_actions
for each row execute function private.exam_prep_failed_retest_recommendation_v1();

create or replace function public.get_exam_prep_mentor_queue_safe_v1()
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_result jsonb;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['mentor','lead_mentor','academic_moderator']) then
    raise exception 'exam_prep_mentor_role_required' using errcode='42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'queue_item_id',q.id,
    'learner_user_id',q.learner_user_id,
    'assignment_id',q.assignment_id,
    'component_code',q.component_code,
    'skill_code',q.skill_code,
    'queue_type',q.queue_type,
    'priority_class',q.priority_class,
    'status',q.status,
    'requires_second_check',q.requires_second_check,
    'requested_decision',q.requested_decision,
    'opened_at',q.opened_at,
    'recommendation',jsonb_build_object(
      'reason',r.recommendation_reason,
      'evidence_id',r.evidence_id,
      'correction_case_id',r.correction_case_id,
      'source_object_type',r.source_object_type,
      'source_object_id',r.source_object_id
    )
  ) order by case q.priority_class when 'P0' then 0 when 'P1' then 1 when 'P2' then 2 else 3 end,q.opened_at),'[]'::jsonb)
  into v_result
  from private.exam_prep_mentor_queue_items q
  join private.exam_prep_human_review_recommendations r on r.id=q.recommendation_id
  where q.mentor_user_id=v_uid and q.status in ('open','in_review','pending_second_check')
    and exists(
      select 1 from private.exam_prep_active_mentor_assignment_v1(q.learner_user_id,q.component_code) a
      where a.assignment_id=q.assignment_id and a.mentor_user_id=v_uid
    );
  return v_result;
end;
$$;
revoke execute on function public.get_exam_prep_mentor_queue_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_mentor_queue_safe_v1() to authenticated,service_role;

create or replace function public.submit_exam_prep_mentor_review_safe_v1(
  p_queue_item_id uuid,
  p_decision_code text,
  p_reason_code text,
  p_reason_text text,
  p_verified_level smallint default null,
  p_review_scope jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_q private.exam_prep_mentor_queue_items%rowtype;
  v_rec private.exam_prep_human_review_recommendations%rowtype;
  v_review uuid;
  v_second boolean;
  v_before jsonb;
  v_evidence uuid[]:='{}'::uuid[];
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['mentor','lead_mentor','academic_moderator']) then raise exception 'exam_prep_mentor_role_required' using errcode='42501'; end if;
  if p_decision_code not in ('verified','partial','insufficient','needs_retest','hold','confirm','reject','escalate') then raise exception 'exam_prep_bad_mentor_decision'; end if;
  if p_reason_text is null or char_length(p_reason_text) not between 10 and 4000 then raise exception 'exam_prep_mentor_reason_required'; end if;
  if p_reason_code is null or char_length(p_reason_code) not between 2 and 80 then raise exception 'exam_prep_mentor_reason_code_required'; end if;
  if p_verified_level is not null and (p_decision_code<>'verified' or p_verified_level not in (4,5)) then raise exception 'exam_prep_bad_verified_level'; end if;

  select * into v_q from private.exam_prep_mentor_queue_items where id=p_queue_item_id for update;
  if v_q.id is null or v_q.mentor_user_id<>v_uid then raise exception 'exam_prep_mentor_queue_not_found' using errcode='P0002'; end if;
  if v_q.status not in ('open','in_review') then raise exception 'exam_prep_mentor_queue_not_reviewable'; end if;
  if not exists(select 1 from private.exam_prep_active_mentor_assignment_v1(v_q.learner_user_id,v_q.component_code) a where a.assignment_id=v_q.assignment_id and a.mentor_user_id=v_uid) then
    raise exception 'exam_prep_mentor_assignment_not_active' using errcode='42501';
  end if;

  select * into v_rec from private.exam_prep_human_review_recommendations where id=v_q.recommendation_id;
  if v_rec.evidence_id is not null then v_evidence:=array[v_rec.evidence_id]; end if;
  select jsonb_build_object(
    'objective_skill_state',(select to_jsonb(s) - 'user_id' from private.exam_prep_skill_states s where s.user_id=v_q.learner_user_id and s.component_code=v_q.component_code and s.skill_code=v_q.skill_code order by s.derived_at desc limit 1),
    'placement',(select to_jsonb(p) - 'user_id' from private.exam_prep_component_placements p where p.user_id=v_q.learner_user_id and p.component_code=v_q.component_code order by p.derived_at desc limit 1),
    'correction',(select to_jsonb(c) - 'user_id' from private.exam_prep_correction_cases c where c.id=v_rec.correction_case_id)
  ) into v_before;

  v_second:=v_q.requires_second_check or p_verified_level=5 or v_q.queue_type in ('placement_advanced_skip','readiness','override_review');
  insert into private.exam_prep_mentor_reviews(
    queue_item_id,assignment_id,learner_user_id,mentor_user_id,component_code,skill_code,
    decision_code,verified_level,reason_code,reason_text,linked_evidence_ids,before_snapshot,
    decision_payload,review_scope,requires_second_check,review_status
  ) values(
    v_q.id,v_q.assignment_id,v_q.learner_user_id,v_uid,v_q.component_code,v_q.skill_code,
    p_decision_code,p_verified_level,p_reason_code,p_reason_text,v_evidence,coalesce(v_before,'{}'::jsonb),
    jsonb_build_object('decision_code',p_decision_code,'verified_level',p_verified_level),coalesce(p_review_scope,'{}'::jsonb),
    v_second,case when v_second then 'pending_second_check' else 'final' end
  ) returning id into v_review;

  update private.exam_prep_mentor_queue_items
    set status=case when v_second then 'pending_second_check' else 'resolved' end,
        updated_at=now(),resolved_at=case when v_second then null else now() end
  where id=v_q.id;

  insert into private.exam_prep_audit_events(program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,before_state,after_state,metadata)
  values('math_as_p1_p5',v_uid,'mentor','mentor_review_created','private.exam_prep_mentor_reviews',v_review::text,v_q.learner_user_id,v_q.component_code,
    v_before,jsonb_build_object('decision_code',p_decision_code,'verified_level',p_verified_level,'review_status',case when v_second then 'pending_second_check' else 'final' end),
    jsonb_build_object('queue_item_id',v_q.id,'assignment_id',v_q.assignment_id,'requires_second_check',v_second));

  return jsonb_build_object('review_id',v_review,'queue_item_id',v_q.id,'status',case when v_second then 'pending_second_check' else 'final' end,'requires_second_check',v_second);
end;
$$;
revoke execute on function public.submit_exam_prep_mentor_review_safe_v1(uuid,text,text,text,smallint,jsonb) from public,anon;
grant execute on function public.submit_exam_prep_mentor_review_safe_v1(uuid,text,text,text,smallint,jsonb) to authenticated,service_role;

create or replace function public.get_exam_prep_second_check_queue_safe_v1()
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_result jsonb;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator']) then raise exception 'exam_prep_moderator_role_required' using errcode='42501'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'review_id',r.id,'queue_item_id',r.queue_item_id,'learner_user_id',r.learner_user_id,
    'mentor_user_id',r.mentor_user_id,'component_code',r.component_code,'skill_code',r.skill_code,
    'decision_code',r.decision_code,'verified_level',r.verified_level,'reason_code',r.reason_code,
    'reason_text',r.reason_text,'linked_evidence_ids',r.linked_evidence_ids,'before_snapshot',r.before_snapshot,
    'decision_payload',r.decision_payload,'review_scope',r.review_scope,'created_at',r.created_at
  ) order by r.created_at),'[]'::jsonb) into v_result
  from private.exam_prep_mentor_reviews r
  join private.exam_prep_mentor_queue_items q on q.id=r.queue_item_id
  where r.review_status='pending_second_check' and q.status='pending_second_check'
    and r.mentor_user_id<>v_uid
    and not exists(select 1 from private.exam_prep_mentor_second_checks sc where sc.review_id=r.id);
  return v_result;
end;
$$;
revoke execute on function public.get_exam_prep_second_check_queue_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_second_check_queue_safe_v1() to authenticated,service_role;

create or replace function public.submit_exam_prep_second_check_safe_v1(
  p_review_id uuid,p_outcome text,p_reason_text text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_r private.exam_prep_mentor_reviews%rowtype; v_q private.exam_prep_mentor_queue_items%rowtype; v_sc uuid;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator']) then raise exception 'exam_prep_moderator_role_required' using errcode='42501'; end if;
  if p_outcome not in ('confirmed','rejected','needs_revision') then raise exception 'exam_prep_bad_second_check_outcome'; end if;
  if p_reason_text is null or char_length(p_reason_text) not between 10 and 4000 then raise exception 'exam_prep_second_check_reason_required'; end if;

  select * into v_r from private.exam_prep_mentor_reviews where id=p_review_id;
  if v_r.id is null or v_r.review_status<>'pending_second_check' then raise exception 'exam_prep_review_not_pending_second_check' using errcode='P0002'; end if;
  if v_r.mentor_user_id=v_uid then raise exception 'exam_prep_second_check_must_be_independent' using errcode='42501'; end if;
  select * into v_q from private.exam_prep_mentor_queue_items where id=v_r.queue_item_id for update;
  if v_q.status<>'pending_second_check' then raise exception 'exam_prep_queue_not_pending_second_check'; end if;

  insert into private.exam_prep_mentor_second_checks(review_id,queue_item_id,reviewer_user_id,outcome,reason_text)
  values(v_r.id,v_q.id,v_uid,p_outcome,p_reason_text) returning id into v_sc;

  update private.exam_prep_mentor_queue_items
    set status=case when p_outcome='confirmed' then 'resolved' else 'open' end,
        updated_at=now(),resolved_at=case when p_outcome='confirmed' then now() else null end
  where id=v_q.id;

  insert into private.exam_prep_audit_events(program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,before_state,after_state,metadata)
  values('math_as_p1_p5',v_uid,'academic_moderator','mentor_second_check_created','private.exam_prep_mentor_second_checks',v_sc::text,v_r.learner_user_id,v_r.component_code,
    jsonb_build_object('review_id',v_r.id,'decision_code',v_r.decision_code,'verified_level',v_r.verified_level),
    jsonb_build_object('outcome',p_outcome),jsonb_build_object('queue_item_id',v_q.id,'original_mentor_user_id',v_r.mentor_user_id));
  return jsonb_build_object('second_check_id',v_sc,'review_id',v_r.id,'outcome',p_outcome,'queue_status',case when p_outcome='confirmed' then 'resolved' else 'open' end);
end;
$$;
revoke execute on function public.submit_exam_prep_second_check_safe_v1(uuid,text,text) from public,anon;
grant execute on function public.submit_exam_prep_second_check_safe_v1(uuid,text,text) to authenticated,service_role;

create or replace function public.raise_exam_prep_safeguarding_safe_v1(
  p_assignment_id bigint,p_severity text,p_reason_code text,p_summary text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_a private.exam_prep_mentor_assignments%rowtype; v_event uuid;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['mentor','lead_mentor','academic_moderator','mentor_ops','safeguarding_lead']) then raise exception 'exam_prep_staff_role_required' using errcode='42501'; end if;
  if p_severity not in ('concern','urgent','critical') then raise exception 'exam_prep_bad_safeguarding_severity'; end if;
  if p_reason_code is null or char_length(p_reason_code) not between 2 and 80 then raise exception 'exam_prep_safeguarding_reason_code_required'; end if;
  if p_summary is null or char_length(p_summary) not between 10 and 4000 then raise exception 'exam_prep_safeguarding_summary_required'; end if;

  select * into v_a from private.exam_prep_mentor_assignments where id=p_assignment_id;
  if v_a.id is null then raise exception 'exam_prep_assignment_not_found' using errcode='P0002'; end if;
  if v_a.assignment_status not in ('active','paused') then raise exception 'exam_prep_safeguarding_assignment_scope_ended'; end if;
  if v_a.mentor_user_id<>v_uid and not private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator','mentor_ops','safeguarding_lead']) then
    raise exception 'exam_prep_safeguarding_assignment_scope_required' using errcode='42501';
  end if;

  insert into private.exam_prep_safeguarding_events(
    learner_user_id,assignment_id,component_code,raised_by_user_id,severity,reason_code,summary,status
  ) values(v_a.learner_user_id,v_a.id,v_a.component_code,v_uid,p_severity,p_reason_code,p_summary,'open')
  returning id into v_event;

  insert into private.exam_prep_audit_events(program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,metadata)
  values('math_as_p1_p5',v_uid,'mentor_staff','safeguarding_escalated','private.exam_prep_safeguarding_events',v_event::text,v_a.learner_user_id,v_a.component_code,
    jsonb_build_object('severity',p_severity,'reason_code',p_reason_code,'assignment_id',v_a.id));
  return jsonb_build_object('safeguarding_event_id',v_event,'status','open','severity',p_severity);
end;
$$;
revoke execute on function public.raise_exam_prep_safeguarding_safe_v1(bigint,text,text,text) from public,anon;
grant execute on function public.raise_exam_prep_safeguarding_safe_v1(bigint,text,text,text) to authenticated,service_role;

commit;
