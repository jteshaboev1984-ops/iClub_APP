# Practice AI Diagnosis — Storage and Archive Status

## Current status

This step is production-safe and does not change existing practice/tour history.

Completed:

1. Database storage contract is applied in Supabase.
2. The same migration is committed in `supabase/migrations/20260708_practice_ai_diagnosis_storage_contract.sql`.
3. AI diagnosis snapshots are stored in existing `learning_roadmaps` using:
   - `source_type = 'practice_ai_diagnosis'`
   - `source_id = practice_attempt_id`
4. Archive/read RPCs are created:
   - `get_practice_ai_diagnosis(p_attempt_id bigint)`
   - `create_practice_ai_diagnosis(p_attempt_id bigint)`
   - `get_ai_diagnosis_archive(p_subject_id bigint default null, p_limit integer default 20)`
   - `has_ai_diagnosis_archive(p_subject_id bigint default null)`
5. New unique/index guards are added:
   - `learning_roadmaps_practice_ai_attempt_uidx`
   - `learning_roadmaps_practice_ai_archive_idx`
6. `learning_roadmaps` still had `0` records after the migration. No historical score/result data was changed.
7. A gated read-only archive preview layer was added:
   - `ai-diagnosis-archive-preview.js`
   - `ai-diagnosis-archive-preview.css`

## Important safety boundary

The archive preview files are intentionally separate and gated. They do not write to the database and do not create/update/delete attempts, answers, scores, ratings, certificates, or roadmaps.

The preview feature is designed to be enabled only by:

```js
localStorage.setItem('iclub_ai_diag_enabled', '1')
```

or by opening the app with:

```text
?ai_diag=1
```

## Not connected yet

The preview archive layer is created as files but is not yet connected to `index.html`.

Reason: `index.html` is large and live. Replacing the whole file only to add two asset lines is unnecessary risk. The next step should be a tiny reviewed patch to add:

```html
<link rel="stylesheet" href="ai-diagnosis-archive-preview.css" />
```

near the existing stylesheet and:

```html
<script src="ai-diagnosis-archive-preview.js"></script>
```

after `app.js`.

## Intended UI placement

When enabled and when the authenticated user has at least one saved AI diagnosis, the archive entry should appear in the Subject Hub / Practice area next to `Мои рекомендации`.

The entry label:

```text
Архив AI-диагностик
Сохранённые рекомендации по практикам
```

## Next production-safe step

1. Add the two asset includes to `index.html`.
2. Test with a user that has a saved `practice_ai_diagnosis` roadmap.
3. Keep default visibility off for normal users.
4. Only after archive access works, connect the Practice Result AI button to `create_practice_ai_diagnosis(attempt_id)`.
5. Do not touch tours, ratings, certificates, or historical attempt rows.
