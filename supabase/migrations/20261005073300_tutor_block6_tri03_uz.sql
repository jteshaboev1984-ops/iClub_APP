begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>80 then raise exception 'TRI03 UZ baseline %',v; end if;
end $pre$;

with x as (select
$t$Teskari trigonometrik funksiya berilgan nisbat uchun bitta asosiy burchak qiymatini qaytaradi. Shuning uchun kalkulyator shu trigonometrik qiymatga ega barcha burchaklarni emas, bitta tanlangan burchakni ko‘rsatadi.

Misollar:

arcsin(1/2)=π/6,
arccos(-1/2)=2π/3,
arctan(1)=π/4.

Tenglama yechishda bu asosiy qiymat faqat boshlang‘ich nuqtadir. Savol berilgan oraliqdagi barcha yechimlarni so‘rasa, qolgan burchaklar grafik, simmetriya va davr yordamida topiladi.$t$::text m,
$t$Teskari trigonometrik funksiya bitta asosiy qiymat beradi. Masalan, arcsin(1/2)=π/6, arccos(-1/2)=2π/3 va arctan(1)=π/4. Kalkulyator javobi tenglamaning barcha yechimlarini avtomatik bermaydi.$t$::text simp,
$t$Bir xil sin, cos yoki tan qiymati bir nechta burchaklarda uchrashi mumkin. Shu sabab teskari funksiya bitta kelishilgan asosiy burchakni tanlaydi. Uni kalkulyatorning standart javobi deb o‘ylang; boshqa oraliq yechimlarni topish alohida qadam.$t$::text alt,
$t$Kalkulyator burchak rejimini tekshiring. Teskari trigonometrik natijani asosiy qiymat deb qabul qiling. Kalkulyatordagi bitta javobni tenglamaning barcha mumkin bo‘lgan burchaklari deb hisoblamang.$t$::text focus)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select 'p1:P1-TRI-03:tutor:uz:v2','P1','P1-TRI-03','uz','tutor_v2_learner_first',
'Teskari trigonometrik funksiyalar',m,simp,alt,focus,
'p1:P1-TRI-03:theory:uz:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Teskari trigonometrik funksiyalar',m,simp,alt,focus,'p1:P1-TRI-03:theory:uz:v1'))
from x;

commit;
