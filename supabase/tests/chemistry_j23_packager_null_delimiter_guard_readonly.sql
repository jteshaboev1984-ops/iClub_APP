-- Read-only, synthetic-only regression: a stale staged row MUST NOT pass by
-- smuggling an embedded unit separator or NULL past concat_ws().
-- No learner data, no private answers, no writes.
WITH cases(case_name,a,b,c,should_pass) AS (
 VALUES
 ('correct','a'::text,'b'::text,'c'::text,true),
 ('separator_and_null',('a'||chr(31)||'b')::text,'c'::text,NULL::text,false),
 ('trailing_separator_and_null','a'::text,('b'||chr(31)||'c')::text,NULL::text,false),
 ('missing_field','a'::text,NULL::text,'c'::text,false),
 ('separator_inside_field',('a'||chr(31))::text,'b'::text,'c'::text,false)
),
expected AS (
 SELECT encode(extensions.digest(convert_to(concat_ws(chr(31),'a','b','c'),'UTF8'),'sha256'),'hex') expected_hash
),
audited AS (
 SELECT x.case_name,x.should_pass,
 encode(extensions.digest(convert_to(concat_ws(chr(31),x.a,x.b,x.c),'UTF8'),'sha256'),'hex') insecure_hash,
 CASE WHEN (x.a IS NOT NULL AND strpos(x.a,chr(31))=0)
         AND (x.b IS NOT NULL AND strpos(x.b,chr(31))=0)
         AND (x.c IS NOT NULL AND strpos(x.c,chr(31))=0)
      THEN encode(extensions.digest(convert_to(concat_ws(chr(31),x.a,x.b,x.c),'UTF8'),'sha256'),'hex')
      ELSE NULL END guarded_hash
 FROM cases x
)
SELECT count(*) AS synthetic_cases_expected_5,
 count(*) FILTER(WHERE coalesce(guarded_hash=expected_hash,false)=should_pass) AS correct_classifications_expected_5,
 count(*) FILTER(WHERE insecure_hash=expected_hash AND guarded_hash IS NULL) AS delimiter_collisions_rejected_expected_2,
 count(*) FILTER(WHERE case_name='correct' AND guarded_hash=expected_hash) AS genuine_record_accepted_expected_1,
 count(*) FILTER(WHERE should_pass=false AND guarded_hash IS NOT DISTINCT FROM expected_hash) AS false_accepts_expected_0
FROM audited CROSS JOIN expected;
