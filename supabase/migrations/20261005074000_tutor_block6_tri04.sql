begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>81 then raise exception 'TRI04 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-TRI-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'TRI04 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-TRI-04:tutor:en:v2','P1','P1-TRI-04','en','tutor_v2_learner_first','Basic trigonometric identities',
$t$A trigonometric identity is an equality that is true for every allowed value of x. In Paper 1, the two core identities are

sin²x + cos²x = 1

and

tan x = sin x / cos x.

The goal is usually to transform one side until it matches the other.

For example,

sin²x / (1 - cos x)

can use sin²x = 1 - cos²x:

(1 - cos²x)/(1 - cos x)
= (1 - cos x)(1 + cos x)/(1 - cos x)
= 1 + cos x,

provided the original denominator is non-zero.

The useful habit is to choose an identity because it creates a simplifiable algebraic structure, not just because you recognise a trig expression.$t$,
$t$For Paper 1, use

sin²x + cos²x = 1

and

tan x = sin x / cos x.

To simplify sin²x/(1-cos x), replace sin²x by 1-cos²x, factor the numerator, then cancel the common factor. The result is 1+cos x, where the original denominator is non-zero.$t$,
$t$Treat a trig identity like algebra with a small set of allowed substitutions.

If you see sin²x next to cos x, the identity sin²x=1-cos²x may turn the numerator into a difference of squares. If you see tan x mixed with sin and cos, rewrite tan x as sin x/cos x so everything is in the same language.

The aim is to make the structure simpler step by step.$t$,
$t$Usually transform one side rather than moving everything at once. Use only the basic Paper 1 identities. Factor before cancelling and respect any original denominator restriction. Do not introduce addition, subtraction or double-angle formulae here.$t$,
'p1:P1-TRI-04:theory:en:v1'
),
(
'p1:P1-TRI-04:tutor:ru:v2','P1','P1-TRI-04','ru','tutor_v2_learner_first','Основные тригонометрические тождества',
$t$Тригонометрическое тождество — это равенство, верное для всех допустимых x. В Paper 1 используются два основных тождества:

sin²x + cos²x = 1

и

tan x = sin x / cos x.

Обычно задача состоит в том, чтобы преобразовать одну сторону до вида другой.

Например,

sin²x / (1 - cos x)

можно преобразовать с помощью sin²x = 1 - cos²x:

(1 - cos²x)/(1 - cos x)
= (1 - cos x)(1 + cos x)/(1 - cos x)
= 1 + cos x,

при условии, что исходный знаменатель не равен нулю.

Полезно выбирать тождество не просто потому, что оно знакомо, а потому что оно создаёт выражение, которое дальше удобно упростить.$t$,
$t$Для Paper 1 используйте

sin²x + cos²x = 1

и

tan x = sin x / cos x.

Чтобы упростить sin²x/(1-cos x), замените sin²x на 1-cos²x, разложите числитель на множители и сократите общий множитель. Получаем 1+cos x, если исходный знаменатель не равен нулю.$t$,
$t$Смотрите на тождество как на обычную алгебру с несколькими разрешёнными заменами.

Если рядом встречаются sin²x и cos x, замена sin²x=1-cos²x может превратить выражение в разность квадратов. Если tan x смешан с sin и cos, перепишите tan x как sin x/cos x.

Так выражение шаг за шагом становится проще.$t$,
$t$Обычно лучше преобразовывать одну сторону тождества. Используйте только базовые тождества Paper 1. Перед сокращением сначала разложите выражение на множители и учитывайте ограничения исходного знаменателя. Формулы сложения, вычитания и двойного угла сюда не добавляйте.$t$,
'p1:P1-TRI-04:theory:ru:v1'
),
(
'p1:P1-TRI-04:tutor:uz:v2','P1','P1-TRI-04','uz','tutor_v2_learner_first','Asosiy trigonometrik ayniyatlar',
$t$Trigonometrik ayniyat — barcha ruxsat etilgan x lar uchun to‘g‘ri bo‘ladigan tenglik. Paper 1 da ikki asosiy ayniyat ishlatiladi:

sin²x + cos²x = 1

va

tan x = sin x / cos x.

Odatda maqsad bir tomonni ikkinchi tomonga teng ko‘rinishga keltirishdir.

Masalan,

sin²x / (1 - cos x)

da sin²x = 1 - cos²x dan foydalanamiz:

(1 - cos²x)/(1 - cos x)
= (1 - cos x)(1 + cos x)/(1 - cos x)
= 1 + cos x,

asl maxraj nol bo‘lmagan holatda.

Foydali odat: ayniyatni shunchaki tanish bo‘lgani uchun emas, balki keyingi algebraik soddalashtirishga yordam bergani uchun tanlang.$t$,
$t$Paper 1 uchun

sin²x + cos²x = 1

va

tan x = sin x / cos x

ayniyatlaridan foydalaning.

sin²x/(1-cos x) ni soddalashtirish uchun sin²x ni 1-cos²x ga almashtiring, suratni ko‘paytuvchilarga ajrating va umumiy ko‘paytuvchini qisqartiring. Natija 1+cos x bo‘ladi, bunda asl maxraj nol emas.$t$,
$t$Trigonometrik ayniyatni oddiy algebra deb o‘ylang, faqat bir nechta maxsus almashtirishlar bor.

sin²x bilan cos x bir ifodada uchrasa, sin²x=1-cos²x almashtirishi ayirmalar kvadratiga olib kelishi mumkin. tan x sin va cos bilan aralashsa, uni sin x/cos x ko‘rinishiga o‘tkazing.

Maqsad — ifodani bosqichma-bosqich soddalashtirish.$t$,
$t$Ko‘pincha ayniyatning faqat bir tomonini o‘zgartiring. Faqat Paper 1 dagi asosiy ayniyatlardan foydalaning. Qisqartirishdan oldin ko‘paytuvchilarga ajrating va asl maxraj cheklovini saqlang. Qo‘shish, ayirish yoki ikki burchak formulalarini bu yerga kiritmang.$t$,
'p1:P1-TRI-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
