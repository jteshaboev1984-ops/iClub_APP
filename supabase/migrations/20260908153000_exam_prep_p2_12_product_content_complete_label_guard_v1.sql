-- P2-12 / Annual Roadmap C23: Product readiness label governance.
-- Product Content-Complete is a product/content milestone only. It must never be named AS READY or Exam Ready.
-- Learner Exam Ready remains a separate learner evidence state and is not changed by this migration.
begin;

-- Fail before adding the constraint if production already contains a conflicting live label.
do $$
begin
  if exists(
    select 1
    from private.exam_prep_product_roadmap_milestones m
    where m.milestone_kind='product_content_complete'
      and m.product_label<>'Product Content-Complete'
  ) then
    raise exception 'exam_prep_c23_product_content_complete_label_mismatch';
  end if;

  if exists(
    select 1
    from private.exam_prep_product_roadmap_milestones m
    where lower(m.product_label) like '%as ready%'
       or lower(m.product_label) like '%exam ready%'
  ) then
    raise exception 'exam_prep_c23_forbidden_product_readiness_label';
  end if;
end
$$;

alter table private.exam_prep_product_roadmap_milestones
  drop constraint if exists exam_prep_product_roadmap_label_governance_v1;

alter table private.exam_prep_product_roadmap_milestones
  add constraint exam_prep_product_roadmap_label_governance_v1
  check (
    (milestone_kind<>'product_content_complete' or product_label='Product Content-Complete')
    and lower(product_label) not like '%as ready%'
    and lower(product_label) not like '%exam ready%'
  ) not valid;

alter table private.exam_prep_product_roadmap_milestones
  validate constraint exam_prep_product_roadmap_label_governance_v1;

comment on constraint exam_prep_product_roadmap_label_governance_v1
  on private.exam_prep_product_roadmap_milestones
  is 'C23: product/content readiness label is Product Content-Complete; product milestones may not use AS READY or Exam Ready learner terminology.';

commit;
