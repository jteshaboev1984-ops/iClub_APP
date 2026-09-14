begin;

-- P2-63: synthetic validation is now a permanent engineering track, but it must
-- never be confused with real beta learner evidence. This migration creates a
-- structural identity boundary before any new production-schema synthetic data
-- is generated.
--
-- Important distinction: synthetic LEARNER/OPERATIONAL evidence may never count
-- as real weekly/learner evidence. Explicit engineering validation artifacts
-- such as the existing 600/10 and service-transition matrices remain legitimate
-- engineering prerequisites where the release plan explicitly requires them.

create table if not exists private.exam_prep_synthetic_identities(
  user_id uuid primary key references auth.users(id) on delete restrict,
  identity_status text not null default 'active'
    check(identity_status in ('active','retired')),
  evidence_ref text not null
    check(char_length(trim(evidence_ref))>=8),
  purpose text not null
    check(char_length(trim(purpose))>=8),
  registered_at timestamptz not null default now(),
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(
    (identity_status='active' and retired_at is null)
    or (identity_status='retired' and retired_at is not null)
  )
);

alter table private.exam_prep_synthetic_identities enable row level security;
revoke all on table private.exam_prep_synthetic_identities from public,anon,authenticated;
grant select,insert,update on table private.exam_prep_synthetic_identities to service_role;

-- A synthetic identity must be a fresh dedicated test account, not an existing
-- learner account relabelled for convenience. We intentionally inspect every
-- private Exam Prep table with a user_id column so future learner-state tables
-- fail closed automatically until reviewed.
create or replace function private.exam_prep_synthetic_identity_preflight_v1(p_user_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_table record;
  v_count bigint:=0;
  v_private_rows bigint:=0;
  v_practice_attempts bigint:=0;
  v_tour_attempts bigint:=0;
  v_certificates bigint:=0;
  v_auth_exists boolean:=false;
  v_email_ok boolean:=false;
begin
  if p_user_id is null then
    return jsonb_build_object(
      'eligible',false,
      'reason_code','user_id_required',
      'private_exam_prep_rows',0,
      'practice_attempts',0,
      'tour_attempts',0,
      'certificates',0,
      'synthetic_email_pattern_ok',false
    );
  end if;

  select
    count(*)=1,
    coalesce(bool_or(email like 'exam-prep-sv-%@invalid.example'),false)
  into v_auth_exists,v_email_ok
  from auth.users
  where id=p_user_id;

  for v_table in
    select distinct c.table_name
    from information_schema.columns c
    where c.table_schema='private'
      and c.column_name='user_id'
      and c.table_name like 'exam_prep_%'
      and c.table_name<>'exam_prep_synthetic_identities'
    order by c.table_name
  loop
    execute format(
      'select count(*) from private.%I where user_id=$1',
      v_table.table_name
    ) into v_count using p_user_id;
    v_private_rows:=v_private_rows+coalesce(v_count,0);
  end loop;

  if to_regclass('public.practice_attempts') is not null then
    select count(*) into v_practice_attempts
    from public.practice_attempts
    where user_id=p_user_id;
  end if;

  if to_regclass('public.tour_attempts') is not null then
    select count(*) into v_tour_attempts
    from public.tour_attempts
    where user_id=p_user_id;
  end if;

  if to_regclass('public.certificates') is not null then
    select count(*) into v_certificates
    from public.certificates
    where user_id=p_user_id;
  end if;

  return jsonb_build_object(
    'eligible',
      v_auth_exists
      and v_email_ok
      and v_private_rows=0
      and v_practice_attempts=0
      and v_tour_attempts=0
      and v_certificates=0,
    'reason_code',case
      when not v_auth_exists then 'auth_user_missing'
      when not v_email_ok then 'synthetic_email_pattern_required'
      when v_private_rows<>0 then 'preexisting_exam_prep_state'
      when v_practice_attempts<>0 or v_tour_attempts<>0 or v_certificates<>0 then 'preexisting_legacy_state'
      else 'eligible'
    end,
    'private_exam_prep_rows',v_private_rows,
    'practice_attempts',v_practice_attempts,
    'tour_attempts',v_tour_attempts,
    'certificates',v_certificates,
    'synthetic_email_pattern_ok',v_email_ok
  );
end;
$$;

revoke all on function private.exam_prep_synthetic_identity_preflight_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_identity_preflight_v1(uuid) to service_role;

create or replace function private.is_exam_prep_synthetic_identity_v1(p_user_id uuid)
returns boolean
language sql
stable security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_synthetic_identities s
    where s.user_id=p_user_id
  );
$$;

revoke all on function private.is_exam_prep_synthetic_identity_v1(uuid) from public,anon,authenticated;
grant execute on function private.is_exam_prep_synthetic_identity_v1(uuid) to service_role;

-- Registration is one-way. A retired synthetic identity remains synthetic and
-- can never later be recycled into a real learner identity.
create or replace function private.enforce_exam_prep_synthetic_identity_registration_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_preflight jsonb;
begin
  if tg_op='INSERT' then
    if new.identity_status<>'active' or new.retired_at is not null then
      raise exception 'exam_prep_synthetic_identity_must_register_active';
    end if;

    v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(new.user_id);
    if coalesce((v_preflight->>'eligible')::boolean,false) is not true then
      raise exception 'exam_prep_synthetic_identity_preflight_failed: %',v_preflight->>'reason_code';
    end if;

    new.evidence_ref:=trim(new.evidence_ref);
    new.purpose:=trim(new.purpose);
    new.registered_at:=coalesce(new.registered_at,now());
    new.created_at:=coalesce(new.created_at,now());
    new.updated_at:=now();
    return new;
  end if;

  if new.user_id is distinct from old.user_id
     or new.evidence_ref is distinct from old.evidence_ref
     or new.purpose is distinct from old.purpose
     or new.registered_at is distinct from old.registered_at
     or new.created_at is distinct from old.created_at then
    raise exception 'exam_prep_synthetic_identity_provenance_immutable';
  end if;

  if old.identity_status='retired' and new.identity_status<>'retired' then
    raise exception 'exam_prep_synthetic_identity_cannot_reactivate';
  end if;

  if new.identity_status='retired' and new.retired_at is null then
    new.retired_at:=now();
  elsif new.identity_status='active' and new.retired_at is not null then
    raise exception 'exam_prep_active_synthetic_identity_cannot_have_retired_at';
  end if;

  new.updated_at:=now();
  return new;
end;
$$;

revoke all on function private.enforce_exam_prep_synthetic_identity_registration_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_identity_registration_guard_v1
  on private.exam_prep_synthetic_identities;
create trigger exam_prep_synthetic_identity_registration_guard_v1
before insert or update on private.exam_prep_synthetic_identities
for each row execute function private.enforce_exam_prep_synthetic_identity_registration_v1();

-- Once a user is classified synthetic, real-beta control surfaces refuse that
-- user. Synthetic harness access may later use dedicated synthetic mechanisms,
-- but never a real beta membership/consent or a real beta cohort entitlement.
create or replace function private.enforce_exam_prep_real_beta_identity_firewall_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_user_id uuid;
  v_cohort_key text;
begin
  v_user_id:=nullif(to_jsonb(new)->>'user_id','')::uuid;
  if v_user_id is null
     or not private.is_exam_prep_synthetic_identity_v1(v_user_id) then
    return new;
  end if;

  if tg_table_name='exam_prep_feature_entitlements' then
    v_cohort_key:=nullif(to_jsonb(new)->>'cohort_key','');
    if v_cohort_key is null
       or not exists(
         select 1
         from private.exam_prep_beta_cohorts c
         where c.cohort_key=v_cohort_key
       ) then
      return new;
    end if;
  end if;

  raise exception 'exam_prep_synthetic_identity_forbidden_in_real_beta_control: %',tg_table_name;
end;
$$;

revoke all on function private.enforce_exam_prep_real_beta_identity_firewall_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_beta_members_synthetic_firewall_v1
  on private.exam_prep_beta_members;
create trigger exam_prep_beta_members_synthetic_firewall_v1
before insert or update on private.exam_prep_beta_members
for each row execute function private.enforce_exam_prep_real_beta_identity_firewall_v1();

drop trigger if exists exam_prep_beta_consents_synthetic_firewall_v1
  on private.exam_prep_beta_consents;
create trigger exam_prep_beta_consents_synthetic_firewall_v1
before insert or update on private.exam_prep_beta_consents
for each row execute function private.enforce_exam_prep_real_beta_identity_firewall_v1();

drop trigger if exists exam_prep_feature_entitlements_synthetic_firewall_v1
  on private.exam_prep_feature_entitlements;
create trigger exam_prep_feature_entitlements_synthetic_firewall_v1
before insert or update on private.exam_prep_feature_entitlements
for each row execute function private.enforce_exam_prep_real_beta_identity_firewall_v1();

-- Defense-in-depth report. It returns counts only, never learner identifiers.
create or replace function private.exam_prep_synthetic_real_boundary_report_v1()
returns jsonb
language sql
stable security definer
set search_path=''
as $$
  with counts as (
    select
      (select count(*) from private.exam_prep_synthetic_identities)::int as synthetic_identities,
      (
        select count(*)
        from private.exam_prep_beta_members bm
        join private.exam_prep_synthetic_identities s on s.user_id=bm.user_id
      )::int as beta_member_overlap,
      (
        select count(*)
        from private.exam_prep_beta_consents bc
        join private.exam_prep_synthetic_identities s on s.user_id=bc.user_id
      )::int as beta_consent_overlap,
      (
        select count(*)
        from private.exam_prep_feature_entitlements e
        join private.exam_prep_synthetic_identities s on s.user_id=e.user_id
        join private.exam_prep_beta_cohorts c on c.cohort_key=e.cohort_key
      )::int as beta_entitlement_overlap
  )
  select jsonb_build_object(
    'synthetic_identities',synthetic_identities,
    'beta_member_overlap',beta_member_overlap,
    'beta_consent_overlap',beta_consent_overlap,
    'beta_entitlement_overlap',beta_entitlement_overlap,
    'eligible',beta_member_overlap=0 and beta_consent_overlap=0 and beta_entitlement_overlap=0
  )
  from counts;
$$;

revoke all on function private.exam_prep_synthetic_real_boundary_report_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_real_boundary_report_v1() to service_role;

-- Existing real-beta rows must already be clean. This is a migration-time
-- assertion and therefore fails closed if a future replay introduces overlap.
do $$
declare
  v_report jsonb;
begin
  v_report:=private.exam_prep_synthetic_real_boundary_report_v1();
  if coalesce((v_report->>'eligible')::boolean,false) is not true then
    raise exception 'exam_prep_synthetic_real_boundary_overlap_detected: %',v_report;
  end if;
end;
$$;

commit;
