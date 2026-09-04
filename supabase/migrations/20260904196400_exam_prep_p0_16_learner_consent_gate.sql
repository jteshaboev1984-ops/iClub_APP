-- P0-16 controlled-beta learner-consent gate.
--
-- Safety intent:
-- * Project Owner release approval is not a substitute for learner consent;
-- * beta membership remains dark until an explicit consent record exists;
-- * approval/activation cannot be bypassed with a direct server-side member write;
-- * revoking consent before first activation reopens the cohort as DRAFT;
-- * revoking consent after live activation fail-closes the entire beta immediately;
-- * this migration itself activates nobody and preserves the global kill switch.

begin;

create table if not exists private.exam_prep_beta_consents (
  id bigint generated always as identity primary key,
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  consent_scope text not null default 'exam_prep_controlled_beta_v1'
    check (consent_scope='exam_prep_controlled_beta_v1'),
  consent_status text not null check (consent_status in ('granted','revoked')),
  consented_at timestamptz not null,
  grant_evidence_ref text not null
    check (char_length(trim(grant_evidence_ref)) between 5 and 500),
  revoked_at timestamptz,
  revocation_evidence_ref text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique(cohort_id,user_id),
  check (
    (consent_status='granted' and revoked_at is null and revocation_evidence_ref is null)
    or
    (consent_status='revoked' and revoked_at is not null
      and char_length(trim(revocation_evidence_ref)) between 5 and 500)
  )
);

create index if not exists exam_prep_beta_consents_cohort_status_idx
on private.exam_prep_beta_consents(cohort_id,consent_status,user_id);

alter table private.exam_prep_beta_consents enable row level security;
revoke all on private.exam_prep_beta_consents from public,anon,authenticated,service_role;
grant select on private.exam_prep_beta_consents to service_role;

drop trigger if exists exam_prep_beta_consents_audit_v1
on private.exam_prep_beta_consents;
create trigger exam_prep_beta_consents_audit_v1
after insert or update or delete on private.exam_prep_beta_consents
for each row execute function private.exam_prep_audit_row_change_v1();

create or replace function private.exam_prep_beta_consent_granted_v1(
  p_cohort_id bigint,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_beta_consents c
    where c.cohort_id=p_cohort_id
      and c.user_id=p_user_id
      and c.consent_scope='exam_prep_controlled_beta_v1'
      and c.consent_status='granted'
      and c.revoked_at is null
  );
$$;
revoke all on function private.exam_prep_beta_consent_granted_v1(bigint,uuid)
from public,anon,authenticated,service_role;

-- Defense in depth: even a direct service-side update of beta_members cannot
-- move a learner into APPROVED or ACTIVE without an effective consent record.
create or replace function private.enforce_exam_prep_beta_member_consent_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if new.member_status in ('approved','active')
     and not private.exam_prep_beta_consent_granted_v1(new.cohort_id,new.user_id) then
    raise exception 'exam_prep_beta_consent_required: cohort %, user %',new.cohort_id,new.user_id;
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_beta_member_consent_v1()
from public,anon,authenticated,service_role;

drop trigger if exists exam_prep_beta_member_consent_guard_v1
on private.exam_prep_beta_members;
create trigger exam_prep_beta_member_consent_guard_v1
before insert or update of cohort_id,user_id,member_status
on private.exam_prep_beta_members
for each row execute function private.enforce_exam_prep_beta_member_consent_v1();

-- Record an explicit learner opt-in. The evidence reference is intentionally
-- opaque (form response id, message reference, signed-record id, etc.); PII does
-- not need to be copied into this table.
create or replace function public.record_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_user_id uuid,
  p_evidence_ref text,
  p_consented_at timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_id bigint;
begin
  if p_evidence_ref is null or char_length(trim(p_evidence_ref)) not between 5 and 500 then
    raise exception 'exam_prep_beta_consent_evidence_required';
  end if;
  if p_consented_at is null or p_consented_at>now()+interval '5 minutes' then
    raise exception 'exam_prep_beta_consent_bad_timestamp';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status<>'draft' then
    raise exception 'exam_prep_beta_consent_grant_requires_draft_cohort';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id
  for update;
  if v_m.id is null then
    raise exception 'exam_prep_beta_member_not_found' using errcode='P0002';
  end if;
  if v_m.member_status<>'candidate' then
    raise exception 'exam_prep_beta_consent_grant_requires_candidate';
  end if;

  insert into private.exam_prep_beta_consents(
    cohort_id,user_id,consent_scope,consent_status,consented_at,grant_evidence_ref,
    revoked_at,revocation_evidence_ref,created_by,updated_by
  ) values (
    v_c.id,p_user_id,'exam_prep_controlled_beta_v1','granted',p_consented_at,trim(p_evidence_ref),
    null,null,auth.uid(),auth.uid()
  )
  on conflict(cohort_id,user_id) do update set
    consent_scope='exam_prep_controlled_beta_v1',
    consent_status='granted',
    consented_at=excluded.consented_at,
    grant_evidence_ref=excluded.grant_evidence_ref,
    revoked_at=null,
    revocation_evidence_ref=null,
    updated_at=now(),
    updated_by=auth.uid()
  returning id into v_id;

  return jsonb_build_object(
    'consent_id',v_id,
    'cohort_key',p_cohort_key,
    'user_id',p_user_id,
    'consent_status','granted',
    'feature_state','unchanged'
  );
end;
$$;
revoke all on function public.record_exam_prep_beta_consent_v1(text,uuid,text,timestamptz)
from public,anon,authenticated;
grant execute on function public.record_exam_prep_beta_consent_v1(text,uuid,text,timestamptz)
to service_role;

-- Revocation is fail-closed. Before the first live wave it reopens the roster as
-- DRAFT. Once any wave is live it invokes the existing emergency pause path so
-- all active entitlements are removed atomically while evidence is preserved.
create or replace function public.revoke_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_user_id uuid,
  p_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_pause jsonb;
begin
  if p_evidence_ref is null or char_length(trim(p_evidence_ref)) not between 5 and 500 then
    raise exception 'exam_prep_beta_revocation_evidence_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id
  for update;
  if v_m.id is null then
    raise exception 'exam_prep_beta_member_not_found' using errcode='P0002';
  end if;

  if not exists(
    select 1 from private.exam_prep_beta_consents c
    where c.cohort_id=v_c.id and c.user_id=p_user_id and c.consent_status='granted'
  ) then
    raise exception 'exam_prep_beta_consent_not_granted';
  end if;

  update private.exam_prep_beta_consents
  set consent_status='revoked',revoked_at=now(),revocation_evidence_ref=trim(p_evidence_ref),
      updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and user_id=p_user_id;

  if v_c.cohort_status in ('canary','active') then
    v_pause:=public.pause_exam_prep_controlled_beta_v1(
      p_cohort_key,
      'learner consent revoked; controlled beta paused fail-closed'
    );
  elsif v_c.cohort_status='approved' and v_c.current_wave=0 then
    -- Approval granted no learner access. Return all waiting members to candidate
    -- status so the roster can be repaired/re-consented without hidden access.
    update private.exam_prep_feature_config
    set rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,
        kill_switch=true,updated_at=now(),updated_by=auth.uid()
    where id=1;

    update private.exam_prep_feature_entitlements e
    set entitlement_status='paused',updated_at=now(),updated_by=auth.uid()
    where e.cohort_key=p_cohort_key and e.entitlement_status='active';

    update private.exam_prep_beta_members
    set member_status='candidate',activated_at=null,paused_at=null,
        updated_at=now(),updated_by=auth.uid()
    where cohort_id=v_c.id and member_status='approved';

    update private.exam_prep_beta_cohorts
    set cohort_status='draft',approved_at=null,updated_at=now(),updated_by=auth.uid()
    where id=v_c.id;
  end if;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'user_id',p_user_id,
    'consent_status','revoked',
    'cohort_status',(select cohort_status from private.exam_prep_beta_cohorts where id=v_c.id),
    'feature_state',(select rollout_state from private.exam_prep_feature_config where id=1),
    'kill_switch',(select kill_switch from private.exam_prep_feature_config where id=1),
    'pause_result',v_pause
  );
end;
$$;
revoke all on function public.revoke_exam_prep_beta_consent_v1(text,uuid,text)
from public,anon,authenticated;
grant execute on function public.revoke_exam_prep_beta_consent_v1(text,uuid,text)
to service_role;

create or replace function public.get_exam_prep_beta_consent_status_v1(p_cohort_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_members int;
  v_granted int;
  v_revoked int;
  v_missing int;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select count(*) into v_members
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status<>'removed';

  select count(*) filter(where c.consent_status='granted'),
         count(*) filter(where c.consent_status='revoked')
  into v_granted,v_revoked
  from private.exam_prep_beta_consents c
  join private.exam_prep_beta_members m
    on m.cohort_id=c.cohort_id and m.user_id=c.user_id
  where c.cohort_id=v_c.id and m.member_status<>'removed';

  v_missing:=v_members-v_granted-v_revoked;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'cohort_status',v_c.cohort_status,
    'members',v_members,
    'granted',v_granted,
    'revoked',v_revoked,
    'missing',v_missing,
    'consent_complete',(v_members>0 and v_granted=v_members and v_revoked=0)
  );
end;
$$;
revoke all on function public.get_exam_prep_beta_consent_status_v1(text)
from public,anon,authenticated;
grant execute on function public.get_exam_prep_beta_consent_status_v1(text)
to service_role;

-- Deployment invariants: adding consent governance must not open Exam Prep and
-- must not retroactively manufacture consent for any pre-existing draft member.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_fabricated int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P0-16 learner-consent gate requires fail-closed feature state';
  end if;

  select count(*) into v_fabricated
  from private.exam_prep_beta_consents;
  if v_fabricated<>0 then
    raise exception 'P0-16 learner-consent migration must not fabricate consent rows';
  end if;
end
$$;

commit;
