-- Final P1-02 release-safety baseline for the controlled-beta line.
-- This migration is assertion-only: it creates no learner access and mutates no content.
-- It intentionally gives all Exam Prep CI gates one common source SHA after the
-- learner-consent governance overlay and workflow sequencing changes.

begin;

do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_runway jsonb;
  v_p5_status text;
  v_active_entitlements integer;
begin
  select * into v_cfg
  from private.exam_prep_feature_config
  where id=1;

  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'Exam Prep release-safety baseline requires fail-closed feature state';
  end if;

  select count(*) into v_active_entitlements
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active_entitlements<>0 then
    raise exception 'Exam Prep release-safety baseline found active entitlements=%',v_active_entitlements;
  end if;

  select status into v_p5_status
  from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1'
    and component_code='P5';
  if v_p5_status is distinct from 'published' then
    raise exception 'Exam Prep release-safety baseline expected published P5 E2 content, got %',v_p5_status;
  end if;

  v_runway:=public.get_exam_prep_content_runway_v1(5::smallint);
  if coalesce((v_runway->>'hard_floor_green')::boolean,false) is not true
     or coalesce((v_runway->>'target_4w_green')::boolean,false) is not true
     or coalesce((v_runway#>>'{components,P1,target_4w_green}')::boolean,false) is not true
     or coalesce((v_runway#>>'{components,P5,target_4w_green}')::boolean,false) is not true then
    raise exception 'Exam Prep release-safety baseline runway is not GREEN: %',v_runway;
  end if;
end
$$;

commit;
