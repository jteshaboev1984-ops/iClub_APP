begin;

-- P2-46: beta-governance actor boundary.
-- Weekly review v2 accepts an explicit reviewer id for audit attribution and is
-- intended for governed service/operations execution. Browser-authenticated
-- learners must never be able to call it and impersonate a staff reviewer by
-- supplying that reviewer's UUID.

revoke execute on function public.record_exam_prep_beta_weekly_review_v2(
  text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid
) from public,anon,authenticated;

grant execute on function public.record_exam_prep_beta_weekly_review_v2(
  text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid
) to service_role;

commit;
