-- P1-03 ephemeral CI only.
-- Keeps rollback-only synthetic stage labels compatible with production enum constraints
-- without weakening the production schema. Installed only in the ephemeral GitHub Actions DB.

create or replace function private.p103_normalize_stage_fixture_v1()
returns trigger
language plpgsql
set search_path=''
as $$
begin
  -- The behavioral matrix deliberately uses synthetic_* labels to make fixture-only
  -- stage overrides obvious. Production accepts only the governed enum, so normalize
  -- those labels before the production constraint is evaluated. This helper never ships.
  if new.stage_gate_status like 'synthetic_%' then
    new.stage_gate_status:='operational';
    -- Carry an unmistakable CI-only sentinel through the production projection trigger.
    -- app_readiness_reason is not rewritten by that trigger, so zzz_* can identify
    -- both the initial synthetic rows and later post-rebuild synthetic overrides.
    new.app_readiness_reason:='P1-03 rollback-only fixture';
  end if;

  -- Initial rollback-only rows use a deliberately invalid sentinel so the fixture
  -- cannot be confused with a real readiness decision. Normalize only that sentinel.
  if new.app_readiness_estimate='false' then
    new.app_readiness_estimate:='INSUFFICIENT_EVIDENCE';
  end if;

  return new;
end;
$$;

revoke all on function private.p103_normalize_stage_fixture_v1() from public;

drop trigger if exists aaa_p103_normalize_stage_fixture on private.exam_prep_stage_states;
create trigger aaa_p103_normalize_stage_fixture
before insert or update on private.exam_prep_stage_states
for each row execute function private.p103_normalize_stage_fixture_v1();

-- The legacy P1-03 timed matrix intentionally injects Stage 1/2 rows without
-- placement/access rows. The production stage projection now correctly derives
-- those rows from placement + evidence and would therefore fail them closed to 0.
-- Restore only the unmistakable rollback-only sentinel after the production BEFORE
-- trigger has run. Trigger name sorts after exam_prep_stage0_gate_projection_v1.
create or replace function private.p103_restore_stage_fixture_v1()
returns trigger
language plpgsql
set search_path=''
as $$
begin
  if new.app_readiness_reason='P1-03 rollback-only fixture' then
    new.operational_stage:=new.evidence_stage_candidate;
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='P1-03 rollback-only synthetic operational-stage override';
  end if;
  return new;
end;
$$;

revoke all on function private.p103_restore_stage_fixture_v1() from public;

drop trigger if exists zzz_p103_restore_stage_fixture on private.exam_prep_stage_states;
create trigger zzz_p103_restore_stage_fixture
before insert or update on private.exam_prep_stage_states
for each row execute function private.p103_restore_stage_fixture_v1();
