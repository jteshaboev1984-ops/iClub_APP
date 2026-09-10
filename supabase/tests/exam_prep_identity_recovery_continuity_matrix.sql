-- Exam Prep identity recovery continuity matrix.
-- Rollback-only proof: Telegram/auth recovery re-keys Exam Prep identity without
-- recalculating academic state, merging histories, or weakening immutable facts.
\set ON_ERROR_STOP on

begin;

create temp table ep_identity_fixture(
  old_uid uuid primary key,
  new_uid uuid not null,
  telegram_id text not null unique
) on commit drop;

insert into ep_identity_fixture values (
  gen_random_uuid(),
  gen_random_uuid(),
  'ep-id-recovery-' || replace(gen_random_uuid()::text, '-', '')
);

insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
select old_uid,'authenticated','authenticated','ep-id-old-'||replace(old_uid::text,'-','')||'@invalid.example',now(),now(),false,false
from ep_identity_fixture
union all
select new_uid,'authenticated','authenticated','ep-id-new-'||replace(new_uid::text,'-','')||'@invalid.example',now(),now(),false,false
from ep_identity_fixture;

insert into public.users(id,telegram_user_id,first_name,last_name,language_code,created_at,must_change_password)
select old_uid,telegram_id,'EP Identity','Old','en',now(),false from ep_identity_fixture
union all
select new_uid,null,'EP Identity','New','en',now(),false from ep_identity_fixture;

do $$
declare
  v_old uuid;
  v_new uuid;
  v_program bigint;
  v_engine text;
  v_skill text;
  v_stage_before jsonb;
  v_stage_after jsonb;
  v_result jsonb;
  v_blocked boolean;
begin
  select old_uid,new_uid into v_old,v_new from ep_identity_fixture;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and status='active'
  order by id desc limit 1;

  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by activated_at desc nulls last,created_at desc
  limit 1;

  select skill_code into v_skill
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program and component_code='P1'
  order by skill_code limit 1;

  if v_program is null or v_engine is null or v_skill is null then
    raise exception 'Exam Prep identity recovery fixture prerequisites are missing';
  end if;

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
  ) values(v_old,'active',true,false,false,now());

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
    mathematics_hours_budget,active_week_no,profile_revision,paper_comparability_epoch
  ) values(v_old,v_program,'9709 synthetic continuity','A',10,4,3,7,2);

  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version
  ) values(v_old,v_program,'P1',v_skill,v_engine);

  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,
    denominator_count,l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,
    app_readiness_reason
  ) values(
    v_old,v_program,'P1',v_engine,
    45,45,0,0,0,0,0,
    'Synthetic value; normal stage triggers may replace this on insert.'
  );

  select to_jsonb(s)-'user_id' into v_stage_before
  from private.exam_prep_stage_states s
  where s.user_id=v_old and s.program_version_id=v_program and s.component_code='P1' and s.engine_version=v_engine;

  if not private.exam_prep_user_has_identity_refs_v1(v_old) then
    raise exception 'Old synthetic user should have Exam Prep identity references';
  end if;
  if private.exam_prep_user_has_identity_refs_v1(v_new) then
    raise exception 'New synthetic user must start clean';
  end if;

  -- The active guard must be callable by normal roles because it is used in trigger WHEN clauses,
  -- while mutation helpers remain private.
  if not has_function_privilege('authenticated','private.exam_prep_identity_rekey_active_v1()','EXECUTE') then
    raise exception 'Authenticated role cannot evaluate safe identity-rekey trigger guard';
  end if;
  if has_function_privilege('authenticated','private.exam_prep_rekey_user_identity_v1(uuid,uuid)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_user_has_identity_refs_v1(uuid)','EXECUTE') then
    raise exception 'Identity mutation helpers are exposed to authenticated';
  end if;

  -- Prove immutable facts still reject ordinary mutation, allow only old->new identity under
  -- the trusted context, and still reject payload changes even while that context is active.
  create temp table ep_immutable_probe(
    id integer primary key,
    user_id uuid not null references public.users(id),
    payload text not null
  ) on commit drop;
  create trigger ep_immutable_probe_guard
    before update or delete on ep_immutable_probe
    for each row execute function private.exam_prep_block_immutable_mutation_v1();
  insert into ep_immutable_probe values(1,v_old,'keep-exactly');

  v_blocked:=false;
  begin
    update ep_immutable_probe set payload='must-fail' where id=1;
  exception when others then
    if position('immutable_exam_prep_fact' in sqlerrm)>0 then v_blocked:=true; else raise; end if;
  end;
  if not v_blocked then raise exception 'Ordinary immutable mutation was accepted'; end if;

  perform set_config('iclub.exam_prep_identity_rekey','v1',true);
  perform set_config('iclub.exam_prep_identity_rekey_old_uid',v_old::text,true);
  perform set_config('iclub.exam_prep_identity_rekey_new_uid',v_new::text,true);
  update ep_immutable_probe set user_id=v_new where id=1;

  v_blocked:=false;
  begin
    update ep_immutable_probe set payload='must-still-fail' where id=1;
  exception when others then
    if position('immutable_exam_prep_fact' in sqlerrm)>0 then v_blocked:=true; else raise; end if;
  end;
  if not v_blocked then raise exception 'Trusted context accepted a non-identity immutable mutation'; end if;
  perform set_config('iclub.exam_prep_identity_rekey','off',true);
  perform set_config('iclub.exam_prep_identity_rekey_old_uid','',true);
  perform set_config('iclub.exam_prep_identity_rekey_new_uid','',true);

  select public.recover_telegram_user_identity(new_uid,telegram_id)
    into v_result
  from ep_identity_fixture;

  if coalesce((v_result->>'ok')::boolean,false) is distinct from true
     or v_result->>'reason'<>'recovered' then
    raise exception 'Synthetic recovery failed: %',v_result;
  end if;

  if coalesce((v_result->'moved'->'exam_prep'->>'total_identity_refs_moved')::integer,0) < 4 then
    raise exception 'Synthetic recovery did not report expected Exam Prep identity moves: %',v_result;
  end if;

  if private.exam_prep_user_has_identity_refs_v1(v_old) then
    raise exception 'Old UUID still owns Exam Prep identity references after recovery';
  end if;
  if not private.exam_prep_user_has_identity_refs_v1(v_new) then
    raise exception 'New UUID did not receive Exam Prep identity references';
  end if;

  if exists(select 1 from private.exam_prep_exam_profiles where user_id=v_old)
     or exists(select 1 from private.exam_prep_feature_entitlements where user_id=v_old)
     or exists(select 1 from private.exam_prep_skill_states where user_id=v_old)
     or exists(select 1 from private.exam_prep_stage_states where user_id=v_old) then
    raise exception 'Old UUID retained core Exam Prep rows';
  end if;

  if (select count(*) from private.exam_prep_exam_profiles where user_id=v_new)<>1
     or (select count(*) from private.exam_prep_feature_entitlements where user_id=v_new)<>1
     or (select count(*) from private.exam_prep_skill_states where user_id=v_new)<>1
     or (select count(*) from private.exam_prep_stage_states where user_id=v_new)<>1 then
    raise exception 'New UUID missing one or more core Exam Prep rows';
  end if;

  select to_jsonb(s)-'user_id' into v_stage_after
  from private.exam_prep_stage_states s
  where s.user_id=v_new and s.program_version_id=v_program and s.component_code='P1' and s.engine_version=v_engine;

  if v_stage_after is distinct from v_stage_before then
    raise exception 'Stage state was recalculated during identity recovery. before=% after=%',v_stage_before,v_stage_after;
  end if;

  if private.exam_prep_identity_rekey_active_v1() then
    raise exception 'Identity re-key context leaked after recovery';
  end if;

  if exists(select 1 from public.users where id=v_old) then
    raise exception 'Old public.users row should be removed after successful recovery';
  end if;
  if not exists(select 1 from auth.users where id=v_old) then
    raise exception 'Old auth.users row must remain under the existing recovery contract';
  end if;
end
$$;

rollback;

do $$
begin
  if exists(select 1 from auth.users where email like 'ep-id-%@invalid.example') then
    raise exception 'Synthetic auth residue found after rollback';
  end if;
  if exists(select 1 from public.users where first_name='EP Identity') then
    raise exception 'Synthetic public.users residue found after rollback';
  end if;
end
$$;

\echo 'Exam Prep identity recovery continuity matrix: GREEN'
