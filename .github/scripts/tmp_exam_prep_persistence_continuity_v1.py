from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 occurrence, found {count}')
    return text.replace(old, new, 1)

live_path = Path('exam-prep/exam-prep-live.js')
live = live_path.read_text(encoding='utf-8')
live = replace_once(live, 'const VERSION = "p019timed1";', 'const VERSION = "p019timed2";', 'live version')

live = replace_once(
    live,
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "ko‘nikma",',
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "ko‘nikma", continueCheck: "Kirish tekshiruvini davom ettirish", profileSaved: "Saqlangan reja", targetShort: "Maqsad", totalShort: "Jami", mathShort: "Matematika", hoursShort: "soat/hafta",',
    'uz continuity copy'
)
live = replace_once(
    live,
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "skills",',
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "skills", continueCheck: "Continue entry check", profileSaved: "Saved plan", targetShort: "Target grade", totalShort: "Total", mathShort: "Mathematics", hoursShort: "h/week",',
    'en continuity copy'
)
live = replace_once(
    live,
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "навыков",',
    'componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "навыков", continueCheck: "Продолжить входную проверку", profileSaved: "Сохранённый план", targetShort: "Цель", totalShort: "Всего", mathShort: "Математика", hoursShort: "ч/нед",',
    'ru continuity copy'
)

live = replace_once(
    live,
    '<label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026"></label>\n      <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A"></label>',
    '<label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026" required aria-required="true"></label>\n      <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A" required aria-required="true"></label>',
    'native profile required fields'
)

live = replace_once(
    live,
    'if (!(values.totalHours > 0) || !(values.mathHours > 0) || values.mathHours > values.totalHours || values.totalHours > 168) {',
    'if (!String(values.examSeries || "").trim() || !String(values.targetGrade || "").trim() || !(values.totalHours > 0) || !(values.mathHours > 0) || values.mathHours > values.totalHours || values.totalHours > 168) {',
    'native profile validation'
)

live = replace_once(
    live,
    'actions.push(`<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`);',
    'actions.push(`<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active || ansItems > 0 ? c.continueCheck : c.start)}</button>`);',
    'continuity CTA'
)

live = replace_once(
    live,
    'const profileLine = [state.profile?.exam_series, state.profile?.target_grade].filter(Boolean).join(" · ");\n    const profileBadge = profileLine ? `<div class="ep-live-dashboard-profile">${esc(profileLine)}</div>` : "";',
    'const totalHours = Number(state.profile?.total_student_hours_available || 0), mathHours = Number(state.profile?.mathematics_hours_budget || 0);\n    const profileBits = [\n      state.profile?.exam_series || "",\n      state.profile?.target_grade ? `${c.targetShort}: ${state.profile.target_grade}` : "",\n      totalHours > 0 ? `${c.totalShort}: ${totalHours} ${c.hoursShort}` : "",\n      mathHours > 0 ? `${c.mathShort}: ${mathHours} ${c.hoursShort}` : ""\n    ].filter(Boolean);\n    const profileLine = profileBits.join(" · ");\n    const profileBadge = profileLine ? `<div class="ep-live-dashboard-profile"><strong>${esc(c.profileSaved)}</strong><span>${esc(profileLine)}</span></div>` : "";',
    'saved plan dashboard summary'
)

live = replace_once(
    live,
    '.ep-live-dashboard-profile{flex:0 0 auto;padding:6px 9px;border:1px solid rgba(127,127,127,.24);border-radius:999px;font-size:11px;font-weight:700}',
    '.ep-live-dashboard-profile{flex:0 1 310px;display:grid;gap:2px;padding:7px 9px;border:1px solid rgba(127,127,127,.24);border-radius:10px;font-size:10px;line-height:1.35}.ep-live-dashboard-profile strong{font-size:10px}.ep-live-dashboard-profile span{overflow-wrap:anywhere}',
    'saved plan structural style'
)
live_path.write_text(live, encoding='utf-8')

profile_path = Path('exam-prep/exam-prep-profile-completeness.js')
profile = profile_path.read_text(encoding='utf-8')
profile = replace_once(profile, 'const VERSION = "p205profile1";', 'const VERSION = "p205profile2";', 'profile completeness version')
profile = replace_once(
    profile,
    'body: "Imtihon sessiyasi va maqsad bahoni kiriting. Bu ma’lumotlar keyinchalik tayyorgarlik holatini to‘g‘ri baholash uchun kerak. Oldingi natijalaringiz saqlanadi.",',
    'body: "Javoblaringiz va progressingiz saqlangan. Faqat yetishmayotgan imtihon ma’lumotlarini to‘ldiring. Mavjud natijalar o‘zgarmaydi.",',
    'uz repair copy'
)
profile = replace_once(
    profile,
    'body: "Add your exam series and target grade. They are needed later to assess readiness correctly. Your existing progress will be kept.",',
    'body: "Your answers and progress are saved. Complete only the missing exam details. Your existing results will not change.",',
    'en repair copy'
)
profile = replace_once(
    profile,
    'body: "Укажите экзаменационную сессию и целевую оценку. Эти данные понадобятся позже, чтобы корректно оценивать готовность. Уже накопленный прогресс сохранится.",',
    'body: "Ваши ответы и прогресс сохранены. Дополните только недостающие данные об экзамене. Уже полученные результаты не изменятся.",',
    'ru repair copy'
)

old_render = '''    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-profile-completion>\n      <div class="ep-live-card">\n        <strong>${esc(c.title)}</strong>\n        <div class="ep-live-meta">${esc(c.body)}</div>\n        <form class="ep-live-form" data-ep-profile-completion-form>\n          <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" value="${esc(profile?.exam_series || "")}" placeholder="May/June 2027" required aria-required="true"></label>\n          <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" value="${esc(profile?.target_grade || "")}" placeholder="A" required aria-required="true"></label>\n          <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(total)}" required></label>\n          <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(math)}" required></label>\n          <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>\n        </form>\n        <div data-ep-profile-completion-error></div>\n      </div>\n    </section>`;\n    root.querySelector("[data-ep-profile-completion-form]")?.addEventListener("submit", event => save(event, profile));'''
new_render = '''    const shell = root.querySelector(".ep-host-shell.ep-live");\n    const dashboard = root.querySelector(".ep-live-dashboard-intro");\n    const grid = root.querySelector(".ep-live-grid");\n    if (!shell || !dashboard || !grid) return;\n\n    const panel = document.createElement("section");\n    panel.className = "ep-live-card ep-profile-completion-card";\n    panel.dataset.epProfileCompletion = "true";\n    panel.innerHTML = `\n      <strong>${esc(c.title)}</strong>\n      <div class="ep-live-meta">${esc(c.body)}</div>\n      <form class="ep-live-form" data-ep-profile-completion-form>\n        <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" value="${esc(profile?.exam_series || "")}" placeholder="May/June 2027" required aria-required="true"></label>\n        <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" value="${esc(profile?.target_grade || "")}" placeholder="A" required aria-required="true"></label>\n        <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(total)}" required></label>\n        <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(math)}" required></label>\n        <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>\n      </form>\n      <div data-ep-profile-completion-error></div>`;\n    shell.insertBefore(panel, grid);\n    panel.querySelector("[data-ep-profile-completion-form]")?.addEventListener("submit", event => save(event, profile));'''
profile = replace_once(profile, old_render, new_render, 'additive profile repair')
profile_path.write_text(profile, encoding='utf-8')

api_path = Path('exam-prep/exam-prep-api.js')
api = api_path.read_text(encoding='utf-8')
api = replace_once(api, 'exam-prep-live.js?v=p019timed1', 'exam-prep-live.js?v=p019timed2', 'live cache key')
api = replace_once(api, 'exam-prep-profile-completeness.js?v=p205profile1', 'exam-prep-profile-completeness.js?v=p205profile2', 'profile cache key')
api_path.write_text(api, encoding='utf-8')

p017_path = Path('.github/scripts/p0_17_live_diagnostic_regression.js')
p017 = p017_path.read_text(encoding='utf-8')
p017 = replace_once(p017, "r.version==='p019timed1'", "r.version==='p019timed2'", 'p0-17 version expectation')
p017_path.write_text(p017, encoding='utf-8')

p205_path = Path('scripts/p2-05-profile-completeness-regression.cjs')
p205 = p205_path.read_text(encoding='utf-8')
p205 = replace_once(p205, "assert(api.includes('exam-prep-profile-completeness.js?v=p205profile1'), 'profile completeness guard is not loaded by Exam Prep API');", "assert(api.includes('exam-prep-profile-completeness.js?v=p205profile2'), 'profile completeness guard is not loaded by Exam Prep API');", 'p2-05 cache expectation')
p205 = replace_once(p205, "assert(guard.includes('data-ep-profile-completion-form'), 'incomplete existing profile repair form missing');", "assert(guard.includes('data-ep-profile-completion-form'), 'incomplete existing profile repair form missing');\nassert(guard.includes('shell.insertBefore(panel, grid)'), 'incomplete profile repair must be additive and preserve dashboard progress');\nassert(!guard.includes('root.innerHTML = `<section class=\"ep-host-shell ep-live\" data-ep-profile-completion>'), 'profile repair must not replace the live dashboard');", 'p2-05 additive assertion')
p205 = replace_once(p205, "  'Уже накопленный прогресс сохранится',\n  'Oldingi natijalaringiz saqlanadi',\n  'Your existing progress will be kept'", "  'Ваши ответы и прогресс сохранены',\n  'Javoblaringiz va progressingiz saqlangan',\n  'Your answers and progress are saved'", 'p2-05 learner copy expectation')
p205_path.write_text(p205, encoding='utf-8')

print('Exam Prep persistence continuity patch staged.')
