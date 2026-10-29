-- Closed-gate regression for Chemistry J24, all languages; READ ONLY.
-- No student must see an AS Theory catalogue or lesson until explicitly approved.
-- A passing check returns all six values = 'not_available' (and j24=false/j25=closed).
SELECT
 (public.iclub_exam_chemistry_j24_theory_catalog_v1('en')->>'code') AS catalog_en,
 (public.iclub_exam_chemistry_j24_theory_catalog_v1('ru')->>'code') AS catalog_ru,
 (public.iclub_exam_chemistry_j24_theory_catalog_v1('uz')->>'code') AS catalog_uz,
 (public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-01-01','en')->>'code') AS lesson_en,
 (public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-01-01','ru')->>'code') AS lesson_ru,
 (public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-01-01','uz')->>'code') AS lesson_uz,
 (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) AS j24_expected_false,
 (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) AS j25_expected_closed;
