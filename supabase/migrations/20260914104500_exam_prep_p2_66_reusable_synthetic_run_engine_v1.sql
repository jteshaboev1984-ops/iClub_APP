begin;

-- P2-66: reusable Seed -> Run -> Audit -> Cleanup engine.
-- Synthetic validation remains fully separate from the real beta track.
-- Cleanup is run-scoped, fail-closed on legacy/control contamination and
-- preserves the immutable run/event history plus one cleanup summary audit.

create or replace function private.exam_prep_synthetic_run_legacy_refs_v1(p_run_id text)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_users uuid[];
  v_fk record;
  v_count bigint;
  v_total bigint:=0;
  v_counts jsonb:='{}'::jsonb;
begin
  select array_agg(user_id order by user_id) into v_users
  from private.exam_prep_synthetic_identities
  where run_id=p_run_id;

  if not exists(select 1 from private.exam_prep_synthetic_validation_runs where run_id=p_run_id) then
    raise exception 'exam_prep_synthetic_run_not_found';
  end if;

  if coalesce(array_length(v_users,1),0)=0 then
    return jsonb_build_object('total_refs',0,'counts','{}'::jsonb);
  end if;

  for v_fk in
    select n.nspname as child_schema, cl.relname as child_table, a.attname as child_column
    from pg_constraint c
    join pg_class cl on cl.oid=c.conrelid
    join pg_namespace n on n.oid=cl.relnamespace
    join pg_class rcl on rcl.oid=c.confrelid
    join pg_namespace rn on rn.oid=rcl.relnamespace
    join unnest(c.conkey) with ordinality ck(attnum,ord) on true
    join unnest(c.confkey) with ordinality fk(attnum,ord) on fk.ord=ck.ord
    join pg_attribute a on a.attrelid=c.conrelid and a.attnum=ck.attnum
    join pg_attribute ra on ra.attrelid=c.confrelid and ra.attnum=fk.attnum
    where c.contype='f'
      and rn.nspname='public' and rcl.relname='users' and ra.attname='id'
      and n.nspname='public' and cl.relname<>'users'
    order by cl.relname,a.attname
  loop
    execute format('select count(*) from %I.%I where %I=any($1)',
      v_fk.child_schema,v_fk.child_table,v_fk.child_column)
      into v_count using v_users;
    if coalesce(v_count,0)>0 then
      v_counts:=v_counts || jsonb_build_object(v_fk.child_table||'.'||v_fk.child_column,v_count);
      v_total:=v_total+v_count;
    end if;
  end loop;

  return jsonb_build_object('total_refs',v_total,'counts',v_counts);
end;
$$;
revoke all on function private.exam_prep_synthetic_run_legacy_refs_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_run_legacy_refs_v1(text) to service_role;

create or replace function private.exam_prep_synthetic_run_inventory_v1(p_run_id text)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_users uuid[];
  v_identity_count int:=0;
  v_private_refs bigint:=0;
  v_fk record;
  v_count bigint;
  v_private_counts jsonb:='{}'::jsonb;
  v_legacy jsonb;
  v_boundary jsonb;
  v_isolation jsonb;
  v_protected int:=0;
  v_mixed int:=0;
begin
  select * into v_run from private.exam_prep_synthetic_validation_runs where run_id=p_run_id;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;

  select array_agg(user_id order by user_id),count(*)::int
  into v_users,v_identity_count
  from private.exam_prep_synthetic_identities
  where run_id=p_run_id;

  if v_identity_count>0 then
    for v_fk in
      select n.nspname as child_schema, cl.relname as child_table, a.attname as child_column
      from pg_constraint c
      join pg_class cl on cl.oid=c.conrelid
      join pg_namespace n on n.oid=cl.relnamespace
      join pg_class rcl on rcl.oid=c.confrelid
      join pg_namespace rn on rn.oid=rcl.relnamespace
      join unnest(c.conkey) with ordinality ck(attnum,ord) on true
      join unnest(c.confkey) with ordinality fk(attnum,ord) on fk.ord=ck.ord
      join pg_attribute a on a.attrelid=c.conrelid and a.attnum=ck.attnum
      join pg_attribute ra on ra.attrelid=c.confrelid and ra.attnum=fk.attnum
      where c.contype='f'
        and rn.nspname='public' and rcl.relname='users' and ra.attname='id'
        and n.nspname='private' and cl.relname like 'exam_prep_%'
      order by cl.relname,a.attname
    loop
      execute format('select count(*) from %I.%I where %I=any($1)',
        v_fk.child_schema,v_fk.child_table,v_fk.child_column)
        into v_count using v_users;
      if coalesce(v_count,0)>0 then
        v_private_counts:=v_private_counts || jsonb_build_object(v_fk.child_table||'.'||v_fk.child_column,v_count);
        v_private_refs:=v_private_refs+v_count;
      end if;
    end loop;

    select
      (select count(*) from private.exam_prep_beta_members where user_id=any(v_users))+
      (select count(*) from private.exam_prep_beta_consents where user_id=any(v_users))+
      (select count(*) from private.exam_prep_beta_weekly_reviews where reviewer_user_id=any(v_users))+
      (select count(*) from private.exam_prep_staff_roles where user_id=any(v_users))+
      (select count(*) from private.exam_prep_feature_entitlements e
        where e.user_id=any(v_users) and e.cohort_key is not null
          and exists(select 1 from private.exam_prep_beta_cohorts c where c.cohort_key=e.cohort_key))
    into v_protected;

    select
      (select count(*) from private.exam_prep_mentor_assignments a
        where (a.learner_user_id=any(v_users)) is distinct from (a.mentor_user_id=any(v_users)))+
      (select count(*) from private.exam_prep_mentor_queue_items q
        where (q.learner_user_id=any(v_users)) is distinct from (q.mentor_user_id=any(v_users)))+
      (select count(*) from private.exam_prep_mentor_reviews r
        where (r.learner_user_id=any(v_users)) is distinct from (r.mentor_user_id=any(v_users)))+
      (select count(*) from private.exam_prep_readiness_signoffs s
        where (s.learner_user_id=any(v_users))
          and ((s.mentor_user_id is not null and not s.mentor_user_id=any(v_users))
            or (s.moderator_user_id is not null and not s.moderator_user_id=any(v_users))))+
      (select count(*) from private.exam_prep_safeguarding_events s
        where (s.learner_user_id=any(v_users)) is distinct from (s.raised_by_user_id=any(v_users)))+
      (select count(*) from private.exam_prep_mentor_second_checks sc
        join private.exam_prep_mentor_reviews r on r.id=sc.review_id
        where (r.learner_user_id=any(v_users) or r.mentor_user_id=any(v_users) or sc.reviewer_user_id=any(v_users))
          and not (r.learner_user_id=any(v_users) and r.mentor_user_id=any(v_users) and sc.reviewer_user_id=any(v_users)))
    into v_mixed;
  end if;

  v_legacy:=private.exam_prep_synthetic_run_legacy_refs_v1(p_run_id);
  v_boundary:=private.exam_prep_synthetic_real_boundary_report_v1();
  v_isolation:=private.exam_prep_synthetic_identity_isolation_report_v1();

  return jsonb_build_object(
    'run_id',v_run.run_id,
    'run_status',v_run.run_status,
    'cleanup_status',v_run.cleanup_status,
    'identity_count',v_identity_count,
    'auth_users',(select count(*) from auth.users u where v_users is not null and u.id=any(v_users)),
    'public_users',(select count(*) from public.users u where v_users is not null and u.id=any(v_users)),
    'private_user_reference_cells',v_private_refs,
    'private_reference_counts',v_private_counts,
    'legacy_refs',v_legacy,
    'protected_control_refs',v_protected,
    'mixed_real_synthetic_edges',v_mixed,
    'real_boundary',v_boundary,
    'identity_isolation',v_isolation,
    'clean_boundary',
      coalesce((v_legacy->>'total_refs')::bigint,0)=0
      and v_protected=0
      and v_mixed=0
      and coalesce((v_boundary->>'eligible')::boolean,false)
      and coalesce((v_isolation->>'eligible')::boolean,false)
  );
end;
$$;
revoke all on function private.exam_prep_synthetic_run_inventory_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_run_inventory_v1(text) to service_role;

create or replace function private.create_exam_prep_synthetic_identity_v1(
  p_run_id text,
  p_identity_kind text,
  p_fixture_profile_key text,
  p_evidence_ref text,
  p_purpose text,
  p_locale text default 'en'
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_user uuid:=gen_random_uuid();
  v_email text;
  v_locale text:=lower(coalesce(nullif(trim(p_locale),''),'en'));
begin
  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;
  if v_run.run_status not in ('registered','running') or v_run.cleanup_status<>'not_started' then
    raise exception 'exam_prep_synthetic_identity_run_not_open_for_fixture_registration';
  end if;
  if p_identity_kind not in ('learner','mentor') then raise exception 'exam_prep_synthetic_identity_kind_invalid'; end if;
  if v_locale not in ('en','ru','uz') then raise exception 'exam_prep_synthetic_locale_invalid'; end if;
  if p_fixture_profile_key is null or trim(p_fixture_profile_key)!~'^SVF-[A-Z0-9][A-Z0-9-]{3,63}$' then
    raise exception 'exam_prep_synthetic_fixture_profile_key_invalid';
  end if;

  v_email:='exam-prep-sv-'||substr(md5(p_run_id||v_user::text),1,12)||'-'||replace(v_user::text,'-','')||'@invalid.example';

  insert into auth.users(
    id,aud,role,email,encrypted_password,email_confirmed_at,banned_until,
    raw_app_meta_data,raw_user_meta_data,created_at,updated_at,is_sso_user,is_anonymous
  ) values(
    v_user,'authenticated','authenticated',v_email,null,null,'infinity'::timestamptz,
    jsonb_build_object('provider','synthetic_validation','providers',jsonb_build_array()),
    jsonb_build_object('synthetic_validation',true,'run_id',p_run_id,'fixture_profile_key',trim(p_fixture_profile_key)),
    now(),now(),false,false
  );

  insert into public.users(id,first_name,last_name,language_code,created_at,auth_email,must_change_password)
  values(
    v_user,
    case when p_identity_kind='mentor' then 'SV Mentor' else 'SV Learner' end,
    trim(p_fixture_profile_key),v_locale,now(),v_email,false
  );

  insert into private.exam_prep_synthetic_identities(
    user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
  ) values(
    v_user,p_run_id,p_identity_kind,trim(p_fixture_profile_key),'active',trim(p_evidence_ref),trim(p_purpose)
  );

  return v_user;
end;
$$;
revoke all on function private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text) to service_role;

create or replace function private.complete_exam_prep_synthetic_run_v1(
  p_run_id text,
  p_expected_identity_count integer,
  p_details jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_inventory jsonb;
begin
  if p_expected_identity_count is null or p_expected_identity_count<0 then
    raise exception 'exam_prep_synthetic_expected_identity_count_invalid';
  end if;
  if p_details is null or jsonb_typeof(p_details)<>'object' then
    raise exception 'exam_prep_synthetic_run_details_invalid';
  end if;

  select * into v_run from private.exam_prep_synthetic_validation_runs where run_id=p_run_id for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;
  if v_run.run_status<>'running' then raise exception 'exam_prep_synthetic_run_not_running'; end if;

  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(p_run_id);
  if coalesce((v_inventory->>'identity_count')::int,-1)<>p_expected_identity_count then
    raise exception 'exam_prep_synthetic_identity_count_mismatch expected=% actual=%',
      p_expected_identity_count,v_inventory->>'identity_count';
  end if;
  if coalesce((v_inventory->>'clean_boundary')::boolean,false) is not true then
    raise exception 'exam_prep_synthetic_run_boundary_not_clean: %',v_inventory;
  end if;

  return private.transition_exam_prep_synthetic_validation_run_v1(
    p_run_id,'running','completed',
    jsonb_build_object('p2_66_inventory',v_inventory,'result','green'),null,
    p_details || jsonb_build_object('p2_66_audit','green')
  );
end;
$$;
revoke all on function private.complete_exam_prep_synthetic_run_v1(text,integer,jsonb) from public,anon,authenticated;
grant execute on function private.complete_exam_prep_synthetic_run_v1(text,integer,jsonb) to service_role;

create or replace function private.cleanup_exam_prep_synthetic_run_v1(
  p_run_id text,
  p_expected_identity_count integer,
  p_cleanup_evidence_ref text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_inventory jsonb;
  v_users uuid[];
  v_identity_count int:=0;
  v_legacy_before jsonb;
  v_legacy_after jsonb;
  v_controls_before jsonb;
  v_controls_after jsonb;
  v_real_users_before bigint;
  v_real_users_after bigint;
  v_summary_count int;
  v_prev_cleanup_marker text:=current_setting('iclub.exam_prep_synthetic_cleanup',true);
begin
  if p_acknowledgement is distinct from 'I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1' then
    raise exception 'exam_prep_synthetic_run_cleanup_acknowledgement_required';
  end if;
  if p_expected_identity_count is null or p_expected_identity_count<0 then
    raise exception 'exam_prep_synthetic_expected_identity_count_invalid';
  end if;
  if p_cleanup_evidence_ref is null or char_length(trim(p_cleanup_evidence_ref))<8 then
    raise exception 'exam_prep_synthetic_cleanup_evidence_ref_required';
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;

  if v_run.cleanup_status='clean' then
    select count(*) into v_summary_count
    from private.exam_prep_audit_events
    where event_type='synthetic_validation_run_cleaned'
      and object_type='private.exam_prep_synthetic_validation_runs'
      and object_id=p_run_id;
    return jsonb_build_object(
      'run_id',p_run_id,'cleanup_status','clean','idempotent',true,
      'summary_audit_events',v_summary_count
    );
  end if;

  if v_run.run_status not in ('completed','failed','aborted') then
    raise exception 'exam_prep_synthetic_cleanup_requires_terminal_run';
  end if;

  select array_agg(user_id order by user_id),count(*)::int into v_users,v_identity_count
  from private.exam_prep_synthetic_identities
  where run_id=p_run_id;
  if v_identity_count<>p_expected_identity_count then
    raise exception 'exam_prep_synthetic_identity_count_mismatch expected=% actual=%',p_expected_identity_count,v_identity_count;
  end if;

  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(p_run_id);
  if coalesce((v_inventory->>'clean_boundary')::boolean,false) is not true then
    raise exception 'exam_prep_synthetic_cleanup_boundary_not_clean: %',v_inventory;
  end if;

  v_legacy_before:=private.exam_prep_synthetic_run_legacy_refs_v1(p_run_id);
  if coalesce((v_legacy_before->>'total_refs')::bigint,0)<>0 then
    raise exception 'exam_prep_synthetic_cleanup_legacy_reference_present: %',v_legacy_before;
  end if;

  select jsonb_build_object(
    'beta_members',(select count(*) from private.exam_prep_beta_members),
    'beta_consents',(select count(*) from private.exam_prep_beta_consents),
    'beta_weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews),
    'real_beta_entitlements',(select count(*) from private.exam_prep_feature_entitlements e
      where e.cohort_key is not null and exists(select 1 from private.exam_prep_beta_cohorts c where c.cohort_key=e.cohort_key)),
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates)
  ) into v_controls_before;

  select count(*) into v_real_users_before
  from public.users
  where v_users is null or not id=any(v_users);

  if v_run.cleanup_status='not_started' then
    perform private.transition_exam_prep_synthetic_cleanup_v1(
      p_run_id,'not_started','pending',jsonb_build_object('p2_66','cleanup-queued','evidence_ref',trim(p_cleanup_evidence_ref))
    );
    v_run.cleanup_status:='pending';
  elsif v_run.cleanup_status='failed' then
    perform private.transition_exam_prep_synthetic_cleanup_v1(
      p_run_id,'failed','pending',jsonb_build_object('p2_66','cleanup-retry','evidence_ref',trim(p_cleanup_evidence_ref))
    );
    v_run.cleanup_status:='pending';
  end if;

  if v_run.cleanup_status='pending' then
    perform private.transition_exam_prep_synthetic_cleanup_v1(
      p_run_id,'pending','running',jsonb_build_object('p2_66','cleanup-started','identity_count',v_identity_count)
    );
  elsif v_run.cleanup_status<>'running' then
    raise exception 'exam_prep_synthetic_cleanup_state_not_resumable=%',v_run.cleanup_status;
  end if;

  perform set_config('iclub.exam_prep_synthetic_cleanup','on',true);

  if coalesce(array_length(v_users,1),0)>0 then
    -- Restrict/no-action human-review edges are removed explicitly before the
    -- synthetic public-user rows. The inventory already rejected any edge that
    -- crosses from this run into a real or different-run identity.
    delete from private.exam_prep_mentor_second_checks sc
    where sc.reviewer_user_id=any(v_users)
       or exists(select 1 from private.exam_prep_mentor_reviews r where r.id=sc.review_id and (r.learner_user_id=any(v_users) or r.mentor_user_id=any(v_users)))
       or exists(select 1 from private.exam_prep_mentor_queue_items q where q.id=sc.queue_item_id and (q.learner_user_id=any(v_users) or q.mentor_user_id=any(v_users)));

    delete from private.exam_prep_readiness_signoffs
    where learner_user_id=any(v_users) or mentor_user_id=any(v_users) or moderator_user_id=any(v_users);
    delete from private.exam_prep_mentor_reviews
    where learner_user_id=any(v_users) or mentor_user_id=any(v_users);
    delete from private.exam_prep_mentor_queue_items
    where learner_user_id=any(v_users) or mentor_user_id=any(v_users);
    delete from private.exam_prep_safeguarding_events
    where learner_user_id=any(v_users) or raised_by_user_id=any(v_users);
    delete from private.exam_prep_mentor_assignments
    where learner_user_id=any(v_users) or mentor_user_id=any(v_users);

    -- SET NULL would otherwise leave synthetic AI audit residue.
    delete from private.exam_prep_ai_audit where user_id=any(v_users);

    -- Per-row operational audit entries are synthetic residue. The immutable
    -- run event ledger plus the summary event below preserve the run history.
    delete from private.exam_prep_audit_events
    where actor_user_id=any(v_users) or target_user_id=any(v_users);

    -- This is safe only because legacy/live public references were proven zero.
    delete from public.users where id=any(v_users);

    delete from private.exam_prep_synthetic_identities where run_id=p_run_id;
    delete from auth.users where id=any(v_users);
  end if;

  if v_prev_cleanup_marker is null then
    perform set_config('iclub.exam_prep_synthetic_cleanup','',true);
  else
    perform set_config('iclub.exam_prep_synthetic_cleanup',v_prev_cleanup_marker,true);
  end if;

  if coalesce(array_length(v_users,1),0)>0 then
    if exists(select 1 from public.users where id=any(v_users))
       or exists(select 1 from auth.users where id=any(v_users))
       or exists(select 1 from private.exam_prep_synthetic_identities where user_id=any(v_users))
       or exists(select 1 from private.exam_prep_audit_events where actor_user_id=any(v_users) or target_user_id=any(v_users)) then
      raise exception 'exam_prep_synthetic_cleanup_residue_after_identity_delete';
    end if;
  end if;

  select jsonb_build_object(
    'beta_members',(select count(*) from private.exam_prep_beta_members),
    'beta_consents',(select count(*) from private.exam_prep_beta_consents),
    'beta_weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews),
    'real_beta_entitlements',(select count(*) from private.exam_prep_feature_entitlements e
      where e.cohort_key is not null and exists(select 1 from private.exam_prep_beta_cohorts c where c.cohort_key=e.cohort_key)),
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates)
  ) into v_controls_after;

  if v_controls_after<>v_controls_before then
    raise exception 'exam_prep_synthetic_cleanup_protected_state_changed before=% after=%',v_controls_before,v_controls_after;
  end if;

  select count(*) into v_real_users_after from public.users;
  if v_real_users_after<>v_real_users_before then
    raise exception 'exam_prep_synthetic_cleanup_real_user_count_changed before=% after=%',v_real_users_before,v_real_users_after;
  end if;

  if coalesce((private.exam_prep_synthetic_real_boundary_report_v1()->>'eligible')::boolean,false) is not true
     or coalesce((private.exam_prep_synthetic_identity_isolation_report_v1()->>'eligible')::boolean,false) is not true then
    raise exception 'exam_prep_synthetic_cleanup_post_boundary_not_clean';
  end if;

  perform private.transition_exam_prep_synthetic_cleanup_v1(
    p_run_id,'running','clean',jsonb_build_object(
      'p2_66','cleanup-clean',
      'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
      'deleted_identity_count',v_identity_count,
      'preserved_state',v_controls_after
    )
  );

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',null,'service_role','synthetic_validation_run_cleaned',
    'private.exam_prep_synthetic_validation_runs',p_run_id,
    jsonb_build_object(
      'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
      'deleted_identity_count',v_identity_count,
      'pre_cleanup_inventory',v_inventory,
      'preserved_state',v_controls_after,
      'idempotent',false
    )
  );

  select count(*) into v_summary_count
  from private.exam_prep_audit_events
  where event_type='synthetic_validation_run_cleaned'
    and object_type='private.exam_prep_synthetic_validation_runs'
    and object_id=p_run_id;
  if v_summary_count<>1 then
    raise exception 'exam_prep_synthetic_cleanup_summary_event_count_invalid=%',v_summary_count;
  end if;

  return jsonb_build_object(
    'run_id',p_run_id,
    'cleanup_status','clean',
    'idempotent',false,
    'deleted_identity_count',v_identity_count,
    'summary_audit_events',v_summary_count,
    'preserved_state',v_controls_after
  );
exception
  when others then
    begin
      if v_prev_cleanup_marker is null then
        perform set_config('iclub.exam_prep_synthetic_cleanup','',true);
      else
        perform set_config('iclub.exam_prep_synthetic_cleanup',v_prev_cleanup_marker,true);
      end if;
    exception when others then null; end;
    raise;
end;
$$;
revoke all on function private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text) from public,anon,authenticated;
grant execute on function private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text) to service_role;

-- Browser roles must never gain direct access to this engineering harness.
do $$
begin
  if has_function_privilege('anon','private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text)','EXECUTE')
     or has_function_privilege('anon','private.complete_exam_prep_synthetic_run_v1(text,integer,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','private.complete_exam_prep_synthetic_run_v1(text,integer,jsonb)','EXECUTE')
     or has_function_privilege('anon','private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text)','EXECUTE') then
    raise exception 'exam_prep_p2_66_browser_harness_execute_exposed';
  end if;
end;
$$;

commit;
