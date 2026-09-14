begin;

-- P2-70: three early P5 retest assessment items predate the later holdout
-- convention. Their governed content metadata is already reserve+withheld, but
-- the assessment-item snapshot source still says is_holdout=false. Align only
-- those three source rows. Historical learner/session snapshots are immutable.

do $$
declare
  v_target_count integer;
  v_snapshot_count integer;
begin
  select count(*) into v_target_count
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where a.assessment_key in ('p5_dat01_retest','p5_dat04_retest','p5_dat06_retest')
    and a.component_code='P5'
    and a.assessment_type='retest'
    and a.status='published'
    and ai.reserve_role='retest'
    and ai.question_id is not null
    and ai.is_holdout=false;

  if v_target_count<>3 then
    raise exception 'P2-70 protected retest holdout target drift: expected 3, found %',v_target_count;
  end if;

  select count(*) into v_snapshot_count
  from private.exam_prep_session_items si
  where si.is_holdout=false
    and exists(
      select 1
      from private.exam_prep_assessment_items ai
      join private.exam_prep_assessments a on a.id=ai.assessment_id
      where a.assessment_key in ('p5_dat01_retest','p5_dat04_retest','p5_dat06_retest')
        and ai.question_id=si.question_id
    );

  if v_snapshot_count<>0 then
    raise exception 'P2-70 REFUSED: affected non-holdout session snapshots already exist rows=%',v_snapshot_count;
  end if;
end
$$;

update private.exam_prep_assessment_items ai
set is_holdout=true
from private.exam_prep_assessments a
where a.id=ai.assessment_id
  and a.assessment_key in ('p5_dat01_retest','p5_dat04_retest','p5_dat06_retest')
  and a.component_code='P5'
  and a.assessment_type='retest'
  and a.status='published'
  and ai.reserve_role='retest'
  and ai.question_id is not null
  and ai.is_holdout=false;

do $$
declare
  v_bad integer;
begin
  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where a.assessment_key in ('p5_dat01_retest','p5_dat04_retest','p5_dat06_retest')
    and ai.reserve_role='retest'
    and ai.question_id is not null
    and ai.is_holdout=false;

  if v_bad<>0 then
    raise exception 'P2-70 protected retest holdout alignment incomplete rows=%',v_bad;
  end if;
end
$$;

commit;
