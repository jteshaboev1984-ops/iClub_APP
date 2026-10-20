-- Approved UI improvement: seven first-party product guidance topics in RU/UZ/EN.
-- Source: original iClub main Study, Practice, Tour, Books and Support routes.
-- No academic answers, no learner data, no provider or tariff switches.
DO $check$
BEGIN
 IF md5(pg_get_functiondef('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)'::regprocedure))
     <> 'efa0aad57f26362e80d55d5ce6f0c844'
 THEN RAISE EXCEPTION 'Production prepared delivery function changed unexpectedly'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources)<>18 OR
    EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_help_sources WHERE
      help_key IN ('catalog_help','practice_rules','practice_after','recs_help','tour_rules','books_help','support_help'))
 THEN RAISE EXCEPTION 'App guidance publication: unexpected pre-existing rows'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources
      WHERE published AND NOT revoked AND
      source_hash=encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex'))<>18
 THEN RAISE EXCEPTION 'Prior 18 published navigation sources must remain untouched'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_control
       WHERE singleton=1 AND beta_enabled AND prepared_enabled
       AND NOT generation_enabled)<>1
 THEN RAISE EXCEPTION 'Prepared-only beta gate not in expected state'; END IF;
END $check$;
WITH reviewed(help_key,locale,message) AS (VALUES
('catalog_help','ru','Начни в разделе «Учёба»: выбери доступный предмет. Сначала открой уроки или книги для повторения, а затем Practice для самопроверки. Если нужная функция недоступна, проверь доступ к предмету.'),
('catalog_help','uz','«O‘qish» bo‘limida mavjud fanni tanlang. Avval darslar yoki kitoblar orqali mavzuni takrorlang, so‘ng Practice’da o‘zingizni tekshiring. Bo‘lim ochilmasa, fanga kirish huquqini tekshiring.'),
('catalog_help','en','Start in Study and choose a subject you can access. Review its lessons or books first, then use Practice to check your understanding. If something is locked, check your subject access.'),
('practice_rules','ru','Открой «Учёба» → предмет → Practice. Выбери доступный тур или тему и начни тренировку. После завершения откроется результат; из него можно перейти в разбор ошибок и рекомендации. Practice — тренировка, а не соревновательный Tour.'),
('practice_rules','uz','«O‘qish» → fan → Practice bo‘limiga o‘ting. Mavjud tur yoki mavzuni tanlab, mashqni boshlang. Yakunlangach natija, xatolar tahlili va tavsiyalarni ko‘rishingiz mumkin. Practice rasmiy Tour emas.'),
('practice_rules','en','Open Study → a subject → Practice. Choose an available tour or topic and start your practice. When you finish, open your result, mistake review and recommendations. Practice is training, not a competitive Tour.'),
('practice_after','ru','После завершения Practice открой на экране результата «Разбор ошибок». Сравни ответы с правильными и изучи доступные объяснения. Затем вернись к результату и открой «Рекомендации», чтобы выбрать материал для повторения.'),
('practice_after','uz','Practice tugagach, natija ekranida «Xatolar tahlili»ni oching. Javoblaringizni to‘g‘ri javoblar bilan solishtirib, mavjud izohlarni o‘qing. Keyin natijaga qaytib, takrorlash uchun «Tavsiyalar»ni oching.'),
('practice_after','en','After finishing Practice, choose Mistake Review on the result screen. Compare your answers with the correct ones and read the available explanations. Then return to the result and open Recommendations to decide what to review.'),
('recs_help','ru','Завершив Practice, нажми «Рекомендации» на экране результата. Если для ошибок доступны учебные материалы, iClub предложит, что прочитать и повторить. После повторения вернись к предмету и попробуй Practice ещё раз.'),
('recs_help','uz','Practice yakunlangach, natija ekranidan «Tavsiyalar»ni oching. Xatolaringizga mos o‘quv materiallari mavjud bo‘lsa, iClub ularni taklif qiladi. Takrorlagach, faningizga qaytib, Practice’ni yana bajaring.'),
('recs_help','en','After Practice, open Recommendations from the result screen. If study resources related to your mistakes are available, iClub will suggest what to revisit. Review them, return to your subject and try Practice again.'),
('tour_rules','ru','Перед Tour прочитай правила и подтверди согласие. В официальном туре одна попытка: без пауз и возвращения к предыдущим вопросам. Два нарушения правил приводят к завершению попытки. Разбор может открыться позже в соответствии с правилами тура.'),
('tour_rules','uz','Tour boshlanishidan oldin qoidalarni o‘qing va rozilik bildiring. Rasmiy turda bitta urinish bor: pauza qilish yoki oldingi savolga qaytish mumkin emas. Ikki qoidabuzarlik urinishni tugatadi. Tahlil tur qoidalariga ko‘ra keyinroq ochilishi mumkin.'),
('tour_rules','en','Read and accept the rules before a Tour. An official Tour allows one attempt, with no pauses or return to previous questions. Two rule violations end the attempt. Review may open later according to the Tour rules.'),
('books_help','ru','Открой «Учёба» → нужный предмет → «Книги». Там отображаются опубликованные материалы по предмету. Если список пуст, материалы пока не добавлены. После чтения можно проверить понимание в Practice.'),
('books_help','uz','«O‘qish» → kerakli fan → «Kitoblar» bo‘limini oching. Unda fan bo‘yicha qo‘shilgan materiallar ko‘rsatiladi. Ro‘yxat bo‘sh bo‘lsa, materiallar hali joylanmagan. O‘qigach, Practice’da bilimingizni tekshiring.'),
('books_help','en','Open Study → your subject → Books. This section lists available resources for that subject. If the list is empty, no resources have been added yet. After reading, check your understanding in Practice.'),
('support_help','ru','Если возникла проблема с разделом или заданием, открой «Профиль» → «Поддержка». Сначала проверь ответы на частые вопросы; если нужно, отправь обращение с названием предмета, раздела и описанием проблемы. Не отправляй пароль.'),
('support_help','uz','Bo‘lim yoki topshiriq bilan muammo bo‘lsa, «Profil» → «Yordam» bo‘limini oching. Avval tez-tez so‘raladigan savollarni ko‘ring; kerak bo‘lsa, fan, bo‘lim va muammo tavsifi bilan murojaat yuboring. Parolingizni yubormang.'),
('support_help','en','If a section or activity does not work, open Profile → Support. Check the FAQ first; if needed, submit a request describing the subject, section and problem. Never include your password.')
)
INSERT INTO private.iclub_ai_v21_beta_help_sources(
 help_key,locale,message,source_version,source_hash,publication_revision,
 content_reviewed,rights_reviewed,locale_reviewed,published,revoked,approved_at
)
SELECT help_key,locale,message,'app-guidance-main-1ce0c45-v1',
 encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex'),
 1,true,true,true,true,false,clock_timestamp()
FROM reviewed;
DO $assert$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources)<>39 OR
 (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources WHERE
   source_version='app-guidance-main-1ce0c45-v1' AND publication_revision=1 AND
   published AND NOT revoked AND content_reviewed AND rights_reviewed AND locale_reviewed
   AND source_hash=encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex'))<>21
 THEN RAISE EXCEPTION 'Published guidance integrity failed'; END IF;
END $assert$;

-- Admit the reviewed post-Practice guidance prompt, keeping the existing
-- source, RLS, no-provider, quotas, ownership and active-assessment checks.
CREATE OR REPLACE FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(
 p_user_id uuid,p_request_id uuid,p_help_key text,p_locale text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $deliver$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 s private.iclub_ai_v21_beta_help_sources%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 old private.iclub_ai_v21_beta_deliveries%rowtype;
 v_now timestamptz := clock_timestamp();
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_locale NOT IN ('ru','uz','en')
 OR p_help_key NOT IN (
  'support_help','catalog_help','ratings_help','home_next',
  'practice_rules','practice_after','tour_rules','books_help','about_help',
  'notifications_help','community_help','certificates_help',
  'profile_meaning','video_help','recs_help','archive_help',
  'nav_home','nav_courses','nav_ratings','nav_profile','nav_about','nav_support'
 ) THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- The singleton row lock serializes read/grant/quota, including two workers.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none' THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 -- Protection is derived from server academic tables, never browser view hints.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (
  SELECT 1 FROM public.practice_sessions_v4
  WHERE user_id=p_user_id AND status='in_progress'
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 SELECT * INTO s FROM private.iclub_ai_v21_beta_help_sources
  WHERE help_key=p_help_key AND locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT s.published OR s.revoked
 OR NOT s.content_reviewed OR NOT s.rights_reviewed
 OR NOT s.locale_reviewed OR s.approved_at IS NULL
 OR encode(extensions.digest(convert_to(s.message,'UTF8'),'sha256'),'hex')
    <>s.source_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- A same-ID retry is idempotent only for the SAME owner/key/version/revision;
 -- after revocation, neither new nor historical messages are returned.
 SELECT * INTO old FROM private.iclub_ai_v21_beta_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.help_key=p_help_key
  AND old.locale=p_locale AND old.source_hash=s.source_hash
  AND old.source_version=s.source_version
  AND old.publication_revision=s.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',s.message,
     'mode','prepared','academic_state_changed',false,
     'provider_called',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES (p_user_id,v_now,0)
 ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at <= v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
   SET started_at=v_now,committed_count=0,updated_at=v_now
   WHERE user_id=p_user_id;
  u.committed_count:=0;
 END IF;
 IF u.committed_count>=3 THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_deliveries(
  request_id,user_id,help_key,locale,source_version,source_hash,publication_revision
 ) VALUES (
  p_request_id,p_user_id,p_help_key,p_locale,
  s.source_version,s.source_hash,s.publication_revision
 );
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+1,updated_at=v_now
 WHERE user_id=p_user_id;

 RETURN jsonb_build_object('ok',true,'message',s.message,
  'mode','prepared','academic_state_changed',false,
  'provider_called',false,'replayed',false);
END $deliver$;
REVOKE ALL ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)
 TO service_role;
