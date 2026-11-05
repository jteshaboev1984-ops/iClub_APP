-- D10-08: prevent avoidable repeat-answer retests in actual P1/P5.
-- We found five exact mathematical prompt collisions spanning published,
-- diagnostic, mixed, and retest contexts. Old IDs, keys, answers and all
-- existing learner sessions must remain forever unchanged.
-- This migration ONLY reorders existing eligible retest candidate assessments.
-- Never removes a candidate: when no unseen alternative remains, fall back
-- to existing behavior. No new study / progression / retest access gate.
-- Source: original service-only P2-19 selector, no API signature change.
-- DRAFT ONLY: do not apply to live Supabase without separate architect GO.
BEGIN;
-- Private deterministic math question fingerprint. Preserve all signs,
-- relations, constants, variables and operation order. The ONLY formatting
-- normalization is whitespace, lettercase, common glyph/superscript variants.
-- This deliberately does NOT equate algebraically similar but different tasks.
create or replace function private.exam_prep_canonical_prompt_v1(p_prompt text)
returns text language sql immutable strict
set search_path=''
as $normalize$
 select regexp_replace(lower(
   replace(replace(replace(replace(replace(replace(replace(replace(
      p_prompt,'²','^2'),'³','^3'),'⁴','^4'),'−','-'),
      '–','-'),'≤','<='),'≥','>='),'×','*')
 ),'[[:space:]]+','','g');
$normalize$;
revoke all on function private.exam_prep_canonical_prompt_v1(text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_canonical_prompt_v1(text)
  to service_role;


create or replace function private.exam_prep_select_fresh_retest_assessment_v1(
  p_user_id uuid,p_component_code text,p_skill_code text
)
returns bigint
language sql
stable
security definer
set search_path=''
as $$
  select a.id
  from private.exam_prep_assessments a
  join private.exam_prep_assessment_items ai
    on ai.assessment_id=a.id
   and ai.question_id is not null
   and ai.primary_skill_code=p_skill_code
   and ai.reserve_role='retest'
  join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id
   and m.content_version_id=a.content_version_id
   and m.primary_skill_code=ai.primary_skill_code
  join public.questions candidate on candidate.id=ai.question_id
  where p_user_id is not null
    and p_component_code in ('P1','P5')
    and p_skill_code like p_component_code||'-%'
    and a.component_code=p_component_code
    and a.assessment_type='retest'
    and a.status='published'
    and (select count(*) from private.exam_prep_assessment_items z where z.assessment_id=a.id)=1
    and m.reserve_role='retest'
    and m.lifecycle_state='reserve'
    and m.exposure_state='withheld'
    and m.qa_scope_status='pass'
    and m.qa_math_status='pass'
    and m.qa_language_status='pass'
    and m.qa_technical_status='pass'
    and not exists(
      select 1
      from private.exam_prep_sessions s
      join private.exam_prep_session_items si on si.session_id=s.id
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.session_type='retest'
        and si.question_id=ai.question_id
    )
    and not exists(
      select 1
      from private.exam_prep_session_authorizations sa
      where sa.user_id=p_user_id
        and sa.assessment_id=a.id
        and sa.purpose='retest'
        and sa.status='issued'
        and (sa.valid_until is null or sa.valid_until>now())
    )
  -- Prefer genuinely novel mathematical prompts, not merely another
  -- question ID with the exact same problem. SOFT PREFERENCE ONLY:
  -- retain every original candidate and fall back to earliest eligible ID
  -- if all alternatives repeat existing content (no new access blocker).
  order by
    case when exists(
      select 1
      from private.exam_prep_sessions seen
      join private.exam_prep_session_items shown on shown.session_id=seen.id
      join public.questions prior_q on prior_q.id=shown.question_id
      where seen.user_id=p_user_id
        and seen.component_code=p_component_code
        and shown.question_id<>ai.question_id
        and private.exam_prep_canonical_prompt_v1(prior_q.question_text_en)
          = private.exam_prep_canonical_prompt_v1(candidate.question_text_en)
    ) then 1 else 0 end,
    case when exists(
      select 1
      from private.exam_prep_question_content_meta released
      join public.questions released_q on released_q.id=released.question_id
      where released.primary_skill_code=ai.primary_skill_code
        and released.reserve_role='learning'
        and released.lifecycle_state='published'
        and released.exposure_state='released'
        and released.question_id<>ai.question_id
        and private.exam_prep_canonical_prompt_v1(released_q.question_text_en)
          = private.exam_prep_canonical_prompt_v1(candidate.question_text_en)
    ) then 1 else 0 end,
    a.id
  limit 1;
$$;
revoke all on function private.exam_prep_select_fresh_retest_assessment_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_select_fresh_retest_assessment_v1(uuid,text,text)
  to service_role;
COMMIT;
