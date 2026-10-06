-- Emergency rollback for Tutor v3 audit repair.
-- Restores historical Tutor v2 + source-v1 runtime ownership without deleting v3 history.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 revert expected 243 active v3 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='retired' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 revert expected 243 retired v2 cards, found %',v; end if;
end
$pre$;

update private.exam_prep_ai_tutor_cards
set approval_status='retired',
    is_runtime_allowed=false,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and approval_status='approved'
  and is_runtime_allowed;

update private.exam_prep_ai_source_cards
set approval_status='retired',
    is_runtime_allowed=false,
    updated_at=now()
where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
  and approval_status='approved'
  and is_runtime_allowed;

update private.exam_prep_ai_source_cards s
set approval_status='approved',
    is_runtime_allowed=true,
    approved_at=coalesce(s.approved_at,now()),
    updated_at=now()
where s.source_card_key in (
  select t.source_card_key
  from private.exam_prep_ai_tutor_cards t
  where t.content_version='tutor_v2_learner_first'
)
  and s.approval_status='retired'
  and not s.is_runtime_allowed;

update private.exam_prep_ai_tutor_cards
set approval_status='approved',
    is_runtime_allowed=true,
    approved_at=coalesce(approved_at,now()),
    updated_at=now()
where content_version='tutor_v2_learner_first'
  and approval_status='retired'
  and not is_runtime_allowed;

do $post$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 revert failed to restore 243 v2 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='retired' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 revert failed to retire v3 cards, found %',v; end if;

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
  )->>'content_version'='tutor_v2_learner_first';

  if v<>243 then raise exception 'Tutor v3 revert service lookup did not restore v2: %',v; end if;
end
$post$;

commit;
