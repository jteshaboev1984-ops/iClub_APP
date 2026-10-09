-- iClub QA HOLD. Do NOT run on production without architect approval.
-- This first statement intentionally FAILS. Remove it only after signing off
-- scope (Mathematics selected), RU/UZ/EN texts and in-app-only delivery.
DO $hold$ BEGIN RAISE EXCEPTION 'HOLD: in-app notification campaign not yet approved'; END $hold$;

BEGIN;
SET LOCAL statement_timeout='30s';

DO $send$
DECLARE
  v_campaign constant text := 'math_practice_v2_notice_20261009_v1';
  v_notification_id bigint;
  v_subject_id bigint;
  v_expected integer;
  v_created integer;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended('iclub_notice:'||v_campaign,0));
  IF (SELECT count(*) FROM public.notifications n WHERE n.meta->>'campaign_code'=v_campaign)<>0 THEN
    RAISE EXCEPTION 'notification_campaign_already_exists';
  END IF;

  SELECT s.id INTO v_subject_id FROM public.subjects s
    WHERE s.subject_key='mathematics' AND s.is_active IS TRUE LIMIT 1;
  IF v_subject_id IS NULL THEN RAISE EXCEPTION 'mathematics_subject_missing'; END IF;

  SELECT count(*) INTO v_expected FROM (
    SELECT DISTINCT u.id FROM public.users u
    JOIN public.user_subjects us ON us.user_id=u.id
    WHERE us.subject_id=v_subject_id
  ) selected;
  IF v_expected<1 THEN RAISE EXCEPTION 'no_mathematics_inbox_recipients'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM private.practice_v2_release_switch_audit
    WHERE release_version='math_p1_practice_v2_2026_10_07' AND status='published'
      AND tour_snapshot_before=tour_snapshot_after
  ) THEN RAISE EXCEPTION 'practice_v2_publish_not_verified'; END IF;

  INSERT INTO public.notifications
    (audience,publish_at,title_ru,title_uz,title_en,body_ru,body_uz,body_en,kind,meta)
  VALUES
    ('manual',now(),
     'Практика по математике обновлена',
     'Matematika amaliyoti yangilandi',
     'Mathematics Practice updated',
     'В Практике по математике теперь 495 вопросов нового банка. Результаты прежней версии были очищены при обновлении. Начните новую попытку во вкладке «По турам» или «По темам». Результаты туров, сертификаты и прогресс Exam Prep сохранены.',
     'Matematika amaliyotida endi yangi bankning 495 ta savoli mavjud. Oldingi versiya natijalari yangilanish vaqtida tozalangan. «Turlar bo‘yicha» yoki «Mavzular bo‘yicha» bo‘limida yangi urinishni boshlang. Turlar natijalari, sertifikatlar va Exam Prep’dagi natijalaringiz saqlangan.',
     'Mathematics Practice now has 495 questions in the new bank. Results from the previous version were cleared during the update. Start a new attempt in “By tour” or “By topic”. Your Tours results, certificates and Exam Prep progress are preserved.',
     'manual',
     jsonb_build_object('campaign_code',v_campaign,'type','mathematics_practice_bank_update','channel','in_app_only'))
  RETURNING id INTO v_notification_id;

  INSERT INTO public.user_notifications
    (user_id,notification_id,delivery_status,delivery_error)
  SELECT DISTINCT u.id,v_notification_id,'skipped',
    'in_app_only: Mathematics Practice bank updated; no Telegram delivery'
  FROM public.users u
  JOIN public.user_subjects us ON us.user_id=u.id
  WHERE us.subject_id=v_subject_id
  ON CONFLICT (notification_id,user_id) DO NOTHING;

  GET DIAGNOSTICS v_created=ROW_COUNT;
  IF v_created<>v_expected THEN
    RAISE EXCEPTION 'recipient_count_mismatch actual_% expected_%',v_created,v_expected;
  END IF;
  IF (SELECT count(*) FROM public.user_notifications
    WHERE notification_id=v_notification_id AND delivery_status<>'skipped')<>0 THEN
    RAISE EXCEPTION 'telegram_delivery_status_not_skipped';
  END IF;
  RAISE NOTICE 'Campaign ID: %, in-app recipients: %',v_notification_id,v_created;
END $send$;
COMMIT;
