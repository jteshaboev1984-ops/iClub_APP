-- AI-2 initial governed Practice AI source pack for Economics.
-- Scope is deliberately limited to the four diagnostic-pilot questions that are
-- actually linked to the current Practice 1 pool. Tour-only / non-Practice pilot
-- questions are intentionally excluded from AI-2.
-- Text is original iClub guidance, not coursebook text.
-- This migration does not enable Practice AI, create entitlements or call a model.

insert into private.practice_ai_source_cards(
  source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
  title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,approved_at,updated_at
)
values
(
  'practice:economics:q1071:answer_explanation:en:v1','economics',1071,'Demand','Complementary goods',
  'answer_explanation','en','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Complementary goods and demand',
  'Complementary goods are used together. If the price of one complement rises, using the pair becomes more expensive, so demand for the other good tends to decrease.',
  'approved','original_iclub',true,'4d510d8e2e777581c303d75ea939b75d22efa9d2d34ac74124d16cb31611d1c6',now(),now()
),
(
  'practice:economics:q1071:answer_explanation:ru:v1','economics',1071,'Demand','Complementary goods',
  'answer_explanation','ru','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Дополняющие товары и спрос',
  'Дополняющие товары используются вместе. Если цена одного из них растёт, совместное использование становится дороже, поэтому спрос на другой товар обычно снижается.',
  'approved','original_iclub',true,'8d79e90cd11b23ba132997d470ae6938f2465add0a9b8bfee0c6c8cc45078498',now(),now()
),
(
  'practice:economics:q1071:answer_explanation:uz:v1','economics',1071,'Demand','Complementary goods',
  'answer_explanation','uz','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'To‘ldiruvchi tovarlar va talab',
  'To‘ldiruvchi tovarlar birga iste’mol qilinadi. Ulardan birining narxi oshsa, ularni birga ishlatish qimmatroq bo‘ladi va ikkinchi tovarga talab odatda kamayadi.',
  'approved','original_iclub',true,'a721b874aaaf6643a24308b1e72596c546a1e45ddb4f58a94fa0b88966a98149',now(),now()
),
(
  'practice:economics:q1081:answer_explanation:en:v1','economics',1081,'Market','Allocative efficiency',
  'answer_explanation','en','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Allocative efficiency',
  'Allocative efficiency is reached when price equals marginal cost, P = MC. At that point, the value consumers place on the last unit matches the cost of producing it.',
  'approved','original_iclub',true,'a3c8c826e9cb13940df487bf934441cc1913c61540280fb00966a6c55584e80b',now(),now()
),
(
  'practice:economics:q1081:answer_explanation:ru:v1','economics',1081,'Market','Allocative efficiency',
  'answer_explanation','ru','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Аллокативная эффективность',
  'Аллокативная эффективность достигается при P = MC: цена равна предельным издержкам. В этой точке ценность последней единицы для потребителей соответствует затратам на её производство.',
  'approved','original_iclub',true,'9eb4b698af6fb6c6a52f8256d6d38de9887a3a208511c4ae111d457abfb022a3',now(),now()
),
(
  'practice:economics:q1081:answer_explanation:uz:v1','economics',1081,'Market','Allocative efficiency',
  'answer_explanation','uz','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Allokativ samaradorlik',
  'Allokativ samaradorlik P = MC bo‘lganda yuzaga keladi: narx chegaraviy xarajatga teng. Bu nuqtada iste’molchilar uchun oxirgi birlikning qiymati uni ishlab chiqarish xarajatiga mos keladi.',
  'approved','original_iclub',true,'eb22f3f6e73709a3529d91ddf2c5a7ef7705541dbaec8908c0ddde2ca40f9cc4',now(),now()
),
(
  'practice:economics:q1115:answer_explanation:en:v1','economics',1115,'Market','Consumer surplus',
  'answer_explanation','en','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Consumer surplus',
  'Consumer surplus is the difference between what consumers are willing to pay and the market price they actually pay. On a demand diagram, it is the area below the demand curve and above the market price.',
  'approved','original_iclub',true,'ea6836ee186ba14b6ccd447db89be943b4cd03572a19547c3fb1c0347985ecf8',now(),now()
),
(
  'practice:economics:q1115:answer_explanation:ru:v1','economics',1115,'Market','Consumer surplus',
  'answer_explanation','ru','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Потребительский излишек',
  'Потребительский излишек — это разница между готовностью потребителя платить и фактической рыночной ценой. На графике спроса это область под кривой спроса и над рыночной ценой.',
  'approved','original_iclub',true,'df1c7fc104dd6203ed772713b79cde4dcf29bfe253d39f7fd23f93ec2f3abe38',now(),now()
),
(
  'practice:economics:q1115:answer_explanation:uz:v1','economics',1115,'Market','Consumer surplus',
  'answer_explanation','uz','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Iste’molchi ortiqchaligi',
  'Iste’molchi ortiqchaligi iste’molchi to‘lashga tayyor bo‘lgan summa bilan amaldagi bozor narxi o‘rtasidagi farqdir. Talab grafigida bu talab egri chizig‘i ostidagi va bozor narxidan yuqoridagi maydon.',
  'approved','original_iclub',true,'9af61d747c556021fda50e248991d29d8056a82c815d1875ede2bd5704390429',now(),now()
),
(
  'practice:economics:q1135:answer_explanation:en:v1','economics',1135,'Basics','Income from factors of production',
  'answer_explanation','en','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Factor rewards',
  'Each factor of production has a corresponding reward: land earns rent, labour earns wages, capital earns interest, and enterprise earns profit.',
  'approved','original_iclub',true,'c6f904015bdb88f3da7fde0189c7fe6aaf0fd661f64cdac421a8a196b176b101',now(),now()
),
(
  'practice:economics:q1135:answer_explanation:ru:v1','economics',1135,'Basics','Income from factors of production',
  'answer_explanation','ru','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Доходы факторов производства',
  'Каждому фактору производства соответствует свой доход: земля получает ренту, труд — заработную плату, капитал — процент, предпринимательство — прибыль.',
  'approved','original_iclub',true,'c8c30effd2beb3f0791d0e9f53a891dd27c35f2fa9a55a218399109d82484c06',now(),now()
),
(
  'practice:economics:q1135:answer_explanation:uz:v1','economics',1135,'Basics','Income from factors of production',
  'answer_explanation','uz','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Ishlab chiqarish omillari daromadi',
  'Har bir ishlab chiqarish omiliga mos daromad mavjud: yer — renta, mehnat — ish haqi, kapital — foiz, tadbirkorlik — foyda.',
  'approved','original_iclub',true,'361ae75b3f6af4a5c1f840e338c6260a1319d2ced91e06a1145f1b7fcef34d4b',now(),now()
),
(
  'practice:economics:result_context:en:v1','economics',null,null,null,
  'result_context','en','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Understanding a Practice result',
  'A Practice result summarizes recorded answers from this completed attempt. Score, error count and weak topics can guide what to review next, but they do not by themselves prove mastery, exam readiness or a predicted grade.',
  'approved','original_iclub',true,'21cb05640a8adbb3eb03a3750086c9ea9cf1cb314a0ff2b6073f473c68c32533',now(),now()
),
(
  'practice:economics:result_context:ru:v1','economics',null,null,null,
  'result_context','ru','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Как понимать результат Practice',
  'Результат Practice суммирует подтверждённые ответы этой завершённой попытки. Балл, количество ошибок и слабые темы помогают выбрать, что повторить дальше, но сами по себе не подтверждают освоение темы, готовность к экзамену или прогноз оценки.',
  'approved','original_iclub',true,'88f21a9ce8f816db5f21d0012c33e64efe7b6251b855de081cf108a16a3b6bb1',now(),now()
),
(
  'practice:economics:result_context:uz:v1','economics',null,null,null,
  'result_context','uz','iclub_practice_ai_economics_pilot_v1_2026_09_25',
  'Practice natijasini tushunish',
  'Practice natijasi ushbu yakunlangan urinishdagi tasdiqlangan javoblarni jamlaydi. Ball, xatolar soni va zaif mavzular keyin nimani takrorlashni tanlashga yordam beradi, ammo ular o‘z-o‘zidan mavzuni to‘liq egallash, imtihonga tayyorlik yoki baho prognozini anglatmaydi.',
  'approved','original_iclub',true,'13121246c57452510852c91b6bd34ac0b6640daa8efb15fbef0fffc2c6f5e5bf',now(),now()
)
on conflict(source_card_key) do update
set subject_key=excluded.subject_key,
    question_id=excluded.question_id,
    topic=excluded.topic,
    subtopic=excluded.subtopic,
    card_type=excluded.card_type,
    locale=excluded.locale,
    source_version=excluded.source_version,
    title=excluded.title,
    body_text=excluded.body_text,
    approval_status=excluded.approval_status,
    rights_status=excluded.rights_status,
    is_runtime_allowed=excluded.is_runtime_allowed,
    content_hash=excluded.content_hash,
    approved_at=coalesce(private.practice_ai_source_cards.approved_at,excluded.approved_at),
    updated_at=now();
