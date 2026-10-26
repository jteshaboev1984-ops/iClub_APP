-- Economics native Exam Prep — learner-owned setup analogous to Math,
-- but never touching or sharing Mathematics profile rows.
BEGIN;
CREATE TABLE IF NOT EXISTS private.iclub_exam_native_economics_profiles_v1(
 user_id uuid PRIMARY KEY REFERENCES auth.users(id),
 program_key text NOT NULL DEFAULT 'economics_9708' CHECK(program_key='economics_9708'),
 version_key text NOT NULL DEFAULT 'economics_2026_2028_v1' CHECK(version_key='economics_2026_2028_v1'),
 exam_series text NOT NULL CHECK(length(exam_series) BETWEEN 3 AND 80),
 target_grade text NOT NULL CHECK(target_grade IN('A*','A','B','C','D','E')),
 total_student_hours_available numeric(5,1) NOT NULL CHECK(total_student_hours_available BETWEEN 0.5 AND 168),
 economics_hours_budget numeric(5,1) NOT NULL CHECK(economics_hours_budget BETWEEN 0.5 AND 168),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(economics_hours_budget<=total_student_hours_available)
);
ALTER TABLE private.iclub_exam_native_economics_profiles_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_native_economics_profiles_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_native_economics_profiles_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_native_economics_profiles_v1 TO service_role;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_economics_profile_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE u uuid:=auth.uid(); p private.iclub_exam_native_economics_profiles_v1%ROWTYPE;
BEGIN
 IF u IS NULL OR NOT private.iclub_exam_native_economics_beta_allowed_v1(u) THEN
 RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT * INTO p FROM private.iclub_exam_native_economics_profiles_v1 WHERE user_id=u;
 RETURN jsonb_build_object('ok',true,'profile',
 CASE WHEN FOUND THEN jsonb_build_object('exam_series',p.exam_series,'target_grade',p.target_grade,
 'total_student_hours_available',p.total_student_hours_available,'economics_hours_budget',p.economics_hours_budget)
 ELSE NULL END);
END;$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_economics_save_profile_v1(
 p_exam_series text,p_target_grade text,p_total_hours numeric,p_economics_hours numeric
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE u uuid:=auth.uid(); v_exam text:=btrim(coalesce(p_exam_series,''));
BEGIN
 IF u IS NULL OR NOT private.iclub_exam_native_economics_beta_allowed_v1(u) THEN
 RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 IF length(v_exam) NOT BETWEEN 3 AND 80
 OR p_target_grade IS NULL OR p_target_grade NOT IN('A*','A','B','C','D','E')
 OR p_total_hours IS NULL OR p_economics_hours IS NULL
 OR p_total_hours<0.5 OR p_total_hours>168
 OR p_economics_hours<0.5 OR p_economics_hours>p_total_hours THEN
 RETURN jsonb_build_object('ok',false,'code','invalid_profile'); END IF;
 INSERT INTO private.iclub_exam_native_economics_profiles_v1
 (user_id,exam_series,target_grade,total_student_hours_available,economics_hours_budget)
 VALUES (u,v_exam,p_target_grade,p_total_hours,p_economics_hours)
 ON CONFLICT(user_id) DO UPDATE SET
 exam_series=excluded.exam_series,target_grade=excluded.target_grade,
 total_student_hours_available=excluded.total_student_hours_available,
 economics_hours_budget=excluded.economics_hours_budget,updated_at=clock_timestamp();
 RETURN jsonb_build_object('ok',true,'saved',true);
END;$f$;

REVOKE ALL ON FUNCTION public.iclub_exam_native_economics_profile_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_economics_save_profile_v1(text,text,numeric,numeric)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_economics_profile_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_economics_save_profile_v1(text,text,numeric,numeric) TO authenticated;
DO $check$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_native_economics_profiles_v1)<>0
 OR has_table_privilege('authenticated','private.iclub_exam_native_economics_profiles_v1','SELECT')
 OR has_table_privilege('anon','private.iclub_exam_native_economics_profiles_v1','SELECT')
 OR has_function_privilege('anon','public.iclub_exam_native_economics_profile_v1()','EXECUTE')
 OR (SELECT count(*) FROM public.users u WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id))<>3
 THEN RAISE EXCEPTION 'Native Economics setup beta safeguards failed'; END IF;
END;$check$;
COMMIT;
