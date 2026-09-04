-- P1-02 QA + publication gate for P1-FUN-03/04/05 AW9-12 pack.
-- Publishes governed Exam Prep memberships only; legacy public.questions stay draft + inactive.

begin;
do $$ declare v_id bigint; v_skill text; v_bad int; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p1_aw09_12_functions_v1' and component_code='P1' and status='draft';
  if v_id is null then raise exception 'P1-02 AW9-12 functions QA: draft content version missing'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id)<>21 then raise exception 'P1-02 AW9-12 functions QA: expected 21 question objects'; end if;
  foreach v_skill in array array['P1-FUN-03','P1-FUN-04','P1-FUN-05'] loop
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='diagnostic')<>1 then raise exception 'P1-02 AW9-12 functions QA: % diagnostic floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='learning')<>3 then raise exception 'P1-02 AW9-12 functions QA: % learning floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='retest')<>2 then raise exception 'P1-02 AW9-12 functions QA: % retest floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='mixed')<>1 then raise exception 'P1-02 AW9-12 functions QA: % mixed floor',v_skill; end if;
    if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id and primary_skill_code=v_skill and lifecycle_state='approved')<>1 then raise exception 'P1-02 AW9-12 functions QA: % written floor',v_skill; end if;
  end loop;
  select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=v_id and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.options_text_en),'') is null or nullif(trim(q.options_text_ru),'') is null or nullif(trim(q.options_text_uz),'') is null
    or jsonb_typeof(q.options_text_en::jsonb)<>'array' or jsonb_array_length(q.options_text_en::jsonb)<>4
    or jsonb_typeof(q.options_text_ru::jsonb)<>'array' or jsonb_array_length(q.options_text_ru::jsonb)<>4
    or jsonb_typeof(q.options_text_uz::jsonb)<>'array' or jsonb_array_length(q.options_text_uz::jsonb)<>4
    or q.correct_answer not in ('A','B','C','D')
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
  );
  if v_bad<>0 then raise exception 'P1-02 AW9-12 functions QA: % payload/isolation/snapshot failures',v_bad; end if;
  select count(*) into v_bad from (
    select m.id from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where m.content_version_id=v_id and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 AW9-12 functions QA: diagnostic rule contract failed for % items',v_bad; end if;
  select count(*) into v_bad from private.exam_prep_assessment_items i join private.exam_prep_assessments a on a.id=i.assessment_id where a.content_version_id=v_id and a.assessment_type in ('diagnostic','retest','mixed') and not i.is_holdout;
  if v_bad<>0 then raise exception 'P1-02 AW9-12 functions QA: % reserve items not holdout',v_bad; end if;
  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then raise exception 'P1-02 AW9-12 functions QA: expected three isolated R02 holdouts'; end if;
end $$;

update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,lifecycle_state='approved',approved_at=now(),updated_at=now()
from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p1_aw09_12_functions_v1' and cv.status='draft';
update private.exam_prep_content_versions set status='approved',approved_at=now() where content_version='p1_aw09_12_functions_v1' and status='draft';
update private.exam_prep_question_content_meta m set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,published_at=case when reserve_role='learning' then now() else null end,updated_at=now() from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p1_aw09_12_functions_v1' and cv.status='approved';
update private.exam_prep_written_tasks w set lifecycle_state='published' from private.exam_prep_content_versions cv where cv.id=w.content_version_id and cv.content_version='p1_aw09_12_functions_v1' and cv.status='approved' and w.lifecycle_state='approved';
update private.exam_prep_assessments a set status='published',approved_at=coalesce(a.approved_at,now()) from private.exam_prep_content_versions cv where cv.id=a.content_version_id and cv.content_version='p1_aw09_12_functions_v1' and cv.status='approved' and a.status='approved';
update private.exam_prep_content_versions set status='published',published_at=now() where content_version='p1_aw09_12_functions_v1' and status='approved';

do $$ declare v_program bigint; v_skill text; v_p1_ready int; v_p5_ready int; v_r1 jsonb; v_r9 jsonb; v_cfg private.exam_prep_feature_config%rowtype; v_active int; begin
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  foreach v_skill in array array['P1-FUN-03','P1-FUN-04','P1-FUN-05'] loop if not private.exam_prep_skill_content_ready_v1(v_program,'P1',v_skill) then raise exception 'P1-02 AW9-12 functions final: skill not ready %',v_skill; end if; end loop;
  select count(*) into v_p1_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P1' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P1',rs.skill_code);
  select count(*) into v_p5_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P5' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P5',rs.skill_code);
  if v_p1_ready<>6 or v_p5_ready<>0 then raise exception 'P1-02 AW9-12 functions final: expected AW9 readiness P1=6 P5=0, got P1=% P5=%',v_p1_ready,v_p5_ready; end if;
  v_r1:=public.get_exam_prep_content_runway_v1(1::smallint); if coalesce((v_r1->>'hard_floor_green')::boolean,false) is not true or coalesce((v_r1->>'target_4w_green')::boolean,false) is not true or (v_r1#>>'{components,P1,ready_through_aw}')::int<>8 or (v_r1#>>'{components,P5,ready_through_aw}')::int<>8 then raise exception 'P1-02 AW9-12 functions final: AW1-8 runway regressed: %',v_r1::text; end if;
  v_r9:=public.get_exam_prep_content_runway_v1(9::smallint); if coalesce((v_r9->>'hard_floor_green')::boolean,false) or coalesce((v_r9->>'target_4w_green')::boolean,false) then raise exception 'P1-02 AW9-12 functions final: AW9 must remain RED until full release ready: %',v_r9::text; end if;
  select * into v_cfg from private.exam_prep_feature_config where id=1; if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-02 AW9-12 functions final: feature escaped fail-closed'; end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active'; if v_active<>0 then raise exception 'P1-02 AW9-12 functions final: active entitlement residue=%',v_active; end if;
end $$;
commit;