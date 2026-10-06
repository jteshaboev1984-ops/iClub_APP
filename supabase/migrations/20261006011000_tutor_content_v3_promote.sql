-- Atomically promote the fully staged Tutor v3 + atomic source v2 corpus.
-- Old v2/source-v1 rows are retired, never deleted.
-- No learner state/history tables are touched.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 active v2 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 staged v3 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and approval_status='draft' and not is_runtime_allowed
    and rights_status='original_iclub';
  if v<>243 then raise exception 'Tutor v3 promote expected 243 staged atomic sources, found %',v; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.source_version<>'p3_02_full_theory_pack_v2_atomic_2026_10_06'
      )
  ) then raise exception 'Tutor v3 promote source linkage mismatch'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and content_hash<>md5(concat_ws('||',
        content_version,title,main_explanation,simple_explanation,
        alternative_explanation,focus_explanation,source_card_key
      ))
  ) then raise exception 'Tutor v3 promote found stale Tutor hash'; end if;

  if exists(
    select 1 from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
      and content_hash<>encode(digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
  ) then raise exception 'Tutor v3 promote found stale source hash'; end if;
end
$pre$;

-- Switch Tutor runtime ownership first OFF on v2, then ON on v3 to satisfy the unique runtime index.
update private.exam_prep_ai_tutor_cards
set approval_status='retired',
    is_runtime_allowed=false,
    updated_at=now()
where content_version='tutor_v2_learner_first'
  and approval_status='approved'
  and is_runtime_allowed;

-- Retire exactly the source-v1 rows bound by the historical Tutor v2 corpus.
update private.exam_prep_ai_source_cards s
set approval_status='retired',
    is_runtime_allowed=false,
    updated_at=now()
where s.source_card_key in (
  select t.source_card_key
  from private.exam_prep_ai_tutor_cards t
  where t.content_version='tutor_v2_learner_first'
)
  and s.approval_status='approved'
  and s.is_runtime_allowed;

-- Activate the new atomic source layer.
update private.exam_prep_ai_source_cards
set approval_status='approved',
    is_runtime_allowed=true,
    approved_at=now(),
    approved_by=null,
    updated_at=now()
where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
  and approval_status='draft'
  and not is_runtime_allowed;

-- Activate Tutor v3.
update private.exam_prep_ai_tutor_cards
set approval_status='approved',
    is_runtime_allowed=true,
    approved_at=now(),
    approved_by=null,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and approval_status='draft'
  and not is_runtime_allowed;

do $post$
declare
  v integer;
  v_cov jsonb;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed and approved_at is not null;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 active v3 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='retired' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 retired v2 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 active atomic sources, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards s
  where s.source_card_key in (
    select t.source_card_key
    from private.exam_prep_ai_tutor_cards t
    where t.content_version='tutor_v2_learner_first'
  )
    and s.approval_status='retired'
    and not s.is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 promote expected 243 retired bound source-v1 rows, found %',v; end if;

  with expected as (
    select n.component_code,n.skill_code,l.locale
    from private.exam_prep_syllabus_nodes n
    join private.exam_prep_program_versions pv on pv.id=n.program_version_id
    cross join (values ('en'),('ru'),('uz')) l(locale)
    where pv.program_key='math_as_p1_p5'
      and pv.version_key='p1_p5_canonical_v1_0'
      and pv.status='active'
      and n.component_code in ('P1','P5')
  )
  select count(*) into v
  from expected e
  where public.get_exam_prep_ai_tutor_card_service_v1(
    e.component_code,e.skill_code,e.locale
  )->>'content_version'='tutor_v3_learner_first';

  if v<>243 then raise exception 'Tutor v3 promote service lookup did not resolve v3 for all 243 rows: %',v; end if;

  v_cov:=public.get_exam_prep_ai_tutor_card_coverage_service_v1();
  if coalesce((v_cov->>'expected')::integer,-1)<>243
     or coalesce((v_cov->>'ready')::integer,-1)<>243
     or coalesce((v_cov->>'missing')::integer,-1)<>0
     or coalesce((v_cov->>'p1_ready')::integer,-1)<>135
     or coalesce((v_cov->>'p5_ready')::integer,-1)<>108
  then raise exception 'Tutor v3 promote coverage mismatch: %',v_cov; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Tutor v3 promote active source linkage drift'; end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_ai_source_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_source_cards','SELECT')
  then raise exception 'Tutor v3 promote private storage privilege drift'; end if;

  if has_function_privilege(
       'authenticated',
       'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
       'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
       'EXECUTE'
     )
  then raise exception 'Tutor v3 promote Tutor service privilege drift'; end if;
end
$post$;

commit;
