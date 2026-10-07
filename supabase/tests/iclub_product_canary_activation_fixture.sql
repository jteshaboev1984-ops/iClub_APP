\set ON_ERROR_STOP on

-- Test-only minimum of the existing production Exam Prep beta authority tables
-- used by the product canary activation control.

create table if not exists private.exam_prep_beta_members (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  member_status text not null,
  service_mode text null,
  activation_wave smallint null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists exam_prep_beta_members_user_status_test_idx
  on private.exam_prep_beta_members(user_id,member_status);

create table if not exists private.exam_prep_feature_entitlements (
  user_id uuid primary key references public.users(id) on delete cascade,
  entitlement_status text not null,
  core_access boolean not null default false,
  ai_assist boolean not null default false,
  mentor_care_entitled boolean not null default false,
  cohort_key text null,
  valid_from timestamptz null,
  valid_until timestamptz null,
  updated_at timestamptz not null default now()
);

grant select,insert,update,delete on private.exam_prep_beta_members to service_role;
grant select,insert,update,delete on private.exam_prep_feature_entitlements to service_role;
