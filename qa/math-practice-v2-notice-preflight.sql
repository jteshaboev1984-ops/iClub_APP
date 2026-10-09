-- iClub QA read-only. No writes. Re-run directly before approved in-app campaign.
with math_subject as (
  select id from public.subjects where subject_key='mathematics' and is_active is true limit 1
), recipients as (
  select distinct u.id
  from public.users u
  join public.user_subjects us on us.user_id=u.id
  join math_subject m on m.id=us.subject_id
), campaign as (
  select id from public.notifications
  where meta->>'campaign_code'='math_practice_v2_notice_20261009_v1'
)
select
 (select count(*) from auth.users) as auth_accounts,
 (select count(*) from public.users) as inbox_profiles,
 (select count(*) from recipients) as eligible_math_recipients,
 (select count(*) from campaign) as existing_campaigns,
 (select count(*) from public.user_notifications un join campaign c on c.id=un.notification_id) as existing_assignments,
 (select status from private.practice_v2_release_switch_audit
  where release_version='math_p1_practice_v2_2026_10_07' limit 1) as math_bank_status,
 (select count(*) from public.practice_pool_questions ppq join public.practice_pools p on p.id=ppq.pool_id join math_subject m on m.id=p.subject_id where p.is_active is true and ppq.is_active is true and p.tour_no between 1 and 7) as math_bank_active_memberships,
 (select count(*) from public.tour_attempts) as tour_attempts,
 (select count(*) from public.certificates) as certificates;
