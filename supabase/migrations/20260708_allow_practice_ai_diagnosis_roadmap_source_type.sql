-- Allow saved AI diagnosis snapshots in learning_roadmaps.
-- Safe: expands only the allowed source_type list. No data rows are modified.

alter table public.learning_roadmaps
  drop constraint if exists learning_roadmaps_source_type_check;

alter table public.learning_roadmaps
  add constraint learning_roadmaps_source_type_check
  check (source_type = any (array[
    'practice_attempt'::text,
    'tour_attempt'::text,
    'practice_ai_diagnosis'::text
  ]));
