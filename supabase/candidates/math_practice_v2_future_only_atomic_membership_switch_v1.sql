-- Mathematics Practice P1 future-only question replacement — definition only.
-- STAGED, NOT INSTALLED. Do not execute on a hosted database without owner's
-- separate approval. This script does not stage a question or publish anything
-- when applied; functions must be invoked explicitly by an authorized operator.
-- New question rows/meta and inactive memberships must be staged and QA-approved.
-- Old question rows, answers, in-progress sessions and version links are immutable.
-- No full Practice bank-generation increment for routine item fixes.
create or replace function private.math_practice_future_only_activate_v1(
  p_release text,
  p_pairs jsonb
) returns jsonb language plpgsql security definer
set search_path = pg_catalog,public,private,pg_temp as $function$
declare
  v_pair jsonb;
  v_old_id bigint;
  v_new_id bigint;
  v_count integer;
  v_subject_id bigint;
  v_old public.questions%rowtype;
  v_new public.questions%rowtype;
  v_old_meta private.practice_v2_question_meta%rowtype;
  v_new_meta private.practice_v2_question_meta%rowtype;
  v_old_pool public.practice_pool_questions%rowtype;
  v_new_pool public.practice_pool_questions%rowtype;
  v_rows integer := 0;
begin
  -- No caller-controlled SQL, dynamic table name or generation bump.
  if p_release is null or p_release not in ('math_p1_practice_v2_fix_20261120','math_p1_practice_v2_q400_q481_20261120','math_p1_practice_v2_q089_q202_q226_20261120','math_p1_practice_v2_pending10_20261120','math_p1_practice_v2_decimal8_20261121','math_p1_practice_v2_semantic2_20261121','math_p1_practice_v2_setrange1_20261121','math_p1_practice_v2_hard9_20261121') then
    raise exception 'unapproved_math_practice_patch_release';
  end if;
  if jsonb_typeof(p_pairs) is distinct from 'array'
     or jsonb_array_length(p_pairs) not between 1 and 81 then
    raise exception 'invalid_future_only_pair_count';
  end if;
  if p_release='math_p1_practice_v2_q400_q481_20261120' and (
    jsonb_array_length(p_pairs)<>2
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7884::bigint,7965::bigint]
  ) then raise exception 'q400_q481_only_release_scope'; end if;
  if p_release='math_p1_practice_v2_q089_q202_q226_20261120' and (
    jsonb_array_length(p_pairs)<>3
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7573::bigint,7686::bigint,7710::bigint]
  ) then raise exception 'q089_q202_q226_only_release_scope'; end if;
  if p_release='math_p1_practice_v2_pending10_20261120' and (
    jsonb_array_length(p_pairs)<>10
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7506::bigint,7573::bigint,7686::bigint,
        7710::bigint,7754::bigint,7761::bigint,7809::bigint,7835::bigint,
        7884::bigint,7965::bigint]
  ) then raise exception 'pending10_only_release_scope'; end if;
  if p_release='math_p1_practice_v2_decimal8_20261121' and (
    jsonb_array_length(p_pairs)<>8
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x) is distinct from array[7714::bigint,7727::bigint,7796::bigint,7818::bigint,7829::bigint,7838::bigint,7894::bigint,7900::bigint]
  ) then raise exception 'decimal8_exact_release_scope'; end if;
  if p_release='math_p1_practice_v2_semantic2_20261121' and (
    jsonb_array_length(p_pairs)<>2
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
       from jsonb_array_elements(p_pairs) x) is distinct from array[7553::bigint,7795::bigint]
  ) then raise exception 'semantic2_exact_release_scope'; end if;
  if p_release='math_p1_practice_v2_setrange1_20261121' and (
    jsonb_array_length(p_pairs)<>1
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x) is distinct from array[7554::bigint]
  ) then raise exception 'setrange1_exact_release_scope'; end if;
  if p_release='math_p1_practice_v2_hard9_20261121' and (
    jsonb_array_length(p_pairs)<>9
    or (select array_agg((x.value->>'old_id')::bigint
         order by (x.value->>'old_id')::bigint)
       from jsonb_array_elements(p_pairs) x)
       is distinct from array[7511::bigint,7585::bigint,7692::bigint,7723::bigint,
        7769::bigint,7823::bigint,7908::bigint,7974::bigint,10119::bigint]
  ) then raise exception 'hard9_exact_live_successor_scope'; end if;
  select s.id into v_subject_id from public.subjects s
  where s.subject_key='mathematics' and s.is_active is true;
  if v_subject_id is null then raise exception 'mathematics_subject_missing'; end if;

  -- Serialize with the original Mathematics bank release and other patch calls.
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_future_only_patch')::bigint);

  if (select count(*) from (
    select (x.value->>'old_id')::bigint old_id
    from jsonb_array_elements(p_pairs) x
  ) ids) <> (select count(distinct (x.value->>'old_id')::bigint)
               from jsonb_array_elements(p_pairs) x)
  or (select count(*) from (
    select (x.value->>'new_id')::bigint new_id
    from jsonb_array_elements(p_pairs) x
  ) ids) <> (select count(distinct (x.value->>'new_id')::bigint)
               from jsonb_array_elements(p_pairs) x) then
    raise exception 'duplicate_future_only_pair';
  end if;

  -- All changes are in this transaction. Any failing item rolls everything back.
  for v_pair in select value from jsonb_array_elements(p_pairs) loop
    if jsonb_typeof(v_pair) <> 'object'
       or not (v_pair ?& array['old_id','new_id','old_hash','new_hash'])
       or (select count(*) from jsonb_object_keys(v_pair))<>4
       or (v_pair->>'old_hash') !~ '^[a-f0-9]{64}$'
       or (v_pair->>'new_hash') !~ '^[a-f0-9]{64}$' then
      raise exception 'invalid_future_only_pair_payload';
    end if;
    v_old_id := (v_pair->>'old_id')::bigint;
    v_new_id := (v_pair->>'new_id')::bigint;
    if v_old_id=v_new_id then raise exception 'future_only_self_replacement'; end if;

    select * into v_old from public.questions q where q.id=v_old_id for update;
    select * into v_new from public.questions q where q.id=v_new_id for update;
    select * into v_old_meta from private.practice_v2_question_meta m
      where m.question_id=v_old_id for update;
    select * into v_new_meta from private.practice_v2_question_meta m
      where m.question_id=v_new_id for update;

    if v_old.id is null or v_new.id is null
       or v_old.subject_id<>v_subject_id or v_new.subject_id<>v_subject_id
       or v_old.is_active is not true or v_old.quality_status<>'published'
       or v_old_meta.question_id is null
       or v_old_meta.lifecycle_state<>'published'
       or v_old_meta.is_runtime_allowed is not true
       or (v_old_meta.release_version<>'math_p1_practice_v2_2026_10_07'
          and not (p_release='math_p1_practice_v2_hard9_20261121'
           and v_old_id=10119
           and v_old_meta.release_version='math_p1_practice_v2_pending10_20261120'))
       or v_old_meta.content_hash is distinct from (v_pair->>'old_hash')
       or v_new.is_active is not false or v_new.quality_status<>'draft'
       or v_new_meta.question_id is null
       or v_new_meta.lifecycle_state<>'approved'
       or v_new_meta.is_runtime_allowed is not false
       or v_new_meta.release_version<>p_release
       or v_new_meta.content_hash is distinct from (v_pair->>'new_hash')
       or v_old_meta.content_hash=v_new_meta.content_hash
       or v_old.qtype<>v_new.qtype
       or v_old_meta.practice_no<>v_new_meta.practice_no
       or v_old_meta.primary_skill_code<>v_new_meta.primary_skill_code
       or v_old.topic is distinct from v_new.topic
       or v_old.subtopic is distinct from v_new.subtopic
       or v_old_meta.question_role<>v_new_meta.question_role
       or v_new_meta.qa_math_status<>'passed'
       or v_new_meta.qa_language_status<>'passed'
       or v_new_meta.qa_technical_status<>'passed'
       or v_new_meta.qa_tour_separation_status<>'passed'
       or (p_release='math_p1_practice_v2_fix_20261120'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261120')
       or (p_release='math_p1_practice_v2_q400_q481_20261120'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261120Q400Q481')
       or (p_release='math_p1_practice_v2_q089_q202_q226_20261120'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261120Q089Q202Q226')
       or (p_release='math_p1_practice_v2_pending10_20261120'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261120PENDING10')
       or (p_release='math_p1_practice_v2_decimal8_20261121'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261121DEC8')
       or (p_release='math_p1_practice_v2_semantic2_20261121'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261121SEM2')
       or (p_release='math_p1_practice_v2_setrange1_20261121'
         and v_new_meta.content_key<>v_old_meta.content_key||'-V20261121SETRANGE1')
       or (p_release='math_p1_practice_v2_hard9_20261121'
          and v_new_meta.content_key<>v_old_meta.content_key||'-V20261121HARD9')
    then
      raise exception 'future_only_version_identity_or_hash_mismatch';
    end if;

    if exists(select 1 from public.tour_questions t where t.question_id in (v_old_id,v_new_id))
       or exists(select 1 from public.question_version_links l
                   where l.old_question_id=v_old_id and l.link_type='replacement')
       or exists(select 1 from public.question_version_links l
                   where l.new_question_id=v_new_id and l.link_type='replacement')
    then raise exception 'protected_tour_or_existing_version_link'; end if;

    select ppq.* into v_old_pool
    from public.practice_pool_questions ppq
      join public.practice_pools p on p.id=ppq.pool_id
    where ppq.question_id=v_old_id and ppq.is_active is true
      and p.is_active is true and p.subject_id=v_subject_id
      and p.tour_no=v_old_meta.practice_no for update of ppq;
    if not found then raise exception 'old_active_membership_missing'; end if;
    if (select count(*) from public.practice_pool_questions ppq
         join public.practice_pools p on p.id=ppq.pool_id
         where ppq.question_id=v_old_id and ppq.is_active is true
           and p.is_active is true)<>1 then
      raise exception 'old_membership_not_unique';
    end if;
    select ppq.* into v_new_pool
      from public.practice_pool_questions ppq
      where ppq.question_id=v_new_id and ppq.pool_id=v_old_pool.pool_id
        and ppq.is_active is false for update of ppq;
    if not found then raise exception 'new_staged_membership_missing'; end if;
    if v_old_pool.order_no<>v_new_pool.order_no
       or (select count(*) from public.practice_pool_questions ppq
            where ppq.question_id=v_new_id)<>1 then
      raise exception 'new_staged_membership_scope_or_order_mismatch';
    end if;
    -- No historical session/answer/attempt ID changes. q.is_active on old
    -- stays TRUE: both v5 submit RPCs require it for open sessions.
    update public.questions set is_active=true,quality_status='published'
    where id=v_new_id;
    update private.practice_v2_question_meta
      set lifecycle_state='published',is_runtime_allowed=true,
          published_at=coalesce(published_at,now()),updated_at=now()
    where question_id=v_new_id;
    update public.question_answer_diagnostics set quality_status='published'
    where question_id=v_new_id and quality_status='draft';

    -- Future selectors query ACTIVE membership; old sessions do not.
    update public.practice_pool_questions set is_active=false
      where id=v_old_pool.id;
    update public.practice_pool_questions set is_active=true
      where id=v_new_pool.id;

    insert into public.question_version_links(
      old_question_id,new_question_id,link_type,reason)
    values(v_old_id,v_new_id,'replacement',p_release);
    v_rows:=v_rows+1;
  end loop;
  if v_rows<>jsonb_array_length(p_pairs) then
    raise exception 'future_only_partial_switch';
  end if;
  return jsonb_build_object('ok',true,'replaced',v_rows,
    'history_deleted',false,'bank_generation_changed',false);
end $function$;

create or replace function private.math_practice_future_only_rollback_v1(
  p_release text, p_pairs jsonb
) returns jsonb language plpgsql security definer
set search_path = pg_catalog,public,private,pg_temp as $function$
declare
  v_pair jsonb;
  v_old_id bigint;
  v_new_id bigint;
  v_old_pool public.practice_pool_questions%rowtype;
  v_new_pool public.practice_pool_questions%rowtype;
  v_count integer := 0;
begin
  if p_release is null or p_release not in ('math_p1_practice_v2_fix_20261120','math_p1_practice_v2_q400_q481_20261120','math_p1_practice_v2_q089_q202_q226_20261120','math_p1_practice_v2_pending10_20261120','math_p1_practice_v2_decimal8_20261121','math_p1_practice_v2_semantic2_20261121','math_p1_practice_v2_setrange1_20261121','math_p1_practice_v2_hard9_20261121')
     or jsonb_typeof(p_pairs) is distinct from 'array'
     or jsonb_array_length(p_pairs) not between 1 and 81 then
    raise exception 'invalid_future_only_rollback_request';
  end if;
  if p_release='math_p1_practice_v2_q400_q481_20261120' and (
    jsonb_array_length(p_pairs)<>2
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7884::bigint,7965::bigint]
  ) then raise exception 'q400_q481_only_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_q089_q202_q226_20261120' and (
    jsonb_array_length(p_pairs)<>3
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7573::bigint,7686::bigint,7710::bigint]
  ) then raise exception 'q089_q202_q226_only_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_pending10_20261120' and (
    jsonb_array_length(p_pairs)<>10
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x)
       is distinct from array[7506::bigint,7573::bigint,7686::bigint,
        7710::bigint,7754::bigint,7761::bigint,7809::bigint,7835::bigint,
        7884::bigint,7965::bigint]
  ) then raise exception 'pending10_only_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_decimal8_20261121' and (
    jsonb_array_length(p_pairs)<>8
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x) is distinct from array[7714::bigint,7727::bigint,7796::bigint,7818::bigint,7829::bigint,7838::bigint,7894::bigint,7900::bigint]
  ) then raise exception 'decimal8_exact_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_semantic2_20261121' and (
    jsonb_array_length(p_pairs)<>2
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
       from jsonb_array_elements(p_pairs) x) is distinct from array[7553::bigint,7795::bigint]
  ) then raise exception 'semantic2_exact_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_setrange1_20261121' and (
    jsonb_array_length(p_pairs)<>1
    or (select array_agg((x.value->>'old_id')::bigint order by (x.value->>'old_id')::bigint)
        from jsonb_array_elements(p_pairs) x) is distinct from array[7554::bigint]
  ) then raise exception 'setrange1_exact_rollback_scope'; end if;
  if p_release='math_p1_practice_v2_hard9_20261121' and (
    jsonb_array_length(p_pairs)<>9
    or (select array_agg((x.value->>'old_id')::bigint
         order by (x.value->>'old_id')::bigint)
       from jsonb_array_elements(p_pairs) x)
       is distinct from array[7511::bigint,7585::bigint,7692::bigint,7723::bigint,
        7769::bigint,7823::bigint,7908::bigint,7974::bigint,10119::bigint]
  ) then raise exception 'hard9_exact_live_successor_scope'; end if;
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_future_only_patch')::bigint);
  if (select count(distinct (x.value->>'old_id')::bigint)
      from jsonb_array_elements(p_pairs) x)<>jsonb_array_length(p_pairs)
     or (select count(distinct (x.value->>'new_id')::bigint)
      from jsonb_array_elements(p_pairs) x)<>jsonb_array_length(p_pairs) then
    raise exception 'duplicate_future_only_rollback_pair';
  end if;

  for v_pair in select value from jsonb_array_elements(p_pairs) loop
    if jsonb_typeof(v_pair)<>'object'
       or not (v_pair ?& array['old_id','new_id','old_hash','new_hash'])
       or (select count(*) from jsonb_object_keys(v_pair))<>4 then
      raise exception 'invalid_rollback_payload';
    end if;
    v_old_id := (v_pair->>'old_id')::bigint;
    v_new_id := (v_pair->>'new_id')::bigint;
    if not exists (
      select 1 from public.question_version_links l
      where l.old_question_id=v_old_id and l.new_question_id=v_new_id
        and l.link_type='replacement' and l.reason=p_release
    ) then raise exception 'unpublished_version_pair_cannot_rollback'; end if;
    if not exists (
      select 1 from private.practice_v2_question_meta m
      join public.questions q on q.id=m.question_id
      where m.question_id=v_old_id
        and m.content_hash=v_pair->>'old_hash'
        and q.is_active is true and q.quality_status='published'
        and m.lifecycle_state='published' and m.is_runtime_allowed=true
    ) or not exists (
      select 1 from private.practice_v2_question_meta m
      join public.questions q on q.id=m.question_id
      where m.question_id=v_new_id and m.release_version=p_release
        and m.content_hash=v_pair->>'new_hash'
        and q.is_active is true and q.quality_status='published'
        and m.lifecycle_state='published' and m.is_runtime_allowed=true
    ) then raise exception 'rollback_historical_version_hash_drift'; end if;
    select ppq.* into v_new_pool
      from public.practice_pool_questions ppq
      join public.practice_pools p on p.id=ppq.pool_id
      where ppq.question_id=v_new_id and ppq.is_active is true
        and p.is_active is true and p.subject_id=5
      for update of ppq;
    if not found then raise exception 'rollback_current_new_membership_missing'; end if;
    select ppq.* into v_old_pool
      from public.practice_pool_questions ppq
      where ppq.question_id=v_old_id and ppq.pool_id=v_new_pool.pool_id
        and ppq.order_no=v_new_pool.order_no and ppq.is_active is false
      for update of ppq;
    if not found then raise exception 'rollback_old_membership_missing'; end if;
    if exists(select 1 from public.question_version_links l
       where l.old_question_id=v_new_id and l.link_type='replacement') then
      raise exception 'rollback_has_newer_version';
    end if;
    update public.practice_pool_questions set is_active=false
      where id=v_new_pool.id;
    update public.practice_pool_questions set is_active=true
      where id=v_old_pool.id;
    -- Do not mark new question inactive or delete its new answers: some
    -- in-progress post-cutover sessions may already reference it.
    v_count:=v_count+1;
  end loop;
  return jsonb_build_object('ok',true,'restored_old_memberships',v_count,
    'history_deleted',false,'bank_generation_changed',false);
end $function$;

revoke all on function private.math_practice_future_only_activate_v1(text,jsonb)
 from public,anon,authenticated;
revoke all on function private.math_practice_future_only_rollback_v1(text,jsonb)
 from public,anon,authenticated;
