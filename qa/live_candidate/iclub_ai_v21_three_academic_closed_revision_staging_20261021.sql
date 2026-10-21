-- Approved-owner technical staging only: NEW DRAFT versions, not any student release.
-- Uses current stable source_card_key, immutable history and no learner writes.
-- Existing expert-review owner report is pinned to the ORIGINAL v1 snapshots.
-- New v2 revisions independently require refreshed external reviewer evidence.
DO $pre$ DECLARE n integer; BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_review_reports)<>70
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_signed_review_receipts)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_deliveries)
 THEN RAISE EXCEPTION 'Refuse content staging after external source state drift'; END IF;
 SELECT count(*) INTO n
 FROM private.iclub_ai_v21_academic_sources a
 JOIN (VALUES
 (10095,'chemistry','en','62cd8d816296f87b6177470b41abc91498489f861055f1f0b6576f49975f2d78','228d5f63594892ff7c45cfa9473ed158560a4be3aa8144e247b5967fe30d878b'),
 (10095,'chemistry','ru','bbba970fe0c579d07075faecf9ba76514f7dd20cafbc4c792966c3c15a6a0970','228d5f63594892ff7c45cfa9473ed158560a4be3aa8144e247b5967fe30d878b'),
 (10095,'chemistry','uz','87302a522c219fd020f50a96eaea3fb50ae092eabbaad5ff218b9ab444887705','228d5f63594892ff7c45cfa9473ed158560a4be3aa8144e247b5967fe30d878b'),
 (9465,'economics','en','d57ac7f27b1901506b66dc979e27c8c8468e518ed329f193f75c4b57974d4f88','e63354f659fed927bcfe43d2a5e902363f2f23c3392e4a2bb42883e5da567552'),
 (9465,'economics','ru','c84469133393ff71e861f0f04ab7c8a56f37625a02affba79a47670021270f90','e63354f659fed927bcfe43d2a5e902363f2f23c3392e4a2bb42883e5da567552'),
 (9465,'economics','uz','76cbc1334b437026d5aed090aa1096a48dc9039b96dcb4b6192476b8905a7349','e63354f659fed927bcfe43d2a5e902363f2f23c3392e4a2bb42883e5da567552'),
 (9723,'economics','en','7e6e69455e17175d003ad03a8aecf24f1a80b7275394d82abc4f9b21b9f24776','d8ce415f1b509ac7539348d8bf47545e520e11ece4352f2c3e8fe11ce2c880c8'),
 (9723,'economics','ru','f6f20089a4a1a613662bddcb748a571dd12dbeda66a3da80bd1ee44ec88bcb87','d8ce415f1b509ac7539348d8bf47545e520e11ece4352f2c3e8fe11ce2c880c8'),
 (9723,'economics','uz','abd226016001c26bc74a78e32f5a3e4a3df59195b6a52778303dd45e82b8ebc3','d8ce415f1b509ac7539348d8bf47545e520e11ece4352f2c3e8fe11ce2c880c8')
 ) AS pins(id,subject,locale,sha,target)
 ON a.subject_key=pins.subject AND a.context_key='question_'||pins.id
 AND a.locale=pins.locale AND a.content_hash=pins.sha AND a.target_hash=pins.target
 AND a.source_version='qbank_exact_explanation_draft_v1'
 AND a.publication_revision=1 AND NOT a.published AND a.revoked
 AND NOT private.iclub_ai_v21_source_admitted_v1(a);
 IF n<>9 THEN RAISE EXCEPTION 'Refuse stale 3x3 source content fingerprints'; END IF;
END $pre$;

SELECT private.iclub_ai_v21_stage_qbank_revision_v2('chemistry',10095,
 'qbank_exact_explanation_draft_v1','curated_v2_10095',
 jsonb_build_object('en','Propanal is an aldehyde and reduces Tollens’ reagent, giving a silver mirror; propanone is a ketone and does not. HCN adds to propanal to form CH₃CH₂CH(OH)CN. Its carbon bearing –OH is attached to four different groups, so it is chiral. Addition to the planar carbonyl from either face, in an achiral reaction environment, produces a racemic mixture. Propanone gives (CH₃)₂C(OH)CN, where two identical methyl groups mean the product is not chiral.','ru','Пропаналь — альдегид и восстанавливает реактив Толленса с образованием серебряного зеркала; пропанон — кетон и не даёт такой реакции. При присоединении HCN к пропаналю образуется CH₃CH₂CH(OH)CN. Атом углерода с группой –OH связан с четырьмя разными заместителями, поэтому он хирален. В ахиральной реакционной среде атака плоской карбонильной группы возможна с двух сторон и образуется рацемическая смесь. Из пропанона получается (CH₃)₂C(OH)CN с двумя одинаковыми метильными группами; этот продукт не хирален.','uz','Propanal aldegid bo‘lgani uchun Tollens reaktivini qaytarib, kumush ko‘zgu hosil qiladi; propanon keton bo‘lgani uchun bunday reaksiya bermaydi. Propanalga HCN qo‘shilganda CH₃CH₂CH(OH)CN hosil bo‘ladi. –OH tutgan uglerod to‘rtta turli guruhga bog‘langan va xiral markaz hisoblanadi. Axiral reaksiya muhitida tekis karbonil guruhiga ikki tomondan hujum bo‘lishi mumkin, natijada rasemik aralashma hosil bo‘ladi. Propanondan (CH₃)₂C(OH)CN olinadi; undagi ikkita bir xil metil guruhi tufayli mahsulot xiral emas.'),
 'Owner-governed closed academic explanation correction: Clarify racemic mixture statement without changing chemistry answer key') AS revised_locales;

SELECT private.iclub_ai_v21_stage_qbank_revision_v2('economics',9465,
 'qbank_exact_explanation_draft_v1','curated_v2_9465',
 jsonb_build_object('en','Correct answer: Leakages exceed injections by $10 million, putting downward pressure on income. Injections = investment (40) + government spending (50) + exports (30) = $120 million. Leakages = savings (35) + taxes (45) + imports (50) = $130 million. Therefore, net injections = 120 − 130 = −$10 million. Given the question’s spare-capacity and adjustment assumptions, this net withdrawal tends to reduce equilibrium national income; the final decrease cannot be calculated without further multiplier information.','ru','Правильный ответ: изъятия превышают инъекции на 10 млн долларов, создавая понижательное давление на доход. Инъекции = инвестиции (40) + государственные расходы (50) + экспорт (30) = 120 млн долларов. Изъятия = сбережения (35) + налоги (45) + импорт (50) = 130 млн долларов. Чистые инъекции = 120 − 130 = −10 млн долларов. При указанных условиях неполной загрузки и корректировки это ведёт к тенденции снижения равновесного национального дохода; величину итогового изменения без данных о мультипликаторе определить нельзя.','uz','To‘g‘ri javob: iqtisodiyotdan chiqib ketishlar inyeksiyalardan 10 mln dollarga ko‘p bo‘lib, daromadni pasaytiruvchi bosim yuzaga keltiradi. Inyeksiyalar = investitsiya (40) + davlat xarajatlari (50) + eksport (30) = 120 mln dollar. Chiqib ketishlar = jamg‘arma (35) + soliqlar (45) + import (50) = 130 mln dollar. Sof inyeksiya = 120 − 130 = −10 mln dollar. Savoldagi foydalanilmayotgan quvvatlar va moslashish shartlarida bu muvozanatdagi milliy daromadni kamaytirishga moyil; yakuniy o‘zgarish miqdori uchun multiplikator haqida qo‘shimcha ma’lumot kerak.'),
 'Owner-governed closed academic explanation correction: Ensure explicit injections/leakages arithmetic is shown in Uzbek and consistent across EN/RU/UZ') AS revised_locales;

SELECT private.iclub_ai_v21_stage_qbank_revision_v2('economics',9723,
 'qbank_exact_explanation_draft_v1','curated_v2_9723',
 jsonb_build_object('en','Correct answer: The price level stays at 100 and real output falls from 200 to 170. Initially, equilibrium requires 400 − 2P = 100 + P, so 3P = 300, P = 100 and Q = 200. After the demand and cost shocks, 370 − 2P = 70 + P, so 3P = 300 again, P = 100 and Q = 170. The negative demand shock and negative short-run supply shock offset each other in the price level in this example, while output declines.','ru','Правильный ответ: уровень цен остаётся 100, а реальный выпуск сокращается с 200 до 170. Сначала равновесие: 400 − 2P = 100 + P, следовательно 3P = 300, P = 100 и Q = 200. После одновременного сдвига спроса и предложения: 370 − 2P = 70 + P, следовательно снова 3P = 300, P = 100, но Q = 170. Отрицательный шок спроса и отрицательный шок краткосрочного предложения в этом примере взаимно компенсируют влияние на уровень цен, но выпуск уменьшается.','uz','To‘g‘ri javob: narx darajasi 100 bo‘lib qoladi, real ishlab chiqarish esa 200 dan 170 ga kamayadi. Dastlab muvozanat sharti: 400 − 2P = 100 + P; bundan 3P = 300, P = 100 va Q = 200. Talab hamda qisqa muddatli taklif o‘zgargandan keyin: 370 − 2P = 70 + P; bundan yana 3P = 300, P = 100, ammo Q = 170. Ushbu misolda talab va qisqa muddatli taklifning salbiy siljishlari narxga ta’sir jihatidan bir-birini qoplaydi, lekin ishlab chiqarish hajmi pasayadi.'),
 'Owner-governed closed academic explanation correction: Restore both simultaneous equilibrium equations in Russian and Uzbek and preserve shock interpretation') AS revised_locales;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>330
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history WHERE snapshot_basis='original_live_baseline_20261021')<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history WHERE snapshot_basis='owner_governed_revision')<>9
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources WHERE source_version='qbank_exact_explanation_draft_v1')<>201
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources WHERE source_version IN
  ('curated_v2_10095','curated_v2_9465','curated_v2_9723')
 AND publication_revision=2 AND revoked AND NOT published AND NOT content_reviewed
 AND NOT rights_reviewed AND NOT locale_reviewed AND NOT academic_qa_passed
 AND approved_at IS NULL)<>9
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_review_reports)<>70
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
  WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_signed_review_receipts)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_deliveries)
 THEN RAISE EXCEPTION 'Closed revision release guard failure'; END IF;
END $post$;
