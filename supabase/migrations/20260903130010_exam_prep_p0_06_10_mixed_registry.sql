-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.

-- Mandatory mixed registry: 23 nodes / 77 canonical links.
-- MX-X-02 is an administrative cross-component timetable rule and therefore has
-- no linked mastery/prerequisite node; it never merges P1/P5 academic state.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_mixed_nodes(
  program_version_id, mixed_code, owner_label, owner_component_code,
  required_nodes_text, evidence_focus, mastery_rule, denominator_credit
)
select pv.id, v.mixed_code, v.owner_label, v.owner_component_code,
       v.required_nodes_text, v.evidence_focus, v.mastery_rule, v.denominator_credit
from pv
cross join (values
('MX-P1-01','P1','P1','P1-QUA-01; P1-QUA-03; P1-FUN-02; P1-FUN-06','Quadratics + function transformations: vertex/range/graph parameter.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-02','P1','P1','P1-QUA-02; P1-COO-02; P1-COO-06','Coordinate intersections/tangency through quadratic roots and discriminant.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-03','P1','P1','P1-FUN-02; P1-FUN-03; P1-FUN-04; P1-FUN-05','Domain/range + composition + inverse + graph relation.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-04','P1','P1','P1-COO-03; P1-COO-04; P1-COO-05','Lines + circles + perpendicular/tangent geometry.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-05','P1','P1','P1-CIR-02; P1-CIR-03; P1-TRI-02','Radian arc/sector + triangle geometry in composite figures.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-06','P1','P1','P1-TRI-01; P1-TRI-04; P1-TRI-05','Trig graph/identity/equation with interval completeness.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-07','P1','P1','P1-SER-01; P1-SER-03; P1-SER-04; P1-SER-05','Binomial coefficients + progression conditions/inverse parameters.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-08','P1','P1','P1-DIF-04; P1-DIF-05; P1-DIF-07; P1-FUN-02','Differentiation + tangent/stationary behaviour + range/sketch.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-09','P1','P1','P1-DIF-03; P1-DIF-06; P1-CIR-02; P1-CIR-03','Chain rule + connected rates + geometric model.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-10','P1','P1','P1-DIF-02; P1-INT-01; P1-INT-02','Derivative–antiderivative link with boundary condition.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-11','P1','P1','P1-QUA-03; P1-COO-02; P1-INT-03; P1-INT-04','Intersections + limits + signed/total area.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P1-12','P1','P1','P1-INT-04; P1-INT-05; P1-FUN-01','Select area versus volume model and justify limits.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-01','P5','P5','P5-DAT-03; P5-DAT-06; P5-DAT-07; P5-DAT-08','Representation + location/spread + contextual comparison.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-02','P5','P5','P5-DAT-04; P5-DAT-05; P5-DAT-09','Grouped data across histogram, cumulative frequency and summary measures.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-03','P5','P5','P5-CNT-04; P5-CNT-05; P5-PRO-02','Restricted counting used as a probability sample space.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-04','P5','P5','P5-PRO-04; P5-PRO-05; P5-PRO-06','Tree + conditional probability + independence decision.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-05','P5','P5','P5-DRV-01; P5-DRV-02; P5-DRV-03','Construct distribution + expectation + variance.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-06','P5','P5','P5-BIN-01; P5-GEO-01; P5-BIN-02; P5-GEO-02','Choose binomial versus geometric before calculation.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-07','P5','P5','P5-CNT-05; P5-PRO-05; P5-BIN-02','Counting/conditional setup feeding binomial probability.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-08','P5','P5','P5-NOR-03; P5-NOR-04; P5-NOR-05','Direct/inverse normal probability with unknown parameters.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-P5-09','P5','P5','P5-BIN-02; P5-BIN-03; P5-NOR-06','Binomial moments + normal approximation + continuity correction.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-X-01','Cross prerequisite only',null,'PR-ALG-03; PR-EQN-01 → P5-DAT-10/P5-BIN-03/P5-GEO-03/P5-NOR-05','P1-level algebra supports P5 parameter work; evidence credits P5 only and never uplifts P1.','Written mixed task + mentor review; recorded only in owner component.',false),
('MX-X-02','Cross administration',null,'P1 timed block || P5 timed block','Combined mock session may share a timetable, but scores, mastery and retests remain component-separated.','Written mixed task + mentor review; recorded only in owner component.',false)
) as v(mixed_code, owner_label, owner_component_code, required_nodes_text, evidence_focus, mastery_rule, denominator_credit)
on conflict (program_version_id, mixed_code) do update set
  owner_label = excluded.owner_label,
  owner_component_code = excluded.owner_component_code,
  required_nodes_text = excluded.required_nodes_text,
  evidence_focus = excluded.evidence_focus,
  mastery_rule = excluded.mastery_rule,
  denominator_credit = excluded.denominator_credit;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_mixed_links(
  program_version_id, mixed_code, linked_node_code, linked_node_kind,
  linked_component_code, link_order
)
select pv.id, v.mixed_code, v.linked_node_code, v.linked_node_kind,
       v.linked_component_code, v.link_order
from pv
cross join (values
('MX-P1-01','P1-QUA-01','skill','P1',1),('MX-P1-01','P1-QUA-03','skill','P1',2),('MX-P1-01','P1-FUN-02','skill','P1',3),('MX-P1-01','P1-FUN-06','skill','P1',4),
('MX-P1-02','P1-QUA-02','skill','P1',1),('MX-P1-02','P1-COO-02','skill','P1',2),('MX-P1-02','P1-COO-06','skill','P1',3),
('MX-P1-03','P1-FUN-02','skill','P1',1),('MX-P1-03','P1-FUN-03','skill','P1',2),('MX-P1-03','P1-FUN-04','skill','P1',3),('MX-P1-03','P1-FUN-05','skill','P1',4),
('MX-P1-04','P1-COO-03','skill','P1',1),('MX-P1-04','P1-COO-04','skill','P1',2),('MX-P1-04','P1-COO-05','skill','P1',3),
('MX-P1-05','P1-CIR-02','skill','P1',1),('MX-P1-05','P1-CIR-03','skill','P1',2),('MX-P1-05','P1-TRI-02','skill','P1',3),
('MX-P1-06','P1-TRI-01','skill','P1',1),('MX-P1-06','P1-TRI-04','skill','P1',2),('MX-P1-06','P1-TRI-05','skill','P1',3),
('MX-P1-07','P1-SER-01','skill','P1',1),('MX-P1-07','P1-SER-03','skill','P1',2),('MX-P1-07','P1-SER-04','skill','P1',3),('MX-P1-07','P1-SER-05','skill','P1',4),
('MX-P1-08','P1-DIF-04','skill','P1',1),('MX-P1-08','P1-DIF-05','skill','P1',2),('MX-P1-08','P1-DIF-07','skill','P1',3),('MX-P1-08','P1-FUN-02','skill','P1',4),
('MX-P1-09','P1-DIF-03','skill','P1',1),('MX-P1-09','P1-DIF-06','skill','P1',2),('MX-P1-09','P1-CIR-02','skill','P1',3),('MX-P1-09','P1-CIR-03','skill','P1',4),
('MX-P1-10','P1-DIF-02','skill','P1',1),('MX-P1-10','P1-INT-01','skill','P1',2),('MX-P1-10','P1-INT-02','skill','P1',3),
('MX-P1-11','P1-QUA-03','skill','P1',1),('MX-P1-11','P1-COO-02','skill','P1',2),('MX-P1-11','P1-INT-03','skill','P1',3),('MX-P1-11','P1-INT-04','skill','P1',4),
('MX-P1-12','P1-INT-04','skill','P1',1),('MX-P1-12','P1-INT-05','skill','P1',2),('MX-P1-12','P1-FUN-01','skill','P1',3),
('MX-P5-01','P5-DAT-03','skill','P5',1),('MX-P5-01','P5-DAT-06','skill','P5',2),('MX-P5-01','P5-DAT-07','skill','P5',3),('MX-P5-01','P5-DAT-08','skill','P5',4),
('MX-P5-02','P5-DAT-04','skill','P5',1),('MX-P5-02','P5-DAT-05','skill','P5',2),('MX-P5-02','P5-DAT-09','skill','P5',3),
('MX-P5-03','P5-CNT-04','skill','P5',1),('MX-P5-03','P5-CNT-05','skill','P5',2),('MX-P5-03','P5-PRO-02','skill','P5',3),
('MX-P5-04','P5-PRO-04','skill','P5',1),('MX-P5-04','P5-PRO-05','skill','P5',2),('MX-P5-04','P5-PRO-06','skill','P5',3),
('MX-P5-05','P5-DRV-01','skill','P5',1),('MX-P5-05','P5-DRV-02','skill','P5',2),('MX-P5-05','P5-DRV-03','skill','P5',3),
('MX-P5-06','P5-BIN-01','skill','P5',1),('MX-P5-06','P5-GEO-01','skill','P5',2),('MX-P5-06','P5-BIN-02','skill','P5',3),('MX-P5-06','P5-GEO-02','skill','P5',4),
('MX-P5-07','P5-CNT-05','skill','P5',1),('MX-P5-07','P5-PRO-05','skill','P5',2),('MX-P5-07','P5-BIN-02','skill','P5',3),
('MX-P5-08','P5-NOR-03','skill','P5',1),('MX-P5-08','P5-NOR-04','skill','P5',2),('MX-P5-08','P5-NOR-05','skill','P5',3),
('MX-P5-09','P5-BIN-02','skill','P5',1),('MX-P5-09','P5-BIN-03','skill','P5',2),('MX-P5-09','P5-NOR-06','skill','P5',3),
('MX-X-01','PR-ALG-03','foundation',null,1),('MX-X-01','PR-EQN-01','foundation',null,2),('MX-X-01','P5-DAT-10','skill','P5',3),('MX-X-01','P5-BIN-03','skill','P5',4),('MX-X-01','P5-GEO-03','skill','P5',5),('MX-X-01','P5-NOR-05','skill','P5',6)
) as v(mixed_code, linked_node_code, linked_node_kind, linked_component_code, link_order)
on conflict (program_version_id, mixed_code, linked_node_code) do update set
  linked_node_kind = excluded.linked_node_kind,
  linked_component_code = excluded.linked_component_code,
  link_order = excluded.link_order;

commit;
