-- Production-compatible grant hardening.
-- Internal/admin/staging tables have no client RLS policies, so client grants are removed.
-- Canonical/reference tables with SELECT-only client policies are reduced to SELECT-only grants.

begin;

-- Internal/admin/staging/archive tables: no client access.
revoke all privileges on table public.admin_certificate_score_sync_backups from anon, authenticated;
revoke all privileges on table public.admin_daily_reports from anon, authenticated;
revoke all privileges on table public.admin_practice_attempt_score_recalc_backups from anon, authenticated;
revoke all privileges on table public.admin_practice_false_negative_backups from anon, authenticated;
revoke all privileges on table public.admin_profile_takeover_backups from anon, authenticated;
revoke all privileges on table public.admin_tour_attempt_resets from anon, authenticated;
revoke all privileges on table public.admin_tour_attempt_score_recalc_backups from anon, authenticated;
revoke all privileges on table public.admin_tour_false_negative_backups from anon, authenticated;
revoke all privileges on table public.admin_user_profile_fixes from anon, authenticated;
revoke all privileges on table public.question_cleanup_archive from anon, authenticated;
revoke all privileges on table public.question_relink_audit from anon, authenticated;
revoke all privileges on table public.questions_import_staging from anon, authenticated;
revoke all privileges on table public.support_settings from anon, authenticated;

-- Canonical/reference tables: client contract is SELECT-only.
revoke all privileges on table public.books from anon, authenticated;
grant select on table public.books to anon, authenticated;
revoke all privileges on table public.credential_definitions from anon, authenticated;
grant select on table public.credential_definitions to anon, authenticated;
revoke all privileges on table public.districts from anon, authenticated;
grant select on table public.districts to anon, authenticated;
revoke all privileges on table public.lessons from anon, authenticated;
grant select on table public.lessons to anon, authenticated;
revoke all privileges on table public.news from anon, authenticated;
grant select on table public.news to anon, authenticated;
revoke all privileges on table public.practice_pool_questions from anon, authenticated;
grant select on table public.practice_pool_questions to anon, authenticated;
revoke all privileges on table public.practice_pools from anon, authenticated;
grant select on table public.practice_pools to anon, authenticated;
revoke all privileges on table public.regions from anon, authenticated;
grant select on table public.regions to anon, authenticated;
revoke all privileges on table public.subjects from anon, authenticated;
grant select on table public.subjects to anon, authenticated;
revoke all privileges on table public.topic_book_map from anon, authenticated;
grant select on table public.topic_book_map to anon, authenticated;
revoke all privileges on table public.tour_questions from anon, authenticated;
grant select on table public.tour_questions to anon, authenticated;
revoke all privileges on table public.tours from anon, authenticated;
grant select on table public.tours to anon, authenticated;
revoke all privileges on table public.videos from anon, authenticated;
grant select on table public.videos to anon, authenticated;

commit;
