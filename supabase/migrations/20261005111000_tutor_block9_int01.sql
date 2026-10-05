begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>123 then raise exception 'INT01 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-INT-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'INT01 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-INT-01:tutor:en:v2','P1','P1-INT-01','en','tutor_v2_learner_first','Antiderivatives',
$t$Integration reverses differentiation. For n≠-1,

∫x^n dx = x^(n+1)/(n+1) + C.

The power increases by 1, then you divide by the new power.

For a linear expression inside a power, also compensate for its derivative. For example,

∫[6x² + 4(2x+1)³] dx

= 2x³ + 1/2(2x+1)⁴ + C.

You can check the result by differentiating it: the derivative returns 6x² + 4(2x+1)³.

The constant C is needed because many curves have the same derivative.$t$,
$t$Reverse the power rule:

∫x^n dx = x^(n+1)/(n+1) + C, for n≠-1.

Example:

∫[6x² + 4(2x+1)³] dx
= 2x³ + 1/2(2x+1)⁴ + C.

For (ax+b)^n, remember to account for the inner coefficient a.$t$,
$t$Think of integration as asking: “What function would differentiate to this?”

To reverse d/dx(x³)=3x², the integral of 3x² is x³.

For (2x+1)³, differentiation would produce an extra factor 2 from the inside. Integration must undo that factor as well, which is why a compensating division appears.$t$,
$t$Increase the power first, then divide by the new power. For (ax+b)^n, compensate for the inner coefficient. Add C to every indefinite integral. A quick derivative check is the safest way to verify the antiderivative.$t$,
'p1:P1-INT-01:theory:en:v1'
),
(
'p1:P1-INT-01:tutor:ru:v2','P1','P1-INT-01','ru','tutor_v2_learner_first','Первообразные',
$t$Интегрирование является обратной операцией к дифференцированию. При n≠-1:

∫x^n dx = x^(n+1)/(n+1) + C.

Сначала показатель увеличивается на 1, затем выражение делится на новый показатель.

Если внутри степени есть линейное выражение, нужно также компенсировать его производную. Например,

∫[6x² + 4(2x+1)³] dx

= 2x³ + 1/2(2x+1)⁴ + C.

Проверка проста: продифференцируйте ответ — должна вернуться функция 6x² + 4(2x+1)³.

Постоянная C нужна потому, что несколько кривых могут иметь одну и ту же производную.$t$,
$t$Используйте обратное правило степени:

∫x^n dx = x^(n+1)/(n+1) + C, при n≠-1.

Например,

∫[6x² + 4(2x+1)³] dx
= 2x³ + 1/2(2x+1)⁴ + C.

Для (ax+b)^n учитывайте внутренний коэффициент a.$t$,
$t$Считайте интегрирование вопросом: «Какая функция при дифференцировании дала бы это выражение?»

Чтобы обратить d/dx(x³)=3x², интеграл от 3x² должен дать x³.

Для (2x+1)³ при дифференцировании появляется дополнительный множитель 2 от внутреннего выражения. Интегрирование должно компенсировать и его.$t$,
$t$Сначала увеличьте показатель на 1, затем разделите на новый показатель. Для (ax+b)^n компенсируйте внутренний коэффициент. В неопределённом интеграле обязательно добавляйте C. Для проверки продифференцируйте полученный ответ.$t$,
'p1:P1-INT-01:theory:ru:v1'
),
(
'p1:P1-INT-01:tutor:uz:v2','P1','P1-INT-01','uz','tutor_v2_learner_first','Boshlang‘ich funksiyalar',
$t$Integrallash differensiallashning teskari amalidir. n≠-1 bo‘lsa,

∫x^n dx = x^(n+1)/(n+1) + C.

Avval daraja 1 ga oshiriladi, keyin yangi darajaga bo‘linadi.

Daraja ichida chiziqli ifoda bo‘lsa, uning hosilasini ham kompensatsiya qilish kerak. Masalan,

∫[6x² + 4(2x+1)³] dx

= 2x³ + 1/2(2x+1)⁴ + C.

Natijani differensiallab tekshirish mumkin: hosila yana 6x² + 4(2x+1)³ ni beradi.

C doimiysi kerak, chunki bir xil hosilaga ega bir nechta funksiyalar mavjud.$t$,
$t$Daraja qoidasini teskari ishlating:

∫x^n dx = x^(n+1)/(n+1) + C, n≠-1.

Masalan,

∫[6x² + 4(2x+1)³] dx
= 2x³ + 1/2(2x+1)⁴ + C.

(ax+b)^n uchun ichki a koeffitsiyentini hisobga oling.$t$,
$t$Integrallashni “qaysi funksiya differensiallansa shu ifoda chiqadi?” degan savol deb o‘ylang.

d/dx(x³)=3x² bo‘lgani uchun 3x² ning integrali x³.

(2x+1)³ ni differensiallaganda ichkaridan qo‘shimcha 2 koeffitsiyent chiqadi. Integrallash shu koeffitsiyentni ham teskari hisobga oladi.$t$,
$t$Avval darajani 1 ga oshiring, keyin yangi darajaga bo‘ling. (ax+b)^n uchun ichki koeffitsiyentni kompensatsiya qiling. Aniqlanmagan integralga C ni qo‘shing. Eng yaxshi tekshiruv — javobni differensiallash.$t$,
'p1:P1-INT-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
