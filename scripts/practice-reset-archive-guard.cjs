const fs = require("fs");
const assert = require("assert");

const migration = fs.readFileSync("supabase/migrations/20260923105000_practice_reset_archive_before_delete_v1.sql","utf8");
const archivePos = migration.indexOf("INSERT INTO private.practice_reset_archives_v1");
const deletePos = migration.indexOf("DELETE FROM public.practice_attempts");

assert.ok(archivePos > 0 && deletePos > archivePos,"Practice data must be archived before destructive attempt delete");
assert.match(migration,/ALTER TABLE private\.practice_reset_archives_v1 ENABLE ROW LEVEL SECURITY/,"archive RLS missing");
assert.match(migration,/REVOKE ALL ON TABLE private\.practice_reset_archives_v1 FROM PUBLIC,anon,authenticated/,"archive browser revoke missing");
assert.match(migration,/coalesce\(a\.is_lab,false\)=false/,"lab isolation missing");
assert.match(migration,/practice_answers.*jsonb NOT NULL/s,"answer snapshot missing");
assert.match(migration,/'reset_archive_id',v_archive_id/,"reset receipt lacks archive id");
assert.match(migration,/97df3ea3875759ea497665bb798f9ab9/,"live reset function hash guard missing");

console.log("practice reset archive guard: PASS");
