\set ON_ERROR_STOP on

-- AI-2 Economics source-pack fixture. Never run in production.
insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_status
)
values
  (1071,7,'Demand','Complementary goods','medium','mcq','Fixture 1071','A|B|C|D','B',
   'fixture private explanation',true,'RU 1071','UZ 1071','EN 1071','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','Economics Book | Practice 1 | Ch7',60,'published'),
  (1081,7,'Market','Allocative efficiency','medium','mcq','Fixture 1081','A|B|C|D','A',
   'fixture private explanation',true,'RU 1081','UZ 1081','EN 1081','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','Economics Book | Practice 1 | Ch11',60,'published'),
  (1115,7,'Market','Consumer surplus','medium','mcq','Fixture 1115','A|B|C|D','C',
   'fixture private explanation',true,'RU 1115','UZ 1115','EN 1115','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','Economics Book | Practice 1 | Ch11',60,'published'),
  (1135,7,'Basics','Income from factors of production','easy','mcq','Fixture 1135','A|B|C|D','D',
   'fixture private explanation',true,'RU 1135','UZ 1135','EN 1135','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','Economics Book | Practice 1 | Ch1',60,'published')
on conflict(id) do nothing;
