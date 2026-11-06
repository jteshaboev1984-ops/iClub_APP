-- D10-09: real Stage-0 diagnostic source-verified problem freshness.
-- Five exact-condition duplicates confirmed in the original P1 content.
-- Retests already prefer fresh variants (D10-08). This extends a SOFT
-- preference to Stage-0 existing 24/15 governed diagnostic package selection.
-- Does NOT change questions, answer keys, assessments, past attempts, mastery,
-- required item/area counts or current learner membership / stage.
-- DRAFT ONLY; no live migrations, cleanup or open rollout.
BEGIN;
DO $source_guard$
DECLARE v_source text;
BEGIN
 SELECT pg_get_functiondef('private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)'::regprocedure)
 INTO v_source;
 IF v_source IS NULL
   OR position('least(c.new_sections,r.remaining_areas)' in v_source)=0
   OR position('abs(c.total_items-greatest(r.remaining_items,1))' in v_source)=0
   OR to_regprocedure('private.exam_prep_canonical_prompt_v1(text)') IS NULL
   OR has_function_privilege('authenticated','private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)','EXECUTE')
   OR has_function_privilege('anon','private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)','EXECUTE')
 THEN RAISE EXCEPTION 'D10-09 refused: Stage0 selector source/ACL or D10-08 canonical helper drift'; END IF;
END $source_guard$;

create or replace function private.exam_prep_next_diagnostic_assessment_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns bigint
language sql
stable
security definer
set search_path=''
as $$
  with requirements as (
    select
      case when p_component_code='P1' then r.p1_broad_required_items else r.p5_broad_required_items end::int as required_items,
      case when p_component_code='P1' then r.p1_broad_required_areas else r.p5_broad_required_areas end::int as required_areas
    from private.exam_prep_placement_rule_versions r
    where r.program_version_id=p_program_version_id
      and r.status='active'
    order by r.activated_at desc nulls last,r.created_at desc
    limit 1
  ), answered as (
    select distinct si.question_id, n.official_syllabus_section
    from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s
      on s.id=e.session_id and s.user_id=p_user_id and s.status='finalized'
    join private.exam_prep_responses r
      on r.id=e.response_id and r.session_id=s.id and r.user_id=p_user_id
    join private.exam_prep_session_items si
      on si.session_id=s.id and si.item_order=r.item_order and si.question_id is not null
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=p_program_version_id
     and n.component_code=p_component_code
     and n.skill_code=e.skill_code
    where e.user_id=p_user_id
      and e.component_code=p_component_code
      and e.evidence_type='diagnostic'
  ), answered_summary as (
    select
      count(distinct a.question_id)::int as answered_items,
      count(distinct a.official_syllabus_section)::int as answered_areas
    from answered a
  ), remaining as (
    select
      greatest(req.required_items-coalesce(s.answered_items,0),0)::int as remaining_items,
      greatest(req.required_areas-coalesce(s.answered_areas,0),0)::int as remaining_areas
    from requirements req
    cross join answered_summary s
  ), seen_prompts as (
    -- Actual owner-specific previously delivered question conditions, including
    -- another question ID that is mathematically the same condition.
    select distinct private.exam_prep_canonical_prompt_v1(q.question_text_en) as prompt_norm
    from private.exam_prep_sessions s
    join private.exam_prep_session_items si on si.session_id=s.id and si.question_id is not null
    join public.questions q on q.id=si.question_id
    where s.user_id=p_user_id AND s.component_code=p_component_code
      and q.question_text_en is not null
  ), published_learning_prompts as (
    -- A supposedly withheld diagnostic should preferably NOT repeat an
    -- existing published learning condition with an available explanation.
    select distinct private.exam_prep_canonical_prompt_v1(q.question_text_en) as prompt_norm
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv
      on cv.id=m.content_version_id AND cv.program_version_id=p_program_version_id
    join public.questions q on q.id=m.question_id
    where m.reserve_role='learning'
      and m.lifecycle_state='published'
      and m.exposure_state='released'
      and q.question_text_en is not null
  ), candidates as (
    select
      a.id,
      count(*)::int as total_items,
      count(*) filter(where an.question_id is null)::int as unanswered_items,
      count(distinct private.exam_prep_canonical_prompt_v1(q.question_text_en))
        filter (where an.question_id is null
          and not exists(
            select 1 from seen_prompts seen
            where seen.prompt_norm=private.exam_prep_canonical_prompt_v1(q.question_text_en)
          )
        )::int as newly_deliverable_prompts,
      count(distinct private.exam_prep_canonical_prompt_v1(q.question_text_en))
        filter (where an.question_id is null
          and not exists(
            select 1 from published_learning_prompts learning
            where learning.prompt_norm=private.exam_prep_canonical_prompt_v1(q.question_text_en)
          )
        )::int as private_diagnostic_prompts,
      count(distinct private.exam_prep_canonical_prompt_v1(q.question_text_en))::int as distinct_prompts,
      count(distinct n.official_syllabus_section)
        filter(where not exists(
          select 1 from answered ax
          where ax.official_syllabus_section=n.official_syllabus_section
        ))::int as new_sections
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv
      on cv.id=a.content_version_id
     and cv.program_version_id=p_program_version_id
     and cv.component_code=p_component_code
     and cv.status='published'
    join private.exam_prep_assessment_items ai
      on ai.assessment_id=a.id
     and ai.question_id is not null
     and ai.reserve_role='diagnostic'
    left join public.questions q on q.id=ai.question_id
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=p_program_version_id
     and n.component_code=p_component_code
     and n.skill_code=ai.primary_skill_code
    left join answered an on an.question_id=ai.question_id
    where a.component_code=p_component_code
      and a.assessment_type='diagnostic'
      and a.status='published'
      and not exists(
        select 1 from private.exam_prep_assessment_items bad
        where bad.assessment_id=a.id
          and (bad.question_id is null or bad.reserve_role<>'diagnostic')
      )
    group by a.id
    having count(*) filter(where an.question_id is null)>0
  )
  select c.id
  from candidates c
  cross join remaining r
  order by
    least(c.new_sections,r.remaining_areas) desc,
    case when c.unanswered_items=c.total_items then 0 else 1 end,
    case when c.total_items<=greatest(r.remaining_items,1) then 0 else 1 end,
    abs(c.total_items-greatest(r.remaining_items,1)) asc,
    -- Only tie-break after the established official area/item/shape ranking:
    -- prefer actual new question conditions, then conditions not released in
    -- learning, then mathematically distinct items in the selected package.
    -- Soft preference; retain every historically authorized candidate.
    c.newly_deliverable_prompts desc,
    c.private_diagnostic_prompts desc,
    c.distinct_prompts desc,
    c.unanswered_items desc,
    c.id
  limit 1;
$$;


REVOKE ALL ON FUNCTION private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)
 TO service_role;

DO $postcheck$
BEGIN
 IF has_function_privilege('anon','private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)','EXECUTE')
 OR NOT has_function_privilege('service_role','private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)','EXECUTE')
 OR NOT EXISTS(
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='private' AND p.proname='exam_prep_next_diagnostic_assessment_v1'
    AND p.prosecdef AND p.provolatile='s'
 ) THEN RAISE EXCEPTION 'D10-09 private selector ACL/STABLE contract changed'; END IF;
END $postcheck$;
COMMIT;
