-- Initial governed AI context source pack for P1/P5 learner explanations.
-- Additive only. These are original iClub guidance cards, not Cambridge/coursebook text.
-- This migration does not enable AI generation, does not grant AI entitlements, and does not mutate academic state.

insert into private.exam_prep_ai_source_cards(
  source_card_key,
  component_code,
  skill_code,
  card_type,
  locale,
  source_version,
  title,
  body_text,
  approval_status,
  rights_status,
  is_runtime_allowed,
  content_hash,
  approved_at,
  updated_at
)
values
  (
    'p1:progress_context:en:v1','P1',null,'progress_context','en','iclub_ai_context_v1_2026_09_07',
    'Understanding Paper 1 progress',
    'Paper 1 progress is tracked only from Paper 1 evidence. Confirmed coverage means skills with accepted first-coverage evidence; it is not the same as mastery or exam readiness. Stage movement follows evidence rules, not the calendar.',
    'approved','original_iclub',true,'d625d05945d21d147a3123901878cad9683d358b94f0c4e3a6c7fb5b2c74dd07',now(),now()
  ),
  (
    'p1:progress_context:ru:v1','P1',null,'progress_context','ru','iclub_ai_context_v1_2026_09_07',
    'Как понимать прогресс Paper 1',
    'Прогресс Paper 1 считается только по подтверждениям Paper 1. Подтверждённое покрытие означает навыки с принятым базовым подтверждением; это не то же самое, что mastery или готовность к экзамену. Переход между этапами определяется подтверждениями, а не календарём.',
    'approved','original_iclub',true,'18c196a4833b48139b997553b1355a64bb804729805d0a270eb8635b562a7447',now(),now()
  ),
  (
    'p1:progress_context:uz:v1','P1',null,'progress_context','uz','iclub_ai_context_v1_2026_09_07',
    'Paper 1 progressini tushunish',
    'Paper 1 progressi faqat Paper 1 dalillari asosida hisoblanadi. Tasdiqlangan qamrov qabul qilingan dastlabki dalili bor ko‘nikmalarni anglatadi; bu mastery yoki imtihonga tayyorlik bilan bir xil emas. Bosqichlar kalendar bo‘yicha emas, dalillar bo‘yicha o‘zgaradi.',
    'approved','original_iclub',true,'0469e3000d6a9b78068987933068754212eac5507f0d572452f4237c16060c6f',now(),now()
  ),
  (
    'p5:progress_context:en:v1','P5',null,'progress_context','en','iclub_ai_context_v1_2026_09_07',
    'Understanding Paper 5 progress',
    'Paper 5 progress is tracked only from Paper 5 evidence. Confirmed coverage means skills with accepted first-coverage evidence; it is not the same as mastery or exam readiness. Paper 1 results never raise Paper 5 progress.',
    'approved','original_iclub',true,'077dd1f9bbd8ab638f77f0c75b5cb89b308e06c828e90da7333c1a5f082f77e3',now(),now()
  ),
  (
    'p5:progress_context:ru:v1','P5',null,'progress_context','ru','iclub_ai_context_v1_2026_09_07',
    'Как понимать прогресс Paper 5',
    'Прогресс Paper 5 считается только по подтверждениям Paper 5. Подтверждённое покрытие означает навыки с принятым базовым подтверждением; это не то же самое, что mastery или готовность к экзамену. Результаты Paper 1 не повышают прогресс Paper 5.',
    'approved','original_iclub',true,'7adfd2974c002dd715b1a2e1ca5a2c4d4edd9688bb8152a0f648cb2b0b1c706c',now(),now()
  ),
  (
    'p5:progress_context:uz:v1','P5',null,'progress_context','uz','iclub_ai_context_v1_2026_09_07',
    'Paper 5 progressini tushunish',
    'Paper 5 progressi faqat Paper 5 dalillari asosida hisoblanadi. Tasdiqlangan qamrov qabul qilingan dastlabki dalili bor ko‘nikmalarni anglatadi; bu mastery yoki imtihonga tayyorlik bilan bir xil emas. Paper 1 natijalari Paper 5 progressini oshirmaydi.',
    'approved','original_iclub',true,'af48a1cbaabace45967fa9b63ded5b6533098563eb947ad9d9c6eb0d4c9f2f1b',now(),now()
  ),
  (
    'p1:weekly_plan_context:en:v1','P1',null,'weekly_plan_context','en','iclub_ai_context_v1_2026_09_07',
    'Understanding the Paper 1 weekly plan',
    'The Paper 1 weekly plan is built from the learner’s current Paper 1 evidence, open corrections, due retests and available mathematics time. Priority order can change when new verified evidence arrives. The plan does not overwrite prior evidence.',
    'approved','original_iclub',true,'756801d42940d498e05209bf24adfebccf122ebf69b6a02aa773cde4cea1e78c',now(),now()
  ),
  (
    'p1:weekly_plan_context:ru:v1','P1',null,'weekly_plan_context','ru','iclub_ai_context_v1_2026_09_07',
    'Как понимать недельный план Paper 1',
    'Недельный план Paper 1 строится по текущим подтверждениям Paper 1, открытым исправлениям, наступившим повторным проверкам и доступному времени на математику. Приоритеты могут меняться после новых подтверждённых результатов. План не переписывает прежние подтверждения.',
    'approved','original_iclub',true,'72b0441ef21437c4f80a4b856961b8e2f91be81ae1c017f1a9d49facdc37ce78',now(),now()
  ),
  (
    'p1:weekly_plan_context:uz:v1','P1',null,'weekly_plan_context','uz','iclub_ai_context_v1_2026_09_07',
    'Paper 1 haftalik rejasini tushunish',
    'Paper 1 haftalik rejasi joriy Paper 1 dalillari, ochiq tuzatishlar, vaqti kelgan qayta tekshiruvlar va matematika uchun mavjud vaqt asosida tuziladi. Yangi tasdiqlangan natijalar kelganda ustuvorliklar o‘zgarishi mumkin. Reja oldingi dalillarni qayta yozmaydi.',
    'approved','original_iclub',true,'f3d4bc648237d46efdfd431b8a4553651af66399ea392fdacefa791c61a65399',now(),now()
  ),
  (
    'p5:weekly_plan_context:en:v1','P5',null,'weekly_plan_context','en','iclub_ai_context_v1_2026_09_07',
    'Understanding the Paper 5 weekly plan',
    'The Paper 5 weekly plan is built from the learner’s current Paper 5 evidence, open corrections, due retests and available mathematics time. Paper 1 mastery does not substitute for Paper 5 evidence. The plan does not overwrite prior evidence.',
    'approved','original_iclub',true,'9690d697f6ee689ca22e835c4b9a6bda9798fc0a270d6a7595a33dc758d5bbe0',now(),now()
  ),
  (
    'p5:weekly_plan_context:ru:v1','P5',null,'weekly_plan_context','ru','iclub_ai_context_v1_2026_09_07',
    'Как понимать недельный план Paper 5',
    'Недельный план Paper 5 строится по текущим подтверждениям Paper 5, открытым исправлениям, наступившим повторным проверкам и доступному времени на математику. Mastery Paper 1 не заменяет подтверждения Paper 5. План не переписывает прежние подтверждения.',
    'approved','original_iclub',true,'bb3889f3b7252633c7a704f3e8ec89a5cd2786142ad9ff839161f05f996fb49f',now(),now()
  ),
  (
    'p5:weekly_plan_context:uz:v1','P5',null,'weekly_plan_context','uz','iclub_ai_context_v1_2026_09_07',
    'Paper 5 haftalik rejasini tushunish',
    'Paper 5 haftalik rejasi joriy Paper 5 dalillari, ochiq tuzatishlar, vaqti kelgan qayta tekshiruvlar va matematika uchun mavjud vaqt asosida tuziladi. Paper 1 mastery Paper 5 dalillarining o‘rnini bosmaydi. Reja oldingi dalillarni qayta yozmaydi.',
    'approved','original_iclub',true,'5d8942720be2133c2b5fa6c3b513a264cbf12d4c93bb2f6ef905ff185402b025',now(),now()
  )
on conflict (source_card_key) do update
set component_code=excluded.component_code,
    skill_code=excluded.skill_code,
    card_type=excluded.card_type,
    locale=excluded.locale,
    source_version=excluded.source_version,
    title=excluded.title,
    body_text=excluded.body_text,
    approval_status=excluded.approval_status,
    rights_status=excluded.rights_status,
    is_runtime_allowed=excluded.is_runtime_allowed,
    content_hash=excluded.content_hash,
    approved_at=coalesce(private.exam_prep_ai_source_cards.approved_at,excluded.approved_at),
    updated_at=now();
