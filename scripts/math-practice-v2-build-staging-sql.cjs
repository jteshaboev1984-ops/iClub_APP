#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..');
const CONTENT_ROOT = path.join(ROOT, 'content', 'math', 'practice_v2');
const RELEASE_VERSION = 'math_p1_practice_v2_2026_10_07';

const MODULES = [
  ['p1_quadratics', ['P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06']],
  ['p2_functions', ['P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08']],
  ['p3_coordinate_geometry', ['P1-COO-01','P1-COO-02','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06']],
  ['p4_circular_trigonometry', ['P1-CIR-01','P1-CIR-02','P1-CIR-03','P1-TRI-01','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05']],
  ['p5_binomial_series', ['P1-SER-01','P1-SER-02','P1-SER-03','P1-SER-04','P1-SER-05']],
  ['p6_differentiation', ['P1-DIF-01','P1-DIF-02','P1-DIF-03','P1-DIF-04','P1-DIF-05','P1-DIF-06','P1-DIF-07']],
  ['p7_integration', ['P1-INT-01','P1-INT-02','P1-INT-03','P1-INT-04','P1-INT-05']],
];

const SKILL_TITLE = {
  'P1-CIR-01':'Degrees and radians',
  'P1-CIR-02':'Arc length',
  'P1-CIR-03':'Sector area and circular segments',
  'P1-COO-01':'Equation of a straight line',
  'P1-COO-02':'Distance, midpoint and intersection',
  'P1-COO-03':'Parallel and perpendicular lines',
  'P1-COO-04':'Equation of a circle',
  'P1-COO-05':'Lines and circles',
  'P1-COO-06':'Intersections and tangency',
  'P1-DIF-01':'Meaning of the derivative',
  'P1-DIF-02':'Differentiating powers',
  'P1-DIF-03':'Chain rule',
  'P1-DIF-04':'Tangent and normal',
  'P1-DIF-05':'Increasing and decreasing functions',
  'P1-DIF-06':'Rates of change',
  'P1-DIF-07':'Stationary points and optimisation',
  'P1-FUN-01':'Functions: domain and range',
  'P1-FUN-02':'Range of a function',
  'P1-FUN-03':'Composite functions',
  'P1-FUN-04':'Inverse functions',
  'P1-FUN-05':'Graphs of inverse functions',
  'P1-FUN-06':'Graph translations',
  'P1-FUN-07':'Graph reflections',
  'P1-FUN-08':'Graph stretches and compressions',
  'P1-INT-01':'Antiderivatives',
  'P1-INT-02':'Constant of integration',
  'P1-INT-03':'Definite integrals',
  'P1-INT-04':'Area between curves',
  'P1-INT-05':'Volume of revolution',
  'P1-QUA-01':'Completing the square',
  'P1-QUA-02':'Discriminant and roots',
  'P1-QUA-03':'Solving quadratic equations',
  'P1-QUA-04':'Quadratic inequalities',
  'P1-QUA-05':'Linear–quadratic systems',
  'P1-QUA-06':'Reducing to a quadratic',
  'P1-SER-01':'Binomial expansion',
  'P1-SER-02':'Arithmetic and geometric progressions',
  'P1-SER-03':'Arithmetic progressions',
  'P1-SER-04':'Geometric progressions',
  'P1-SER-05':'Infinite geometric series',
  'P1-TRI-01':'Graphs of sin, cos and tan',
  'P1-TRI-02':'Exact trigonometric values',
  'P1-TRI-03':'Inverse trigonometric functions',
  'P1-TRI-04':'Basic trigonometric identities',
  'P1-TRI-05':'Trigonometric equations',
};

function topicFor(skill) {
  if (skill.startsWith('P1-QUA-')) return 'Quadratics';
  if (skill.startsWith('P1-FUN-')) return 'Functions and graphs';
  if (skill.startsWith('P1-COO-')) return 'Coordinate geometry';
  if (skill.startsWith('P1-CIR-')) return 'Circular measure';
  if (skill.startsWith('P1-TRI-')) return 'Trigonometry';
  if (skill === 'P1-SER-01') return 'Binomial expansion';
  if (skill.startsWith('P1-SER-')) return 'Series';
  if (skill.startsWith('P1-DIF-')) return 'Differentiation';
  if (skill.startsWith('P1-INT-')) return 'Integration';
  throw new Error(`No learner topic for ${skill}`);
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map((k) => [k, stable(value[k])]));
  }
  return value;
}

function hash(value) {
  return crypto.createHash('sha256').update(JSON.stringify(stable(value))).digest('hex');
}

function sqlLiteral(value) {
  if (value === null || value === undefined) return 'null';
  return "'" + String(value).replace(/'/g, "''") + "'";
}

const catalogs = new Map();
const questions = [];

for (const [dirName, skills] of MODULES) {
  const dir = path.join(CONTENT_ROOT, dirName);
  const catalog = JSON.parse(fs.readFileSync(path.join(dir, 'diagnostic_catalog.json'), 'utf8'));

  for (const d of catalog.diagnostics || []) {
    if (catalogs.has(d.code)) throw new Error(`Duplicate diagnostic code ${d.code}`);
    const row = {
      diagnostic_code: d.code,
      release_version: RELEASE_VERSION,
      skill_code: d.skill,
      mistake_type: d.mistake_type,
      inference_strength: d.inference_strength,
      feedback_ru: d.feedback.ru,
      feedback_uz: d.feedback.uz,
      feedback_en: d.feedback.en,
      next_action_ru: d.next_action.ru,
      next_action_uz: d.next_action.uz,
      next_action_en: d.next_action.en,
    };
    row.content_hash = hash(row);
    catalogs.set(d.code, row);
  }

  for (const skill of skills) {
    const file = path.join(dir, `${skill}.json`);
    const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));

    for (const q of parsed.questions || []) {
      const options = q.qtype === 'mcq'
        ? [...q.options].sort((a,b) => a.key.localeCompare(b.key))
        : [];

      const publicOptions = (lang) => q.qtype === 'mcq'
        ? JSON.stringify(options.map((o) => o.text[lang]))
        : null;

      const diagMappings = [];
      if (q.qtype === 'mcq') {
        for (const option of options) {
          if (option.key === q.correct_answer) continue;
          if (!option.diagnostic_code) throw new Error(`${q.key}: wrong MCQ option missing diagnostic`);
          if (!catalogs.has(option.diagnostic_code)) throw new Error(`${q.key}: unknown diagnostic ${option.diagnostic_code}`);
          diagMappings.push({
            answer_kind:'mcq_option',
            answer_key:option.key,
            answer_value:null,
            diagnostic_code:option.diagnostic_code,
          });
        }
      } else {
        for (const rule of q.diagnostic_rules || []) {
          if (!catalogs.has(rule.diagnostic_code)) throw new Error(`${q.key}: unknown input diagnostic ${rule.diagnostic_code}`);
          diagMappings.push({
            answer_kind:'input_exact',
            answer_key:null,
            answer_value:String(rule.answer_match),
            diagnostic_code:rule.diagnostic_code,
          });
        }
      }

      const keyMatch = /^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key);
      if (!keyMatch) throw new Error(`${q.key}: bad key`);

      const row = {
        content_key:q.key,
        release_version:RELEASE_VERSION,
        global_order:Number(keyMatch[1]),
        practice_no:Number(q.practice_no),
        primary_skill_code:q.primary_skill,
        secondary_skill_codes:q.secondary_skills || [],
        question_role:q.role,
        source_ref:q.source_ref,
        topic:topicFor(q.primary_skill),
        subtopic:SKILL_TITLE[q.primary_skill],
        difficulty:q.difficulty,
        qtype:q.qtype,
        question_text:q.question.en,
        question_text_ru:q.question.ru,
        question_text_uz:q.question.uz,
        question_text_en:q.question.en,
        options_text:publicOptions('en'),
        options_text_ru:publicOptions('ru'),
        options_text_uz:publicOptions('uz'),
        options_text_en:publicOptions('en'),
        correct_answer:q.qtype === 'mcq' ? q.correct_answer : q.answer_contract.canonical_answer,
        explanation:q.explanation.en,
        explanation_ru:q.explanation.ru,
        explanation_uz:q.explanation.uz,
        explanation_en:q.explanation.en,
        book_ref:q.source_ref,
        time_limit_sec:q.difficulty === 'easy' ? 45 : q.difficulty === 'hard' ? 90 : 60,
        answer_contract:q.qtype === 'input' ? q.answer_contract : {},
        diagnostics:diagMappings,
      };

      row.content_hash = hash({
        content_key:row.content_key,
        practice_no:row.practice_no,
        primary_skill_code:row.primary_skill_code,
        secondary_skill_codes:row.secondary_skill_codes,
        question_role:row.question_role,
        source_ref:row.source_ref,
        topic:row.topic,
        subtopic:row.subtopic,
        difficulty:row.difficulty,
        qtype:row.qtype,
        question_text_ru:row.question_text_ru,
        question_text_uz:row.question_text_uz,
        question_text_en:row.question_text_en,
        options_text_ru:row.options_text_ru,
        options_text_uz:row.options_text_uz,
        options_text_en:row.options_text_en,
        correct_answer:row.correct_answer,
        explanation_ru:row.explanation_ru,
        explanation_uz:row.explanation_uz,
        explanation_en:row.explanation_en,
        answer_contract:row.answer_contract,
        diagnostics:row.diagnostics,
      });

      questions.push(row);
    }
  }
}

questions.sort((a,b) => a.global_order-b.global_order);

const practiceOrderCounters = new Map();
for (const q of questions) {
  const next = (practiceOrderCounters.get(q.practice_no) || 0) + 1;
  practiceOrderCounters.set(q.practice_no, next);
  q.practice_order = next;
}

if (questions.length !== 495) throw new Error(`Expected 495 questions, got ${questions.length}`);
if (new Set(questions.map((q) => q.content_key)).size !== 495) throw new Error('Duplicate content keys');
for (let i=1;i<=495;i++) {
  if (questions[i-1].global_order !== i) throw new Error(`Missing global order ${i}`);
}
if (Object.keys(SKILL_TITLE).length !== 45) throw new Error('Skill-title map must cover 45 skills');

const diagnosticMappings = questions.reduce((n,q) => n+q.diagnostics.length,0);
const catalogRows = [...catalogs.values()].sort((a,b) => a.diagnostic_code.localeCompare(b.diagnostic_code));
const manifestHash = hash({release_version:RELEASE_VERSION,catalogRows,questions});

function generateSql() {
  const catalogJson = JSON.stringify(catalogRows);
  const questionsJson = JSON.stringify(questions);

  return `-- GENERATED FILE — Mathematics P1 Practice v2 staging package
-- Generator: scripts/math-practice-v2-build-staging-sql.cjs
-- Release: ${RELEASE_VERSION}
-- Manifest SHA-256: ${manifestHash}
--
-- STAGING ONLY:
-- - new questions are inserted is_active=false / quality_status='draft';
-- - new pool memberships are inserted is_active=false;
-- - diagnostics are inserted quality_status='draft';
-- - private metadata is approved but runtime-disabled;
-- - no existing Practice membership, attempt, answer, session or Tour row is changed.

begin;

do $practice_v2_stage$
declare
  v_subject_id bigint;
  v_pool_id bigint;
  v_qid bigint;
  v_existing_hash text;
  v_item jsonb;
  v_map jsonb;
  v_cat private.practice_v2_diagnostic_catalog%rowtype;
  v_catalog jsonb := $catalog$${catalogJson}$catalog$::jsonb;
  v_questions jsonb := $questions$${questionsJson}$questions$::jsonb;
  v_count integer;
begin
  select s.id into v_subject_id
  from public.subjects s
  where s.subject_key='mathematics'
    and s.is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'math_subject_not_found';
  end if;

  select count(*)::integer into v_count
  from public.practice_pools p
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7;

  if v_count<>7 then
    raise exception 'expected_7_math_practice_pools_found_%',v_count;
  end if;

  for v_item in select value from jsonb_array_elements(v_catalog)
  loop
    select c.content_hash into v_existing_hash
    from private.practice_v2_diagnostic_catalog c
    where c.diagnostic_code=v_item->>'diagnostic_code';

    if found then
      if v_existing_hash<>(v_item->>'content_hash') then
        raise exception 'diagnostic_hash_conflict_%',v_item->>'diagnostic_code';
      end if;
    else
      insert into private.practice_v2_diagnostic_catalog(
        diagnostic_code,release_version,skill_code,mistake_type,inference_strength,
        feedback_ru,feedback_uz,feedback_en,
        next_action_ru,next_action_uz,next_action_en,
        approval_status,is_runtime_allowed,content_hash,approved_at
      ) values(
        v_item->>'diagnostic_code',
        v_item->>'release_version',
        v_item->>'skill_code',
        v_item->>'mistake_type',
        v_item->>'inference_strength',
        v_item->>'feedback_ru',
        v_item->>'feedback_uz',
        v_item->>'feedback_en',
        v_item->>'next_action_ru',
        v_item->>'next_action_uz',
        v_item->>'next_action_en',
        'approved',
        false,
        v_item->>'content_hash',
        now()
      );
    end if;
  end loop;

  for v_item in select value from jsonb_array_elements(v_questions)
  loop
    v_qid:=null;
    v_existing_hash:=null;

    select m.question_id,m.content_hash
    into v_qid,v_existing_hash
    from private.practice_v2_question_meta m
    where m.content_key=v_item->>'content_key';

    if found then
      if v_existing_hash<>(v_item->>'content_hash') then
        raise exception 'question_hash_conflict_%',v_item->>'content_key';
      end if;
      continue;
    end if;

    select p.id into v_pool_id
    from public.practice_pools p
    where p.subject_id=v_subject_id
      and p.tour_no=(v_item->>'practice_no')::smallint
    limit 1;

    if v_pool_id is null then
      raise exception 'practice_pool_missing_%',v_item->>'practice_no';
    end if;

    insert into public.questions(
      subject_id,topic,subtopic,difficulty,qtype,
      question_text,options_text,correct_answer,explanation,
      image_url,is_active,
      question_text_ru,question_text_uz,question_text_en,
      options_text_ru,options_text_uz,options_text_en,
      explanation_ru,explanation_uz,explanation_en,
      book_ref,time_limit_sec,quality_flag,quality_status
    ) values(
      v_subject_id,
      v_item->>'topic',
      v_item->>'subtopic',
      v_item->>'difficulty',
      v_item->>'qtype',
      v_item->>'question_text',
      nullif(v_item->>'options_text',''),
      v_item->>'correct_answer',
      v_item->>'explanation',
      null,
      false,
      v_item->>'question_text_ru',
      v_item->>'question_text_uz',
      v_item->>'question_text_en',
      nullif(v_item->>'options_text_ru',''),
      nullif(v_item->>'options_text_uz',''),
      nullif(v_item->>'options_text_en',''),
      v_item->>'explanation_ru',
      v_item->>'explanation_uz',
      v_item->>'explanation_en',
      v_item->>'book_ref',
      (v_item->>'time_limit_sec')::integer,
      null,
      'draft'
    )
    returning id into v_qid;

    insert into private.practice_v2_question_meta(
      question_id,content_key,release_version,practice_no,
      primary_skill_code,secondary_skill_codes,question_role,source_ref,
      answer_contract,content_hash,
      qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,
      lifecycle_state,is_runtime_allowed,approved_at
    ) values(
      v_qid,
      v_item->>'content_key',
      v_item->>'release_version',
      (v_item->>'practice_no')::smallint,
      v_item->>'primary_skill_code',
      array(select jsonb_array_elements_text(v_item->'secondary_skill_codes')),
      v_item->>'question_role',
      v_item->>'source_ref',
      coalesce(v_item->'answer_contract','{}'::jsonb),
      v_item->>'content_hash',
      'passed','passed','passed','passed',
      'approved',
      false,
      now()
    );

    insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
    values(v_pool_id,v_qid,(v_item->>'practice_order')::integer,false);

    for v_map in
      select value from jsonb_array_elements(coalesce(v_item->'diagnostics','[]'::jsonb))
    loop
      select * into v_cat
      from private.practice_v2_diagnostic_catalog c
      where c.diagnostic_code=v_map->>'diagnostic_code';

      if v_cat.diagnostic_code is null then
        raise exception 'diagnostic_catalog_missing_%',v_map->>'diagnostic_code';
      end if;

      insert into public.question_answer_diagnostics(
        question_id,answer_kind,answer_key,answer_value,is_correct,
        mistake_type,weak_skill,
        feedback_ru,feedback_uz,feedback_en,
        next_action_ru,next_action_uz,next_action_en,
        rule_json,quality_status
      ) values(
        v_qid,
        v_map->>'answer_kind',
        nullif(v_map->>'answer_key',''),
        nullif(v_map->>'answer_value',''),
        false,
        v_cat.mistake_type,
        v_cat.skill_code,
        v_cat.feedback_ru,
        v_cat.feedback_uz,
        v_cat.feedback_en,
        v_cat.next_action_ru,
        v_cat.next_action_uz,
        v_cat.next_action_en,
        jsonb_build_object(
          'diagnostic_code',v_cat.diagnostic_code,
          'inference_strength',v_cat.inference_strength,
          'release_version','${RELEASE_VERSION}'
        ),
        'draft'
      );
    end loop;
  end loop;

  select count(*)::integer into v_count
  from private.practice_v2_question_meta m
  where m.release_version='${RELEASE_VERSION}';

  if v_count<>495 then
    raise exception 'staged_question_count_expected_495_found_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join private.practice_v2_question_meta m on m.question_id=ppq.question_id
  where m.release_version='${RELEASE_VERSION}'
    and ppq.is_active is false;

  if v_count<>495 then
    raise exception 'inactive_membership_count_expected_495_found_%',v_count;
  end if;

  -- Membership order must restart at 1 inside every Practice.
  if exists(
    select 1
    from public.practice_pools p
    join public.practice_pool_questions ppq on ppq.pool_id=p.id
    join private.practice_v2_question_meta m on m.question_id=ppq.question_id
    where m.release_version='${RELEASE_VERSION}'
    group by p.id,m.practice_no
    having min(ppq.order_no)<>1
       or max(ppq.order_no)<>count(*)::integer
       or count(distinct ppq.order_no)<>count(*)
  ) then
    raise exception 'staged_membership_order_not_contiguous_per_practice';
  end if;

  select count(*)::integer into v_count
  from public.question_answer_diagnostics d
  join private.practice_v2_question_meta m on m.question_id=d.question_id
  where m.release_version='${RELEASE_VERSION}';

  if v_count<>${diagnosticMappings} then
    raise exception 'diagnostic_mapping_count_expected_${diagnosticMappings}_found_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.tour_questions tq
  join private.practice_v2_question_meta m on m.question_id=tq.question_id
  where m.release_version='${RELEASE_VERSION}';

  if v_count<>0 then
    raise exception 'staged_practice_v2_questions_must_not_be_tour_questions';
  end if;

  select count(*)::integer into v_count
  from public.questions q
  join private.practice_v2_question_meta m on m.question_id=q.id
  where m.release_version='${RELEASE_VERSION}'
    and (q.is_active is true or q.quality_status<>'draft' or m.is_runtime_allowed is true);

  if v_count<>0 then
    raise exception 'staging_must_not_publish_runtime_content';
  end if;
end;
$practice_v2_stage$;

commit;
`;
}

const args = process.argv.slice(2);
const outIndex = args.indexOf('--out');
const shouldCheck = args.includes('--check') || outIndex < 0;

if (outIndex >= 0) {
  const target = args[outIndex+1];
  if (!target) throw new Error('--out requires a path');
  fs.writeFileSync(path.resolve(process.cwd(),target), generateSql(), 'utf8');
}

const summary = {
  releaseVersion:RELEASE_VERSION,
  manifestHash,
  questions:questions.length,
  catalogs:catalogRows.length,
  diagnosticMappings,
  memberships:questions.length,
  practiceOrders:Object.fromEntries([...practiceOrderCounters.entries()].sort((a,b)=>a[0]-b[0])),
  mcq:questions.filter((q)=>q.qtype==='mcq').length,
  input:questions.filter((q)=>q.qtype==='input').length,
  generatedSqlBytes:Buffer.byteLength(generateSql(),'utf8'),
};

if (shouldCheck) console.log(JSON.stringify(summary,null,2));
