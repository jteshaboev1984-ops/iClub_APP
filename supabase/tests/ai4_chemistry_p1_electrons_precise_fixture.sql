\set ON_ERROR_STOP on

insert into public.subjects(id,subject_key,title,type,is_active)
values(4,'chemistry','Chemistry','main',true)
on conflict(id) do update
set subject_key=excluded.subject_key,title=excluded.title,type=excluded.type,is_active=excluded.is_active;

insert into public.practice_pools(id,subject_id,tour_no,title,is_active)
values(7500,4,1,'AI4 Chemistry Electrons precise fixture',true);

delete from public.questions where id in (1908,1917,1927,1931,1937,1939,1941,1945,1953,1956,1960,1962,1968,1971,3036,3037,3039,3046);

insert into public.questions(
 id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
 explanation,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
 book_ref,time_limit_sec,quality_status
) values
(1908,4,'Electrons in atoms','Shape of the p orbital','medium','mcq','Fixture 1908','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1917,4,'Electrons in atoms','Orbital electron capacity','medium','mcq','Fixture 1917','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1927,4,'Electrons in atoms','Effective nuclear charge across a period','medium','mcq','Fixture 1927','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1931,4,'Electrons in atoms','Atomic radius across a period','medium','mcq','Fixture 1931','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1937,4,'Electrons in atoms','Group properties and outer electrons','medium','mcq','Fixture 1937','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1939,4,'Electrons in atoms','First energy level','medium','mcq','Fixture 1939','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1941,4,'Electrons in atoms','Atomic radius trend down a group','medium','mcq','Fixture 1941','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1945,4,'Electrons in atoms','Electron configuration of magnesium','medium','mcq','Fixture 1945','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1953,4,'Electrons in atoms','Ionisation energy down a group','medium','mcq','Fixture 1953','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1956,4,'Electrons in atoms','Atomic radius across a period','medium','mcq','Fixture 1956','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1960,4,'Electrons in atoms','Electron capacity of the p subshell','medium','mcq','Fixture 1960','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1962,4,'Electrons in atoms','Energy levels in the same period','medium','mcq','Fixture 1962','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1968,4,'Electrons in atoms','First ionisation energy across a period','medium','mcq','Fixture 1968','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(1971,4,'Electrons in atoms','Valence electrons and group properties','medium','mcq','Fixture 1971','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(3036,4,'Electrons in atoms','Capacity of the p sub-shell','medium','mcq','Fixture 3036','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(3037,4,'Electrons in atoms','Electron configuration of aluminium','medium','mcq','Fixture 3037','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(3039,4,'Electrons in atoms','First ionisation energy across Period 3','medium','mcq','Fixture 3039','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published'),
(3046,4,'Electrons in atoms','Large jump in successive ionisation energies','medium','mcq','Fixture 3046','["A","B","C","D"]','A','PRIVATE',true,
 'RU','UZ','EN','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','RU','UZ','EN','AI4 Chemistry electrons precise',60,'published');

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
values
(7500,1908,1,true),
(7500,1917,2,true),
(7500,1927,3,true),
(7500,1931,4,true),
(7500,1937,5,true),
(7500,1939,6,true),
(7500,1941,7,true),
(7500,1945,8,true),
(7500,1953,9,true),
(7500,1956,10,true),
(7500,1960,11,true),
(7500,1962,12,true),
(7500,1968,13,true),
(7500,1971,14,true),
(7500,3036,15,true),
(7500,3037,16,true),
(7500,3039,17,true),
(7500,3046,18,true);
