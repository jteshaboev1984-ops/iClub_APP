-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.
-- Prerequisite edge seed chunk 2; edges 93-184 of 184.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_prerequisite_edges(
  program_version_id, edge_no, from_node_code, to_skill_code, target_component_code, edge_rule, is_mastery_crediting
)
select pv.id, v.edge_no, v.from_node_code, v.to_skill_code, v.target_component_code, v.edge_rule, v.is_mastery_crediting
from pv
cross join (values
(93,'P1-INT-01','P1-INT-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(94,'PR-CAL-01','P1-INT-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(95,'P1-INT-03','P1-INT-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(96,'P1-COO-02','P1-INT-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(97,'P1-QUA-03','P1-INT-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(98,'P1-INT-03','P1-INT-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(99,'P1-FUN-01','P1-INT-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(100,'PR-ALG-03','P1-INT-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(101,'PR-STA-01','P5-DAT-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(102,'PR-COM-01','P5-DAT-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(103,'PR-STA-01','P5-DAT-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(104,'PR-ALG-01','P5-DAT-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(105,'P5-DAT-05','P5-DAT-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(106,'PR-GRF-01','P5-DAT-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(107,'PR-STA-01','P5-DAT-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(108,'PR-ALG-01','P5-DAT-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(109,'PR-GRF-01','P5-DAT-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(110,'PR-STA-01','P5-DAT-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(111,'PR-GRF-01','P5-DAT-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(112,'PR-ALG-01','P5-DAT-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(113,'PR-STA-01','P5-DAT-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(114,'P5-DAT-05','P5-DAT-07','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(115,'P5-DAT-06','P5-DAT-07','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(116,'PR-CAL-01','P5-DAT-07','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(117,'P5-DAT-06','P5-DAT-08','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(118,'P5-DAT-07','P5-DAT-08','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(119,'PR-COM-01','P5-DAT-08','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(120,'P5-DAT-06','P5-DAT-09','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(121,'P5-DAT-07','P5-DAT-09','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(122,'PR-ALG-03','P5-DAT-09','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(123,'P5-DAT-09','P5-DAT-10','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(124,'PR-ALG-03','P5-DAT-10','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(125,'PR-CNT-01','P5-CNT-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(126,'PR-ALG-01','P5-CNT-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(127,'P5-CNT-01','P5-CNT-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(128,'P5-CNT-02','P5-CNT-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(129,'PR-ALG-01','P5-CNT-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(130,'P5-CNT-02','P5-CNT-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(131,'P5-CNT-03','P5-CNT-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(132,'P5-CNT-01','P5-CNT-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(133,'P5-CNT-04','P5-CNT-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(134,'PR-SET-01','P5-PRO-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(135,'PR-CNT-01','P5-PRO-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(136,'P5-PRO-01','P5-PRO-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(137,'P5-CNT-05','P5-PRO-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(138,'PR-SET-01','P5-PRO-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(139,'P5-PRO-01','P5-PRO-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(140,'PR-SET-01','P5-PRO-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(141,'P5-PRO-03','P5-PRO-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(142,'P5-PRO-03','P5-PRO-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(143,'P5-PRO-04','P5-PRO-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(144,'PR-ALG-01','P5-PRO-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(145,'P5-PRO-04','P5-PRO-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(146,'P5-PRO-05','P5-PRO-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(147,'P5-PRO-03','P5-DRV-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(148,'PR-ALG-03','P5-DRV-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(149,'P5-DRV-01','P5-DRV-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(150,'PR-ALG-01','P5-DRV-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(151,'P5-DRV-02','P5-DRV-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(152,'PR-ALG-02','P5-DRV-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(153,'P5-PRO-04','P5-BIN-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(154,'P5-DRV-01','P5-BIN-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(155,'P5-BIN-01','P5-BIN-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(156,'P5-CNT-05','P5-BIN-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(157,'PR-CAL-01','P5-BIN-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(158,'P5-BIN-01','P5-BIN-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(159,'P5-DRV-02','P5-BIN-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(160,'P5-DRV-03','P5-BIN-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(161,'P5-PRO-04','P5-GEO-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(162,'P5-DRV-01','P5-GEO-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(163,'P5-GEO-01','P5-GEO-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(164,'P5-PRO-03','P5-GEO-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(165,'PR-ALG-02','P5-GEO-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(166,'P5-GEO-01','P5-GEO-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(167,'P5-DRV-02','P5-GEO-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(168,'PR-EQN-01','P5-GEO-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(169,'P5-DAT-06','P5-NOR-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(170,'P5-DAT-07','P5-NOR-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(171,'PR-GRF-01','P5-NOR-01','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(172,'P5-NOR-01','P5-NOR-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(173,'PR-ALG-03','P5-NOR-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(174,'PR-CAL-01','P5-NOR-02','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(175,'P5-NOR-02','P5-NOR-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(176,'P5-PRO-03','P5-NOR-03','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(177,'P5-NOR-02','P5-NOR-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(178,'PR-EQN-01','P5-NOR-04','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(179,'P5-NOR-04','P5-NOR-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(180,'PR-ALG-03','P5-NOR-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(181,'PR-EQN-01','P5-NOR-05','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(182,'P5-BIN-02','P5-NOR-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(183,'P5-BIN-03','P5-NOR-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(184,'P5-NOR-03','P5-NOR-06','P5','Prerequisite only; passing this edge does not award mastery in the target or another component.',false)
) as v(edge_no, from_node_code, to_skill_code, target_component_code, edge_rule, is_mastery_crediting)
on conflict (program_version_id, edge_no) do update
set from_node_code=excluded.from_node_code,
    to_skill_code=excluded.to_skill_code,
    target_component_code=excluded.target_component_code,
    edge_rule=excluded.edge_rule,
    is_mastery_crediting=false;

commit;
