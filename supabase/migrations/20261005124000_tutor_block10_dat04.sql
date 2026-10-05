begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>147 then raise exception 'DAT04 expected 147 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT04 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-04:tutor:en:v2','P5','P5-DAT-04','en','tutor_v2_learner_first','Histograms and frequency density',
$t$A histogram is used for continuous grouped data. When class widths are unequal, the bar height cannot simply be the frequency. Instead use

frequency density = frequency / class width.

For example:

0-10 has frequency 20, so density = 20/10 = 2.

10-30 has frequency 30, so density = 30/20 = 1.5.

The second class has the larger frequency, but its bar is lower because the class is twice as wide. What represents frequency is bar area:

class width × frequency density = frequency.

This is the key idea in histograms: width carries part of the frequency information, so height must be adjusted by class width.$t$,
$t$For unequal class widths, use

frequency density = frequency / class width.

Example:

0-10, frequency 20 → density 2.

10-30, frequency 30 → density 1.5.

The second bar is wider, so it can have more frequency even though its height is lower.

In a histogram, bar area represents frequency.$t$,
$t$Think of each histogram bar as having to carry an amount of data equal to its frequency.

If a class is wide, that amount is spread across more horizontal space, so the bar does not need to be as tall. If a class is narrow, the same frequency would require a taller bar.

That is why frequency is represented by area, while the vertical scale is frequency density.$t$,
$t$Check class boundaries and class widths before calculating heights. Do not plot raw frequency as height when widths differ. Use frequency density on the vertical axis, and remember: area = class width × density = frequency.$t$,
'p5:P5-DAT-04:theory:en:v1'
),
(
'p5:P5-DAT-04:tutor:ru:v2','P5','P5-DAT-04','ru','tutor_v2_learner_first','Гистограмма и плотность частоты',
$t$Гистограмма используется для непрерывных сгруппированных данных. Если интервалы имеют разную ширину, высота столбца не может быть просто частотой. Используйте

плотность частоты = частота / ширина интервала.

Например:

0-10 имеет частоту 20, поэтому плотность = 20/10 = 2.

10-30 имеет частоту 30, поэтому плотность = 30/20 = 1.5.

У второго интервала частота больше, но столбец ниже, потому что интервал вдвое шире. Частоту показывает площадь столбца:

ширина интервала × плотность частоты = частота.

Главная идея гистограммы: часть информации о частоте уже содержится в ширине, поэтому высоту нужно корректировать.$t$,
$t$При неравной ширине интервалов используйте

плотность частоты = частота / ширина интервала.

Пример:

0-10, частота 20 → плотность 2.

10-30, частота 30 → плотность 1.5.

Второй столбец шире, поэтому может содержать большую частоту при меньшей высоте.

В гистограмме частоту показывает площадь.$t$,
$t$Представьте, что каждый столбец должен «нести» количество данных, равное своей частоте.

Если интервал широкий, это количество распределяется по большей ширине, поэтому столбец может быть ниже. Если интервал узкий, для той же частоты столбец должен быть выше.

Поэтому частота представлена площадью, а по вертикали откладывается плотность частоты.$t$,
$t$Сначала проверьте границы и ширину каждого интервала. При разных ширинах не используйте частоту напрямую как высоту. По вертикали откладывайте плотность частоты и помните: площадь = ширина × плотность = частота.$t$,
'p5:P5-DAT-04:theory:ru:v1'
),
(
'p5:P5-DAT-04:tutor:uz:v2','P5','P5-DAT-04','uz','tutor_v2_learner_first','Gistogramma va chastota zichligi',
$t$Gistogramma uzluksiz guruhlangan ma’lumotlar uchun ishlatiladi. Interval kengliklari turlicha bo‘lsa, ustun balandligini oddiy chastota bilan olish mumkin emas. Buning o‘rniga

chastota zichligi = chastota / interval kengligi

formuladan foydalaniladi.

Masalan:

0-10 intervalida chastota 20, demak zichlik = 20/10 = 2.

10-30 intervalida chastota 30, demak zichlik = 30/20 = 1.5.

Ikkinchi interval chastotasi kattaroq, lekin ustuni pastroq, chunki interval ikki baravar keng. Chastotani ustun yuzi ko‘rsatadi:

interval kengligi × chastota zichligi = chastota.

Asosiy g‘oya: kenglik ham chastota ma’lumotining bir qismini beradi, shuning uchun balandlik kenglikka moslashtiriladi.$t$,
$t$Interval kengliklari turlicha bo‘lsa,

chastota zichligi = chastota / interval kengligi.

Masalan:

0-10, chastota 20 → zichlik 2.

10-30, chastota 30 → zichlik 1.5.

Ikkinchi ustun kengroq bo‘lgani uchun balandligi pastroq bo‘lsa ham chastotasi kattaroq bo‘lishi mumkin.

Gistogrammada chastotani ustun yuzi ko‘rsatadi.$t$,
$t$Har bir gistogramma ustuni o‘z chastotasiga teng miqdordagi ma’lumotni “tashiydi” deb o‘ylang.

Interval keng bo‘lsa, bu miqdor kattaroq gorizontal kenglikka yoyiladi, shuning uchun ustun pastroq bo‘lishi mumkin. Interval tor bo‘lsa, bir xil chastota uchun ustun balandroq bo‘ladi.

Shu sabab chastota yuza bilan, vertikal o‘q esa chastota zichligi bilan ifodalanadi.$t$,
$t$Avval interval chegaralari va kengliklarini tekshiring. Kengliklar turlicha bo‘lsa chastotani to‘g‘ridan-to‘g‘ri balandlik sifatida chizmang. Vertikal o‘qda chastota zichligini ishlating va esda tuting: yuza = kenglik × zichlik = chastota.$t$,
'p5:P5-DAT-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
