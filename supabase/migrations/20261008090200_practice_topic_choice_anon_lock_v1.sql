-- Defense in depth: Supabase may grant function EXECUTE to anon directly.
-- Read-only catalog already denies anon; close the same grant on self-chosen topic sessions.
-- No data/history changes.
revoke all on function public.start_practice_topic_drill_choice_safe_v1(text,text,text,text) from anon;
