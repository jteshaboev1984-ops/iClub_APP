-- Production-applied Supabase migration 20260902134705 / fix_practice_v4_question_count_constraint.
alter table public.practice_sessions_v4 drop constraint if exists practice_sessions_v4_question_ids_check;
alter table public.practice_sessions_v4 add constraint practice_sessions_v4_question_ids_check check (cardinality(question_ids) between 1 and 10);
