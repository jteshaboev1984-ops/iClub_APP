-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.
-- Prerequisite edge seed chunk 1; edges 1-92 of 184.

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
(1,'PR-ALG-03','P1-QUA-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(2,'PR-GRF-01','P1-QUA-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(3,'P1-QUA-01','P1-QUA-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(4,'PR-EQN-01','P1-QUA-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(5,'PR-ALG-02','P1-QUA-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(6,'PR-ALG-03','P1-QUA-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(7,'PR-EQN-01','P1-QUA-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(8,'P1-QUA-03','P1-QUA-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(9,'PR-GRF-01','P1-QUA-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(10,'P1-QUA-03','P1-QUA-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(11,'PR-EQN-01','P1-QUA-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(12,'P1-QUA-03','P1-QUA-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(13,'PR-ALG-03','P1-QUA-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(14,'PR-ALG-03','P1-FUN-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(15,'PR-GRF-01','P1-FUN-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(16,'P1-FUN-01','P1-FUN-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(17,'P1-QUA-01','P1-FUN-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(18,'P1-FUN-01','P1-FUN-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(19,'PR-ALG-03','P1-FUN-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(20,'P1-FUN-01','P1-FUN-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(21,'PR-EQN-01','P1-FUN-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(22,'P1-FUN-04','P1-FUN-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(23,'PR-GRF-01','P1-FUN-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(24,'P1-FUN-01','P1-FUN-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(25,'PR-GRF-01','P1-FUN-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(26,'P1-FUN-01','P1-FUN-07','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(27,'PR-GRF-01','P1-FUN-07','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(28,'P1-FUN-06','P1-FUN-08','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(29,'P1-FUN-07','P1-FUN-08','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(30,'PR-GRF-01','P1-COO-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(31,'PR-EQN-01','P1-COO-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(32,'P1-COO-01','P1-COO-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(33,'PR-ALG-02','P1-COO-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(34,'P1-COO-01','P1-COO-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(35,'P1-QUA-01','P1-COO-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(36,'P1-COO-02','P1-COO-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(37,'P1-COO-03','P1-COO-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(38,'P1-COO-04','P1-COO-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(39,'P1-QUA-03','P1-COO-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(40,'P1-COO-05','P1-COO-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(41,'P1-QUA-02','P1-COO-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(42,'PR-ALG-01','P1-CIR-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(43,'P1-CIR-01','P1-CIR-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(44,'PR-ALG-03','P1-CIR-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(45,'P1-CIR-01','P1-CIR-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(46,'P1-CIR-02','P1-CIR-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(47,'PR-TRI-01','P1-CIR-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(48,'P1-FUN-06','P1-TRI-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(49,'P1-FUN-08','P1-TRI-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(50,'P1-CIR-01','P1-TRI-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(51,'PR-TRI-01','P1-TRI-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(52,'P1-CIR-01','P1-TRI-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(53,'P1-TRI-01','P1-TRI-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(54,'PR-CAL-01','P1-TRI-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(55,'P1-TRI-02','P1-TRI-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(56,'PR-ALG-03','P1-TRI-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(57,'P1-TRI-01','P1-TRI-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(58,'P1-TRI-02','P1-TRI-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(59,'P1-TRI-03','P1-TRI-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(60,'P1-TRI-04','P1-TRI-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(61,'PR-ALG-03','P1-SER-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(62,'PR-CNT-01','P1-SER-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(63,'PR-ALG-01','P1-SER-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(64,'PR-ALG-03','P1-SER-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(65,'P1-SER-02','P1-SER-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(66,'PR-EQN-01','P1-SER-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(67,'P1-SER-02','P1-SER-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(68,'PR-ALG-02','P1-SER-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(69,'P1-SER-04','P1-SER-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(70,'P1-QUA-04','P1-SER-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(71,'P1-COO-01','P1-DIF-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(72,'PR-ALG-03','P1-DIF-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(73,'P1-DIF-01','P1-DIF-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(74,'PR-ALG-02','P1-DIF-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(75,'P1-DIF-02','P1-DIF-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(76,'PR-ALG-03','P1-DIF-03','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(77,'P1-DIF-02','P1-DIF-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(78,'P1-COO-01','P1-DIF-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(79,'P1-COO-03','P1-DIF-04','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(80,'P1-DIF-02','P1-DIF-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(81,'P1-QUA-04','P1-DIF-05','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(82,'P1-DIF-03','P1-DIF-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(83,'P1-CIR-02','P1-DIF-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(84,'P1-CIR-03','P1-DIF-06','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(85,'P1-DIF-02','P1-DIF-07','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(86,'P1-DIF-05','P1-DIF-07','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(87,'P1-FUN-02','P1-DIF-07','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(88,'P1-DIF-02','P1-INT-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(89,'P1-DIF-03','P1-INT-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(90,'PR-ALG-02','P1-INT-01','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(91,'P1-INT-01','P1-INT-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false),
(92,'PR-EQN-01','P1-INT-02','P1','Prerequisite only; passing this edge does not award mastery in the target or another component.',false)
) as v(edge_no, from_node_code, to_skill_code, target_component_code, edge_rule, is_mastery_crediting)
on conflict (program_version_id, edge_no) do update
set from_node_code=excluded.from_node_code,
    to_skill_code=excluded.to_skill_code,
    target_component_code=excluded.target_component_code,
    edge_rule=excluded.edge_rule,
    is_mastery_crediting=false;

commit;
