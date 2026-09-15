'use strict';

// P2-78 isolated concurrency/service-transition regression.
// No network/provider calls. This script talks only to the disposable PostgreSQL
// service started by GitHub Actions.
const { Pool } = require('pg');

const RUN_ID = 'SV-P278-CONCURRENCY';
const pool = new Pool({
  host: process.env.PGHOST || '127.0.0.1',
  port: Number(process.env.PGPORT || 5432),
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'postgres',
  database: process.env.PGDATABASE || 'postgres',
  max: Number(process.env.P278_POOL_SIZE || 48),
  idleTimeoutMillis: 5000,
  connectionTimeoutMillis: 10000,
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function learnerOrd(key) {
  const m = /L(\d{4})$/.exec(key);
  return m ? Number(m[1]) : null;
}
function mentorOrd(key) {
  const m = /M(\d{2})$/.exec(key);
  return m ? Number(m[1]) : null;
}

async function txAs(userId, fn, commit = false) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      "select set_config('request.jwt.claim.sub',$1,true), set_config('request.jwt.claim.role','authenticated',true)",
      [userId]
    );
    const result = await fn(client);
    await client.query(commit ? 'COMMIT' : 'ROLLBACK');
    return result;
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
}

async function loadPeople() {
  const { rows } = await pool.query(`
    select user_id::text,fixture_profile_key,identity_kind
    from private.exam_prep_synthetic_identities
    where run_id=$1 and identity_status='active'
    order by fixture_profile_key`, [RUN_ID]);
  const learners = rows.filter(r => r.identity_kind === 'learner').map(r => ({...r, ord: learnerOrd(r.fixture_profile_key)}));
  const mentors = rows.filter(r => r.identity_kind === 'mentor').map(r => ({...r, ord: mentorOrd(r.fixture_profile_key)}));
  learners.sort((a,b) => a.ord-b.ord);
  mentors.sort((a,b) => a.ord-b.ord);
  assert(learners.length === 600, `expected 600 learners, got ${learners.length}`);
  assert(mentors.length === 10, `expected 10 mentors, got ${mentors.length}`);
  return { learners, mentors };
}

async function capability(userId) {
  return txAs(userId, async client => {
    const { rows } = await client.query('select * from public.get_exam_prep_capabilities_v1()');
    assert(rows.length === 1, 'capability RPC returned unexpected row count');
    return rows[0];
  });
}

async function capabilityWave(learners, mode) {
  const rows = await Promise.all(learners.map(async learner => ({ learner, cap: await capability(learner.user_id) })));
  for (const { learner, cap } of rows) {
    const expectedAi = mode.aiEnabled && learner.ord >= 301;
    const expectedMentorEntitled = learner.ord <= 30;
    const expectedAssignment = mode.mentorEnabled && learner.ord <= 10 && !mode.pausedLearners?.has(learner.ord);
    assert(cap.core_access === true, `${mode.name}: learner ${learner.ord} lost Core`);
    assert(cap.kill_switch === false, `${mode.name}: learner ${learner.ord} saw kill switch`);
    assert(cap.ai_assist === expectedAi, `${mode.name}: learner ${learner.ord} AI mismatch got=${cap.ai_assist} expected=${expectedAi}`);
    assert(cap.mentor_care_entitled === expectedMentorEntitled,
      `${mode.name}: learner ${learner.ord} Mentor entitlement mismatch got=${cap.mentor_care_entitled}`);
    assert(cap.mentor_assignment_active === expectedAssignment,
      `${mode.name}: learner ${learner.ord} assignment mismatch got=${cap.mentor_assignment_active} expected=${expectedAssignment}`);
    assert(cap.mentor_authority === expectedAssignment,
      `${mode.name}: learner ${learner.ord} authority mismatch got=${cap.mentor_authority} expected=${expectedAssignment}`);
  }
  return rows;
}

async function queueFor(mentor) {
  return txAs(mentor.user_id, async client => {
    const { rows } = await client.query('select public.get_exam_prep_mentor_queue_safe_v1() as q');
    return rows[0].q;
  });
}

async function queueWave(mentors) {
  const results = await Promise.all(mentors.map(async mentor => ({ mentor, queue: await queueFor(mentor) })));
  return results;
}

async function assertOneScopeEach(mentors, label) {
  const results = await queueWave(mentors);
  const all = [];
  for (const { mentor, queue } of results) {
    assert(Array.isArray(queue), `${label}: mentor ${mentor.ord} queue is not JSON array`);
    assert(queue.length === 1, `${label}: mentor ${mentor.ord} expected 1 visible scope, got ${queue.length}`);
    all.push(queue[0]);
  }
  const learners = new Set(all.map(x => String(x.learner_user_id)));
  const queueIds = new Set(all.map(x => String(x.queue_item_id)));
  assert(learners.size === 10, `${label}: expected 10 distinct learner scopes, got ${learners.size}`);
  assert(queueIds.size === 10, `${label}: expected 10 distinct queue items, got ${queueIds.size}`);
  return results;
}

async function assertQueueHidden(mentors, expectedTotal, label) {
  const results = await queueWave(mentors);
  const total = results.reduce((n, x) => n + x.queue.length, 0);
  assert(total === expectedTotal, `${label}: expected ${expectedTotal} visible queue items, got ${total}`);
  return results;
}

async function academicFingerprint() {
  const { rows } = await pool.query(`
    with u as (
      select user_id
      from private.exam_prep_synthetic_identities
      where run_id=$1 and identity_kind='learner'
        and exists(select 1 from private.exam_prep_evidence_events e where e.user_id=exam_prep_synthetic_identities.user_id)
    )
    select jsonb_build_object(
      'evidence_count',(select count(*) from private.exam_prep_evidence_events e where e.user_id in (select user_id from u)),
      'evidence_hash',(select md5(coalesce(string_agg(to_jsonb(e)::text,'|' order by e.id::text),'[]')) from private.exam_prep_evidence_events e where e.user_id in (select user_id from u)),
      'sessions_count',(select count(*) from private.exam_prep_sessions s where s.user_id in (select user_id from u)),
      'sessions_hash',(select md5(coalesce(string_agg(to_jsonb(s)::text,'|' order by s.id::text),'[]')) from private.exam_prep_sessions s where s.user_id in (select user_id from u)),
      'responses_count',(select count(*) from private.exam_prep_responses r where r.user_id in (select user_id from u)),
      'responses_hash',(select md5(coalesce(string_agg(to_jsonb(r)::text,'|' order by r.id::text),'[]')) from private.exam_prep_responses r where r.user_id in (select user_id from u)),
      'skill_count',(select count(*) from private.exam_prep_skill_states s where s.user_id in (select user_id from u)),
      'skill_hash',(select md5(coalesce(string_agg(to_jsonb(s)::text,'|' order by s.user_id::text,s.component_code,s.skill_code,s.engine_version),'[]')) from private.exam_prep_skill_states s where s.user_id in (select user_id from u)),
      'placement_count',(select count(*) from private.exam_prep_component_placements p where p.user_id in (select user_id from u)),
      'placement_hash',(select md5(coalesce(string_agg(to_jsonb(p)::text,'|' order by p.user_id::text,p.component_code),'[]')) from private.exam_prep_component_placements p where p.user_id in (select user_id from u)),
      'stage_count',(select count(*) from private.exam_prep_stage_states s where s.user_id in (select user_id from u)),
      'stage_hash',(select md5(coalesce(string_agg(to_jsonb(s)::text,'|' order by s.user_id::text,s.component_code,s.engine_version),'[]')) from private.exam_prep_stage_states s where s.user_id in (select user_id from u)),
      'correction_count',(select count(*) from private.exam_prep_correction_cases c where c.user_id in (select user_id from u)),
      'correction_hash',(select md5(coalesce(string_agg(to_jsonb(c)::text,'|' order by c.id::text),'[]')) from private.exam_prep_correction_cases c where c.user_id in (select user_id from u)),
      'retest_count',(select count(*) from private.exam_prep_retest_events r where r.user_id in (select user_id from u)),
      'retest_hash',(select md5(coalesce(string_agg(to_jsonb(r)::text,'|' order by r.id::text),'[]')) from private.exam_prep_retest_events r where r.user_id in (select user_id from u)),
      'readiness_count',(select count(*) from private.exam_prep_readiness_signoffs r where r.learner_user_id in (select user_id from u)),
      'readiness_hash',(select md5(coalesce(string_agg(to_jsonb(r)::text,'|' order by r.id::text),'[]')) from private.exam_prep_readiness_signoffs r where r.learner_user_id in (select user_id from u))
    ) as fp`, [RUN_ID]);
  return rows[0].fp;
}

async function setFlags({ aiEnabled, mentorEnabled }) {
  await pool.query(`update private.exam_prep_feature_config
                    set ai_enabled=$1,mentor_enabled=$2,updated_at=now()
                    where id=1`, [aiEnabled, mentorEnabled]);
}

async function wrongScopeReviewWave(mentors, queueResults) {
  const queueByMentor = new Map(queueResults.map(x => [x.mentor.ord, x.queue[0].queue_item_id]));
  await Promise.all(mentors.map(async mentor => {
    const targetOrd = mentor.ord === 10 ? 1 : mentor.ord + 1;
    const targetQueue = queueByMentor.get(targetOrd);
    let denied = false;
    try {
      await txAs(mentor.user_id, async client => {
        await client.query(
          `select public.submit_exam_prep_mentor_review_safe_v1($1,'verified','p278_cross_scope',
            'P2-78 cross-mentor review must fail closed.',4::smallint,'{}'::jsonb)`,
          [targetQueue]
        );
      });
    } catch (err) {
      if (String(err.message).includes('exam_prep_mentor_queue_not_found')) denied = true;
      else throw err;
    }
    assert(denied, `mentor ${mentor.ord} could review mentor ${targetOrd} queue item`);
  }));
}

async function privateTableDeniedWave(learners) {
  const sample = learners.filter(x => x.ord <= 10 || [11,30,301,600].includes(x.ord));
  await Promise.all(sample.map(async learner => {
    const client = await pool.connect();
    let denied = false;
    try {
      await client.query('BEGIN');
      await client.query("select set_config('request.jwt.claim.sub',$1,true),set_config('request.jwt.claim.role','authenticated',true)",[learner.user_id]);
      await client.query('set local role authenticated');
      try {
        await client.query('select * from private.exam_prep_mentor_queue_items limit 1');
      } catch (err) {
        denied = err.code === '42501' || /permission denied/i.test(String(err.message));
      }
      await client.query('ROLLBACK');
    } catch (err) {
      try { await client.query('ROLLBACK'); } catch (_) {}
      throw err;
    } finally {
      client.release();
    }
    assert(denied, `learner ${learner.ord} gained direct private mentor-table read access`);
  }));
}

async function mutateAsOps(opsId, sql, values) {
  return txAs(opsId, async client => {
    const { rows } = await client.query(sql, values);
    return rows[0].result;
  }, true);
}

async function main() {
  const { learners, mentors } = await loadPeople();
  const before = await academicFingerprint();
  assert(Number(before.evidence_count) === 24, `expected 24 academic evidence rows, got ${before.evidence_count}`);

  // 600 concurrent client sessions, then the same 600 requests retried. The pool
  // intentionally caps simultaneous DB connections while all promises are live.
  await capabilityWave(learners, { name:'initial', aiEnabled:true, mentorEnabled:true });
  await capabilityWave(learners, { name:'retry', aiEnabled:true, mentorEnabled:true });

  const initialQueues = await assertOneScopeEach(mentors, 'initial-queue');
  await wrongScopeReviewWave(mentors, initialQueues);
  await privateTableDeniedWave(learners);

  // AI outage: Core and Mentor remain intact. No provider is invoked.
  await setFlags({ aiEnabled:false, mentorEnabled:true });
  await capabilityWave(learners, { name:'ai-outage', aiEnabled:false, mentorEnabled:true });
  await assertOneScopeEach(mentors, 'ai-outage-queue');

  // AI recovery is prospective only; deterministic state must not change.
  await setFlags({ aiEnabled:true, mentorEnabled:true });
  await capabilityWave(learners, { name:'ai-recovered', aiEnabled:true, mentorEnabled:true });

  // Mentor global outage: every learner keeps Core and AI entitlement semantics,
  // but assignment authority and visible routine mentor queue disappear.
  await setFlags({ aiEnabled:true, mentorEnabled:false });
  await capabilityWave(learners, { name:'mentor-outage', aiEnabled:true, mentorEnabled:false });
  await assertQueueHidden(mentors, 0, 'mentor-outage-queue');

  // Restore Mentor service and re-establish exactly ten visible human scopes.
  await setFlags({ aiEnabled:true, mentorEnabled:true });
  await capabilityWave(learners, { name:'mentor-recovered', aiEnabled:true, mentorEnabled:true });
  await assertOneScopeEach(mentors, 'mentor-recovered-queue');

  const { rows: assignmentRows } = await pool.query(`
    select a.id,
           (substring(l.fixture_profile_key from 'L([0-9]{4})$'))::int learner_ord,
           (substring(m.fixture_profile_key from 'M([0-9]{2})$'))::int mentor_ord
    from private.exam_prep_mentor_assignments a
    join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
    join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
    where l.run_id=$1 and m.run_id=$1 and a.assignment_status='active'
    order by learner_ord`, [RUN_ID]);
  assert(assignmentRows.length === 10, `expected 10 active assignments before pause, got ${assignmentRows.length}`);
  const a1 = assignmentRows.find(x => x.learner_ord === 1);
  const a2 = assignmentRows.find(x => x.learner_ord === 2);
  const m1 = mentors.find(x => x.ord === 1);
  const m2 = mentors.find(x => x.ord === 2);
  const ops = mentors.find(x => x.ord === 10);

  const paused = await mutateAsOps(ops.user_id,
    'select public.pause_exam_prep_mentor_assignment_safe_v1($1,$2) as result',
    [a1.id,'P2-78 concurrent service test pauses one human scope while Core remains available.']);
  assert(paused.assignment_status === 'paused', `pause failed: ${JSON.stringify(paused)}`);
  await capabilityWave(learners, { name:'mentor-pause', aiEnabled:true, mentorEnabled:true, pausedLearners:new Set([1]) });
  await assertQueueHidden(mentors, 9, 'mentor-pause-queue');

  // Handover learner 1 to mentor 2, then learner 2 to mentor 1. This ends the
  // two old assignments, restores 10 active assignments and one visible scope
  // per mentor without resetting queue age/history.
  const h1 = await mutateAsOps(ops.user_id,
    'select public.handover_exam_prep_mentor_assignment_safe_v1($1,$2,$3) as result',
    [a1.id,m2.user_id,'P2-78 governed handover after temporary mentor absence; preserve queue age and learner history.']);
  assert(Number(h1.moved_open_queue_items) === 1, `first handover did not move one queue item: ${JSON.stringify(h1)}`);
  const h2 = await mutateAsOps(ops.user_id,
    'select public.handover_exam_prep_mentor_assignment_safe_v1($1,$2,$3) as result',
    [a2.id,m1.user_id,'P2-78 reciprocal governed handover restores one active human scope per synthetic mentor.']);
  assert(Number(h2.moved_open_queue_items) === 1, `second handover did not move one queue item: ${JSON.stringify(h2)}`);

  // Stale retry of the old handover must fail closed rather than duplicate work.
  let staleDenied = false;
  try {
    await mutateAsOps(ops.user_id,
      'select public.handover_exam_prep_mentor_assignment_safe_v1($1,$2,$3) as result',
      [a1.id,m2.user_id,'P2-78 stale handover retry must fail closed without creating a duplicate assignment.']);
  } catch (err) {
    staleDenied = String(err.message).includes('exam_prep_assignment_not_handover_eligible');
    if (!staleDenied) throw err;
  }
  assert(staleDenied, 'stale handover retry was not denied');

  const finalQueues = await assertOneScopeEach(mentors, 'post-handover-queue');
  await wrongScopeReviewWave(mentors, finalQueues);
  await capabilityWave(learners, { name:'post-handover', aiEnabled:true, mentorEnabled:true });

  const { rows: scaleRows } = await pool.query(`
    select
      (select count(*) from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        where l.run_id=$1 and a.assignment_status='active' and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now()))::int as active_assignments,
      (select count(distinct a.mentor_user_id) from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        where l.run_id=$1 and a.assignment_status='active' and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now()))::int as distinct_mentors,
      (select count(*) from private.exam_prep_mentor_queue_items q
        join private.exam_prep_human_review_recommendations r on r.id=q.recommendation_id
        where r.source_object_type='p278_scale')::int as physical_queue,
      (select count(*) from private.exam_prep_mentor_queue_items q
        join private.exam_prep_human_review_recommendations r on r.id=q.recommendation_id
        join private.exam_prep_synthetic_identities l on l.user_id=q.learner_user_id
        where r.source_object_type='p278_scale'
          and (substring(l.fixture_profile_key from 'L([0-9]{4})$'))::int>10)::int as leaked_queue,
      (select count(*) from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        where l.run_id=$1 and a.id in ($2,$3) and a.assignment_status='ended')::int as ended_old_assignments`,
    [RUN_ID,a1.id,a2.id]);
  const scale = scaleRows[0];
  assert(scale.active_assignments === 10, `final active assignments=${scale.active_assignments}`);
  assert(scale.distinct_mentors === 10, `final distinct mentors=${scale.distinct_mentors}`);
  assert(scale.physical_queue === 10, `final physical queue=${scale.physical_queue}`);
  assert(scale.leaked_queue === 0, `unassigned/waitlist queue leakage=${scale.leaked_queue}`);
  assert(scale.ended_old_assignments === 2, `old handover assignments not retained as ended history=${scale.ended_old_assignments}`);

  const after = await academicFingerprint();
  assert(JSON.stringify(after) === JSON.stringify(before),
    `service transitions mutated deterministic academic history\nbefore=${JSON.stringify(before)}\nafter=${JSON.stringify(after)}`);

  console.log(JSON.stringify({
    result:'GREEN',
    learners:600,
    mentors:10,
    concurrent_pool_max:pool.options.max,
    capability_requests:600 * 6,
    visible_human_scopes:10,
    unassigned_queue_leakage:0,
    academic_state_diff:0,
    paid_ai_calls:0
  }));
}

main()
  .then(async () => { await pool.end(); })
  .catch(async err => {
    console.error(err && err.stack ? err.stack : err);
    try { await pool.end(); } catch (_) {}
    process.exit(1);
  });
