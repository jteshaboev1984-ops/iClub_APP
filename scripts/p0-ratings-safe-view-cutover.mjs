import fs from 'node:fs';

const appPath = 'app.js';
const htmlPath = 'index.html';
let app = fs.readFileSync(appPath, 'utf8');
let html = fs.readFileSync(htmlPath, 'utf8');

function assert(ok, msg) {
  if (!ok) throw new Error(msg);
}

function countLiteral(source, needle) {
  return source.split(needle).length - 1;
}

function replaceAllExact(source, from, to, expected, label) {
  const count = countLiteral(source, from);
  assert(count === expected, `${label}: expected ${expected}, found ${count}`);
  return source.split(from).join(to);
}

const ratingsSource = '.from("ratings_cache")';
app = replaceAllExact(
  app,
  ratingsSource,
  '.from("ratings_cache_safe_v4")',
  6,
  'ratings_cache source cutover'
);

const tourSource = '.from("tour_attempts")';
const leaderboardNeedle = 'users(first_name,last_name,school,class,region,district';
let searchFrom = 0;
let replacements = 0;
while (true) {
  const idx = app.indexOf(tourSource, searchFrom);
  if (idx < 0) break;
  const window = app.slice(idx, idx + 520);
  if (window.includes(leaderboardNeedle)) {
    app = app.slice(0, idx) + '.from("tour_attempts_leaderboard_safe_v4")' + app.slice(idx + tourSource.length);
    replacements += 1;
    searchFrom = idx + '.from("tour_attempts_leaderboard_safe_v4")'.length;
  } else {
    searchFrom = idx + tourSource.length;
  }
}
assert(replacements === 4, `tour_attempts leaderboard cutover: expected 4, found ${replacements}`);

app = replaceAllExact(
  app,
  'users(first_name,last_name,school,class,region,district,region_id,district_id)',
  'users',
  7,
  'long users relation projection'
);
app = replaceAllExact(
  app,
  'users(first_name,last_name,school,class,region,district)',
  'users',
  1,
  'short users relation projection'
);

assert(countLiteral(app, '.from("ratings_cache")') === 0, 'legacy ratings_cache reads remain');
assert(countLiteral(app, '.from("ratings_cache_safe_v4")') === 6, 'safe ratings cache query count mismatch');
assert(countLiteral(app, '.from("tour_attempts_leaderboard_safe_v4")') === 4, 'safe live leaderboard query count mismatch');
assert(countLiteral(app, 'users(first_name') === 0, 'direct users relation projection remains in Ratings');
assert(countLiteral(app, '.from("tour_attempts")') > 0, 'own Tour history queries were unexpectedly removed');

const oldAppKey = 'app.js?v=support4-p002v4tour1';
assert(countLiteral(html, oldAppKey) === 1, 'old app cache key missing or duplicated');
html = html.replace(oldAppKey, 'app.js?v=support4-p0ratings1');

fs.writeFileSync(appPath, app);
fs.writeFileSync(htmlPath, html);
