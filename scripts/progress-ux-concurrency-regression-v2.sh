#!/usr/bin/env bash
set -euo pipefail

if [[ "${PGOPTIONS:-}" != *"progress_ux.isolated_db=true"* ]]; then
  echo "PROGRESS UX CONCURRENCY REFUSED: isolated database required" >&2
  exit 2
fi

uid="$(psql -Atqc "select gen_random_uuid()")"
email="px-concurrency-${uid}@invalid.example"

psql -v ON_ERROR_STOP=1 -v uid="$uid" -v email="$email" <<'SQL'
insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
values(:'uid'::uuid,'authenticated','authenticated',:'email',now(),now(),false,false);
insert into public.users(id,first_name,created_at,must_change_password)
values(:'uid'::uuid,'ProgressUXConcurrencyV2',now(),false);
insert into private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
values(:'uid'::uuid,'active',true);
update private.exam_prep_feature_config
set rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
where program_key='math_as_p1_p5';
with p as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and status='active' order by id desc limit 1
)
insert into private.exam_prep_exam_profiles
(user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
select :'uid'::uuid,id,'May/June 2027','A',12,6,1 from p;
with profile as (
  select program_version_id from private.exam_prep_exam_profiles where user_id=:'uid'::uuid
), plan as (
  insert into private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  select :'uid'::uuid,program_version_id,'P1',1,1,'active','Progress UX concurrency week 1'
  from profile returning id
)
insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code)
select id,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE' from plan
union all select id,2,'learning','P1-QUA-02','BUILD_FIRST_COVERAGE' from plan
union all select id,3,'learning','P1-QUA-03','BUILD_FIRST_COVERAGE' from plan;
SQL

run_ensure() {
  psql -v ON_ERROR_STOP=1 -Atqc "select set_config('request.jwt.claim.sub', '$uid', false); select set_config('request.jwt.claim.role','authenticated',false); select public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created';"
}
export -f run_ensure
export PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE PGOPTIONS uid

pids=()
for _ in 1 2 3 4 5 6; do (run_ensure >/dev/null) & pids+=("$!"); done
for pid in "${pids[@]}"; do wait "$pid"; done

count="$(psql -Atqc "select count(*) from private.exam_prep_weekly_goal_snapshots where user_id='$uid'::uuid and component_code='P1' and active_week_no=1")"
[[ "$count" == "3" ]] || { echo "Expected 3 week-1 goals, got $count" >&2; exit 1; }
week1_ids="$(psql -Atqc "select string_agg(id::text,',' order by priority_order) from private.exam_prep_weekly_goal_snapshots where user_id='$uid'::uuid and component_code='P1' and active_week_no=1")"

psql -v ON_ERROR_STOP=1 -v uid="$uid" <<'SQL'
update private.exam_prep_weekly_plans set status='superseded'
where user_id=:'uid'::uuid and component_code='P1' and active_week_no=1 and status='active';
with profile as (
  select program_version_id from private.exam_prep_exam_profiles where user_id=:'uid'::uuid
), plan as (
  insert into private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  select :'uid'::uuid,program_version_id,'P1',1,2,'active','Progress UX concurrent replan'
  from profile returning id
)
insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code)
select id,1,'learning','P1-QUA-03','BUILD_FIRST_COVERAGE' from plan
union all select id,2,'learning','P1-QUA-02','BUILD_FIRST_COVERAGE' from plan
union all select id,3,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE' from plan;
SQL
pids=()
for _ in 1 2 3 4; do (run_ensure >/dev/null) & pids+=("$!"); done
for pid in "${pids[@]}"; do wait "$pid"; done
week1_after="$(psql -Atqc "select string_agg(id::text,',' order by priority_order) from private.exam_prep_weekly_goal_snapshots where user_id='$uid'::uuid and component_code='P1' and active_week_no=1")"
[[ "$week1_after" == "$week1_ids" ]] || { echo "Same-week replan changed frozen goal identities" >&2; exit 1; }

psql -v ON_ERROR_STOP=1 -v uid="$uid" <<'SQL'
update private.exam_prep_exam_profiles set active_week_no=2 where user_id=:'uid'::uuid;
update private.exam_prep_weekly_plans set status='superseded'
where user_id=:'uid'::uuid and component_code='P1' and status='active';
insert into private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
values(:'uid'::uuid,'P1','P1-QUA-01','remediating'),(:'uid'::uuid,'P1','P1-QUA-02','remediating');
with profile as (
  select program_version_id from private.exam_prep_exam_profiles where user_id=:'uid'::uuid
), plan as (
  insert into private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  select :'uid'::uuid,program_version_id,'P1',2,1,'active','Progress UX concurrency week 2'
  from profile returning id
)
insert into private.exam_prep_weekly_plan_items
(plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
select id,1,'correction','P1-QUA-01',
  (select c.id from private.exam_prep_correction_cases c where c.user_id=:'uid'::uuid and c.skill_code='P1-QUA-01' order by c.opened_at desc limit 1),
  'COMPLETE_CORRECTION_ANALOGUES' from plan
union all
select id,2,'correction','P1-QUA-02',
  (select c.id from private.exam_prep_correction_cases c where c.user_id=:'uid'::uuid and c.skill_code='P1-QUA-02' order by c.opened_at desc limit 1),
  'COMPLETE_CORRECTION_ANALOGUES' from plan;
SQL
pids=()
for _ in 1 2 3 4 5; do (run_ensure >/dev/null) & pids+=("$!"); done
for pid in "${pids[@]}"; do wait "$pid"; done

week2_count="$(psql -Atqc "select count(*) from private.exam_prep_weekly_goal_snapshots where user_id='$uid'::uuid and component_code='P1' and active_week_no=2")"
[[ "$week2_count" == "2" ]] || { echo "Expected 2 week-2 goals, got $week2_count" >&2; exit 1; }
week1_count="$(psql -Atqc "select count(*) from private.exam_prep_weekly_goal_snapshots where user_id='$uid'::uuid and component_code='P1' and active_week_no=1")"
[[ "$week1_count" == "3" ]] || { echo "Week rollover damaged week-1 history" >&2; exit 1; }

projection="$(psql -Atqc "select set_config('request.jwt.claim.sub', '$uid', false); select set_config('request.jwt.claim.role','authenticated',false); select (public.get_exam_prep_weekly_progress_safe_v1('P1')->>'active_week_no')||'|'||(public.get_exam_prep_weekly_progress_safe_v1('P1')->>'plan_available')||'|'||jsonb_array_length(public.get_exam_prep_weekly_progress_safe_v1('P1')->'goals');" | tail -n 1)"
[[ "$projection" == "2|true|2" ]] || { echo "Week-2 projection incorrect: $projection" >&2; exit 1; }

psql -v ON_ERROR_STOP=1 -c "update private.exam_prep_feature_config set rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,kill_switch=true,updated_at=now() where program_key='math_as_p1_p5'" >/dev/null

echo 'Progress UX concurrency PASS: simultaneous first-open is idempotent, same-week replan preserves frozen goals, and rollover creates a new denominator without damaging week-1 history'
