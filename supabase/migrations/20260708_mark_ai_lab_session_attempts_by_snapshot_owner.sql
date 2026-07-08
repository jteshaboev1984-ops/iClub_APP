-- One-time cleanup for hidden AI lab test attempts from the same user/session that produced an AI diagnosis snapshot.
-- No rows are deleted; only hidden from normal stats by is_lab=true.

update public.practice_attempts pa
set is_lab = true
where pa.subject_id = 7
  and pa.created_at >= timestamp with time zone '2026-07-08 09:00:00+00'
  and pa.created_at <  timestamp with time zone '2026-07-08 13:00:00+00'
  and pa.user_id in (
    select distinct lr.user_id
    from public.learning_roadmaps lr
    where lr.source_type = 'practice_ai_diagnosis'
      and lr.created_at >= timestamp with time zone '2026-07-08 09:00:00+00'
      and lr.created_at <  timestamp with time zone '2026-07-08 13:00:00+00'
  )
  and coalesce(pa.is_lab, false) is false;
