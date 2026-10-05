begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>70 then raise exception 'CIR03 UZ baseline %',v; end if;
end $pre$;

with x as (select
$t$Agar θ radianlarda bo‘lsa, sektor yuzi

A = 1/2 r²θ

formula bilan topiladi.

r=8 va θ=π/3 uchun sektor yuzi 32π/3.

Aylana segmenti yuzini topish uchun sektordan ikki radius orasidagi uchburchak yuzini ayiring. Bu misolda

1/2 r² sinθ = 16√3.

Shuning uchun segment yuzi

32π/3 - 16√3.

Murakkab shaklda avval tanish qismlarni ajrating, keyin chizmaga qarab ularning yuzlarini qo‘shing yoki ayiring.$t$::text m,
$t$θ radianlarda bo‘lsa A=1/2 r²θ. r=8 va θ=π/3 uchun sektor yuzi 32π/3. Radiuslar orasidagi uchburchak yuzi 16√3, demak segment yuzi 32π/3 - 16√3.$t$::text simp,
$t$Sektor to‘liq doiraning bir qismi. To‘liq burchak 2π, doira yuzi πr² bo‘lgani uchun A=1/2 r²θ kelib chiqadi. Aylana segmentini esa «sektor minus uchburchak» deb tasavvur qilish qulay.$t$::text alt,
$t$θ radianlarda ekanini tekshiring. Sektor yuzi 1/2 r²θ ni yoy uzunligi rθ bilan aralashtirmang. Segment uchun to‘g‘ri uchburchakni ayiring. Yuz kvadrat birliklarda yoziladi.$t$::text focus)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select 'p1:P1-CIR-03:tutor:uz:v2','P1','P1-CIR-03','uz','tutor_v2_learner_first',
'Sektor va aylana segmenti yuzi',m,simp,alt,focus,
'p1:P1-CIR-03:theory:uz:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Sektor va aylana segmenti yuzi',m,simp,alt,focus,'p1:P1-CIR-03:theory:uz:v1'))
from x;

commit;
