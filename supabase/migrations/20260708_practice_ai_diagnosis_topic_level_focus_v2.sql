-- AI diagnosis v2: choose main focus by top-level topic, not arbitrary subtopic.
-- Safe: writes only learning_roadmaps snapshots for the authenticated user's practice attempt.

create or replace function public.practice_ai_label_ru(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'macroeconomy' then 'Макроэкономика'
    when 'government intervention' then 'Госрегулирование'
    when 'circular flow' then 'Кругооборот доходов'
    when 'examples of injections' then 'Вливания в кругооборот'
    when 'injections' then 'Вливания в кругооборот'
    when 'examples of leakages' then 'Утечки из кругооборота'
    when 'leakages' then 'Утечки из кругооборота'
    when 'largest component of aggregate demand' then 'Компоненты совокупного спроса'
    when 'real gdp concept' then 'Реальный ВВП'
    when 'wages and leftward shift of sras' then 'Сдвиги SRAS'
    when 'calculating net exports' then 'Чистый экспорт'
    when 'fisher equation' then 'Уравнение Фишера'
    when 'phillips curve' then 'Кривая Филлипса'
    when 'characteristics of public goods' then 'Общественные блага'
    when 'maximum price and shortage' then 'Максимальная цена и дефицит'
    when 'progressive and regressive taxes' then 'Прогрессивные и регрессивные налоги'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

create or replace function public.practice_ai_label_uz(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'macroeconomy' then 'Makroiqtisodiyot'
    when 'government intervention' then 'Davlat aralashuvi'
    when 'circular flow' then 'Daromadlar aylanishi'
    when 'examples of injections' then 'Aylanishga qo‘shiladigan oqimlar'
    when 'injections' then 'Aylanishga qo‘shiladigan oqimlar'
    when 'examples of leakages' then 'Aylanishdan chiqib ketadigan oqimlar'
    when 'leakages' then 'Aylanishdan chiqib ketadigan oqimlar'
    when 'largest component of aggregate demand' then 'Yalpi talab tarkibiy qismlari'
    when 'real gdp concept' then 'Real YaIM'
    when 'wages and leftward shift of sras' then 'SRAS siljishlari'
    when 'calculating net exports' then 'Sof eksport'
    when 'fisher equation' then 'Fisher tenglamasi'
    when 'phillips curve' then 'Phillips egri chizig‘i'
    when 'characteristics of public goods' then 'Jamoat tovarlari'
    when 'maximum price and shortage' then 'Maksimal narx va taqchillik'
    when 'progressive and regressive taxes' then 'Progressiv va regressiv soliqlar'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

create or replace function public.practice_ai_label_en(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'examples of injections' then 'Injections into the circular flow'
    when 'injections' then 'Injections into the circular flow'
    when 'examples of leakages' then 'Leakages from the circular flow'
    when 'leakages' then 'Leakages from the circular flow'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

-- Full create_practice_ai_diagnosis body is applied in Supabase in this migration step.
-- It uses version='practice_ai_diagnosis_v2', aggregates by topic first,
-- and stores localized labels inside plan_json: main_focus_ru/uz/en and topic/subtopic labels.
