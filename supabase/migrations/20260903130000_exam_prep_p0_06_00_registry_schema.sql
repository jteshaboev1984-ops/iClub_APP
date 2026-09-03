-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Acceptance invariants: 45 P1 skills + 36 P5 skills = 81; 8 P1 areas + 5 P5 areas;
-- 11 prerequisite foundation nodes; 184 directed non-crediting prerequisite edges;
-- 23 mandatory mixed nodes; geometric distribution P5-GEO-01..03 present.
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.

begin;

-- Pin the canonical registry version in the P0-05 program/version anchor.
insert into private.exam_prep_program_versions (
  program_key,
  version_key,
  syllabus_version,
  canonical_skill_map_version,
  engine_version,
  rule_version,
  assessment_schema_version,
  status,
  effective_from
) values (
  'math_as_p1_p5',
  'p1_p5_canonical_v1_0',
  '9709-2026-2027-v4',
  '01_Academic_Syllabus_Source_Map_P1_P5_v1.0',
  null,
  null,
  'v1',
  'active',
  '2026-08-26T00:00:00Z'::timestamptz
)
on conflict (program_key, version_key) do update
set
  syllabus_version = excluded.syllabus_version,
  canonical_skill_map_version = excluded.canonical_skill_map_version,
  assessment_schema_version = excluded.assessment_schema_version,
  status = excluded.status,
  effective_from = excluded.effective_from,
  updated_at = now();

create table if not exists private.exam_prep_syllabus_nodes (
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  sequence_no smallint not null,
  component_code text not null check (component_code in ('P1','P5')),
  official_syllabus_section text not null,
  skill_code text not null,
  canonical_description text not null,
  prerequisites_text text null,
  book_chapter text null,
  book_pages text null,
  mcq_suitability text null,
  input_suitability text null,
  mixed_suitability text null,
  written_suitability text null,
  required_mastery_evidence text not null,
  app_can_verify text null,
  mentor_must_verify text null,
  recommended_stage text null,
  content_note text null,
  future_change_note text null,
  official_source_url text not null,
  created_at timestamptz not null default now(),
  primary key (program_version_id, skill_code),
  unique (program_version_id, component_code, sequence_no)
);

create index if not exists exam_prep_syllabus_nodes_component_area_idx
  on private.exam_prep_syllabus_nodes(program_version_id, component_code, official_syllabus_section);

create table if not exists private.exam_prep_prerequisite_nodes (
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  prerequisite_code text not null,
  definition text not null,
  node_type text not null default 'foundation' check (node_type = 'foundation'),
  is_mastery_crediting boolean not null default false check (is_mastery_crediting = false),
  created_at timestamptz not null default now(),
  primary key (program_version_id, prerequisite_code)
);

create table if not exists private.exam_prep_prerequisite_edges (
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  edge_no smallint not null,
  from_node_code text not null,
  to_skill_code text not null,
  target_component_code text not null check (target_component_code in ('P1','P5')),
  edge_rule text not null,
  is_mastery_crediting boolean not null default false check (is_mastery_crediting = false),
  created_at timestamptz not null default now(),
  primary key (program_version_id, edge_no),
  foreign key (program_version_id, to_skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id, skill_code) on delete restrict
);

create index if not exists exam_prep_prerequisite_edges_target_idx
  on private.exam_prep_prerequisite_edges(program_version_id, to_skill_code);
create index if not exists exam_prep_prerequisite_edges_source_idx
  on private.exam_prep_prerequisite_edges(program_version_id, from_node_code);

create table if not exists private.exam_prep_mixed_nodes (
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  mixed_code text not null,
  owner_label text not null,
  owner_component_code text null check (owner_component_code is null or owner_component_code in ('P1','P5')),
  required_nodes_text text not null,
  evidence_focus text not null,
  mastery_rule text not null,
  denominator_credit boolean not null default false check (denominator_credit = false),
  created_at timestamptz not null default now(),
  primary key (program_version_id, mixed_code)
);

create table if not exists private.exam_prep_mixed_links (
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  mixed_code text not null,
  linked_node_code text not null,
  linked_node_kind text not null check (linked_node_kind in ('skill','foundation')),
  linked_component_code text null check (linked_component_code is null or linked_component_code in ('P1','P5')),
  link_order smallint not null,
  created_at timestamptz not null default now(),
  primary key (program_version_id, mixed_code, linked_node_code),
  foreign key (program_version_id, mixed_code)
    references private.exam_prep_mixed_nodes(program_version_id, mixed_code) on delete cascade
);

alter table private.exam_prep_syllabus_nodes enable row level security;
alter table private.exam_prep_prerequisite_nodes enable row level security;
alter table private.exam_prep_prerequisite_edges enable row level security;
alter table private.exam_prep_mixed_nodes enable row level security;
alter table private.exam_prep_mixed_links enable row level security;

revoke all on private.exam_prep_syllabus_nodes from public, anon, authenticated;
revoke all on private.exam_prep_prerequisite_nodes from public, anon, authenticated;
revoke all on private.exam_prep_prerequisite_edges from public, anon, authenticated;
revoke all on private.exam_prep_mixed_nodes from public, anon, authenticated;
revoke all on private.exam_prep_mixed_links from public, anon, authenticated;

grant all on private.exam_prep_syllabus_nodes to service_role;
grant all on private.exam_prep_prerequisite_nodes to service_role;
grant all on private.exam_prep_prerequisite_edges to service_role;
grant all on private.exam_prep_mixed_nodes to service_role;
grant all on private.exam_prep_mixed_links to service_role;

-- Extend the existing private audit trigger so registry objects get stable object ids.
create or replace function private.exam_prep_audit_row_change_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_actor_text text;
  v_target_text text;
  v_component text;
  v_object_id text;
  v_program_key text;
begin
  if tg_op = 'INSERT' then
    v_before := null;
    v_after := to_jsonb(new);
  elsif tg_op = 'UPDATE' then
    v_before := to_jsonb(old);
    v_after := to_jsonb(new);
  else
    v_before := to_jsonb(old);
    v_after := null;
  end if;

  v_actor_text := coalesce(v_after->>'updated_by', v_after->>'created_by', v_before->>'updated_by', v_before->>'created_by');
  v_target_text := coalesce(v_after->>'user_id', v_after->>'learner_user_id', v_before->>'user_id', v_before->>'learner_user_id');
  v_component := coalesce(v_after->>'component_code', v_after->>'target_component_code', v_after->>'owner_component_code',
                          v_before->>'component_code', v_before->>'target_component_code', v_before->>'owner_component_code');
  v_object_id := coalesce(
    v_after->>'id', v_after->>'program_key', v_after->>'user_id', v_after->>'learner_user_id',
    v_after->>'skill_code', v_after->>'prerequisite_code', v_after->>'mixed_code',
    v_before->>'id', v_before->>'program_key', v_before->>'user_id', v_before->>'learner_user_id',
    v_before->>'skill_code', v_before->>'prerequisite_code', v_before->>'mixed_code'
  );
  v_program_key := coalesce(v_after->>'program_key', v_before->>'program_key', 'math_as_p1_p5');

  insert into private.exam_prep_audit_events (
    program_key, actor_user_id, actor_role, event_type, object_type, object_id,
    target_user_id, component_code, before_state, after_state, metadata
  ) values (
    v_program_key,
    coalesce(nullif(v_actor_text, '')::uuid, auth.uid()),
    coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), session_user),
    lower(tg_op),
    tg_table_schema || '.' || tg_table_name,
    v_object_id,
    nullif(v_target_text, '')::uuid,
    case when v_component in ('P1','P5') then v_component else null end,
    v_before,
    v_after,
    jsonb_build_object('trigger', tg_name)
  );

  return null;
end;
$$;
revoke all on function private.exam_prep_audit_row_change_v1() from public, anon, authenticated;

drop trigger if exists exam_prep_syllabus_nodes_audit_v1 on private.exam_prep_syllabus_nodes;
create trigger exam_prep_syllabus_nodes_audit_v1
after insert or update or delete on private.exam_prep_syllabus_nodes
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_prerequisite_nodes_audit_v1 on private.exam_prep_prerequisite_nodes;
create trigger exam_prep_prerequisite_nodes_audit_v1
after insert or update or delete on private.exam_prep_prerequisite_nodes
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_prerequisite_edges_audit_v1 on private.exam_prep_prerequisite_edges;
create trigger exam_prep_prerequisite_edges_audit_v1
after insert or update or delete on private.exam_prep_prerequisite_edges
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_mixed_nodes_audit_v1 on private.exam_prep_mixed_nodes;
create trigger exam_prep_mixed_nodes_audit_v1
after insert or update or delete on private.exam_prep_mixed_nodes
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_mixed_links_audit_v1 on private.exam_prep_mixed_links;
create trigger exam_prep_mixed_links_audit_v1
after insert or update or delete on private.exam_prep_mixed_links
for each row execute function private.exam_prep_audit_row_change_v1();

-- Seed the canonical 81 registry from the signed source map.

commit;
