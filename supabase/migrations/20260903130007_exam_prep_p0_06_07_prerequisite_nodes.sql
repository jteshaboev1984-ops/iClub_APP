-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.
-- Foundation prerequisite nodes (11).

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_prerequisite_nodes(program_version_id, prerequisite_code, definition)
select pv.id, v.prerequisite_code, v.definition
from pv
cross join (values
('PR-ALG-01','Точная арифметика, дроби, отношения и проценты.'),
('PR-ALG-02','Индексы, корни, surds и научная запись.'),
('PR-ALG-03','Раскрытие скобок, факторизация, дробно-рациональные преобразования и смена subject.'),
('PR-CAL-01','Scientific calculator, округление и проверка порядка величины.'),
('PR-CNT-01','Факториал и базовый product rule.'),
('PR-COM-01','Читаемая запись решения, математическая нотация, контекст и единицы.'),
('PR-EQN-01','Линейные уравнения, неравенства и базовые simultaneous equations.'),
('PR-GRF-01','Координаты, шкалы, чтение и построение стандартных графиков.'),
('PR-SET-01','Нотация событий: P(A), union, intersection, complement.'),
('PR-STA-01','Типы данных, frequency tables и class intervals.'),
('PR-TRI-01','Пифагор и right-triangle trigonometry.')
) as v(prerequisite_code, definition)
on conflict (program_version_id, prerequisite_code) do update
set definition=excluded.definition;

commit;
