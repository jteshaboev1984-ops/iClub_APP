from pathlib import Path


def read(path):
    return Path(path).read_text(encoding='utf-8')


def write(path, text):
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    return text.replace(old, new, 1)


# 1) Mathematics Subject Hub: promote the existing governed Exam Prep entry
# without creating a second subject or changing routing/access semantics.
index_path = 'index.html'
html = read(index_path)
old_entry = '''<div id="subject-hub-exam-prep-entry" class="subject-hub-list exam-prep-host-entry" hidden aria-hidden="true">
  <button class="settings-nav" type="button" data-action="open-exam-prep">
    <span class="settings-nav-ico"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><path d="M15 9l5-5"/><path d="M17 4h3v3"/></svg></span>
    <span class="settings-nav-text">
      <span id="subject-hub-exam-prep-title" class="settings-nav-title">Cambridge AS Mathematics · Exam Prep</span>
      <span id="subject-hub-exam-prep-sub" class="settings-nav-sub muted small">Paper 1 + Paper 5</span>
    </span>
    <span class="settings-nav-arrow">›</span>
  </button>
</div>'''
new_entry = '''<div id="subject-hub-exam-prep-entry" class="subject-hub-list exam-prep-host-entry exam-prep-feature-card" hidden aria-hidden="true">
  <button class="exam-prep-feature-button" type="button" data-action="open-exam-prep" aria-describedby="subject-hub-exam-prep-sub">
    <span class="exam-prep-feature-topline">
      <span id="subject-hub-exam-prep-badge" class="exam-prep-feature-badge">Cambridge AS · Mathematics</span>
      <span class="exam-prep-feature-arrow" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg></span>
    </span>
    <span id="subject-hub-exam-prep-title" class="exam-prep-feature-title">Exam Prep</span>
    <span id="subject-hub-exam-prep-sub" class="exam-prep-feature-description">Paper 1 and Paper 5 preparation</span>
    <span class="exam-prep-feature-components" aria-label="Exam components">
      <span class="exam-prep-feature-component"><strong>P1</strong><span id="subject-hub-exam-prep-p1">Pure Mathematics 1 · 45 skills</span></span>
      <span class="exam-prep-feature-component"><strong>P5</strong><span id="subject-hub-exam-prep-p5">Probability &amp; Statistics 1 · 36 skills</span></span>
    </span>
    <span class="exam-prep-feature-footer">
      <span id="subject-hub-exam-prep-note" class="exam-prep-feature-note">Practice and Tours history stays unchanged.</span>
      <span id="subject-hub-exam-prep-cta" class="exam-prep-feature-cta">Open Exam Prep</span>
    </span>
  </button>
</div>'''
html = replace_once(html, old_entry, new_entry, 'index Exam Prep entry')
html = replace_once(html, 'visual/iclub-premium-v3.css?v=premium1', 'visual/iclub-premium-v3.css?v=premium2', 'premium css cache key')
html = replace_once(html, 'exam-prep/exam-prep-host.css?v=p014h1', 'exam-prep/exam-prep-host.css?v=p014ux2', 'host css cache key')
html = replace_once(html, 'exam-prep/exam-prep-host.js?v=p014h1', 'exam-prep/exam-prep-host.js?v=p014ux2', 'host js cache key')
write(index_path, html)


# 2) Host bridge: learner-safe localized product copy + availability presentation class.
host_path = 'exam-prep/exam-prep-host.js'
host = read(host_path)

host = replace_once(host,
'''        skills: "ko‘nikma",
        inviteTitle: "Exam Prep sinoviga taklif",''',
'''        skills: "ko‘nikma",
        entryBadge: "Cambridge AS · Mathematics",
        entryTitle: "Exam Prep",
        entryDesc: "Paper 1 va Paper 5 bo‘yicha shaxsiy tayyorgarlik yo‘li: kirish tekshiruvi, haftalik reja, mavzular, xatolar va vaqtli mashqlar.",
        entryP1: "Pure Mathematics 1 · 45 ko‘nikma",
        entryP5: "Probability & Statistics 1 · 36 ko‘nikma",
        entryNote: "Practice va Tours tarixi o‘zgarmaydi.",
        entryCta: "Exam Prepni ochish",
        inviteBadge: "Yangi imkoniyat",
        inviteCta: "Taklifni ko‘rish",
        inviteTitle: "Exam Prep sinoviga taklif",''', 'host uz entry copy')

host = replace_once(host,
'''        skills: "skills",
        inviteTitle: "Invitation to test Exam Prep",''',
'''        skills: "skills",
        entryBadge: "Cambridge AS · Mathematics",
        entryTitle: "Exam Prep",
        entryDesc: "A personal route for Paper 1 and Paper 5: entry check, weekly plan, syllabus work, corrections and timed practice.",
        entryP1: "Pure Mathematics 1 · 45 skills",
        entryP5: "Probability & Statistics 1 · 36 skills",
        entryNote: "Practice and Tours history stays unchanged.",
        entryCta: "Open Exam Prep",
        inviteBadge: "New feature",
        inviteCta: "View invitation",
        inviteTitle: "Invitation to test Exam Prep",''', 'host en entry copy')

host = replace_once(host,
'''      skills: "навыков",
      inviteTitle: "Приглашение протестировать Exam Prep",''',
'''      skills: "навыков",
      entryBadge: "Cambridge AS · Mathematics",
      entryTitle: "Exam Prep",
      entryDesc: "Персональный маршрут по Paper 1 и Paper 5: входная проверка, недельный план, темы, исправление ошибок и практика на время.",
      entryP1: "Pure Mathematics 1 · 45 навыков",
      entryP5: "Probability & Statistics 1 · 36 навыков",
      entryNote: "История Practice и Tours остаётся без изменений.",
      entryCta: "Открыть Exam Prep",
      inviteBadge: "Новая функция",
      inviteCta: "Посмотреть приглашение",
      inviteTitle: "Приглашение протестировать Exam Prep",''', 'host ru entry copy')

host = replace_once(host,
'''  function setEntryVisible(visible) {
    const el = entryEl();
    if (!el) return;
    el.hidden = !visible;
    el.setAttribute("aria-hidden", visible ? "false" : "true");
  }''',
'''  function setEntryVisible(visible) {
    const el = entryEl();
    const hub = hubEl();
    if (!el) return;
    el.hidden = !visible;
    el.setAttribute("aria-hidden", visible ? "false" : "true");
    if (hub) hub.classList.toggle("exam-prep-available", visible === true);
  }''', 'host availability presentation class')

host = replace_once(host,
'''  function renderEntryCopy() {
    const text = labels(state.language);
    const title = $("#subject-hub-exam-prep-title");
    const sub = $("#subject-hub-exam-prep-sub");
    const inviteOnly = invited() && !allowed(state.capabilities);
    if (title) title.textContent = inviteOnly ? text.inviteTitle : text.title;
    if (sub) sub.textContent = inviteOnly ? text.inviteSub : text.subtitle;
  }''',
'''  function renderEntryCopy() {
    const text = labels(state.language);
    const entry = entryEl();
    const badge = $("#subject-hub-exam-prep-badge");
    const title = $("#subject-hub-exam-prep-title");
    const sub = $("#subject-hub-exam-prep-sub");
    const p1 = $("#subject-hub-exam-prep-p1");
    const p5 = $("#subject-hub-exam-prep-p5");
    const note = $("#subject-hub-exam-prep-note");
    const cta = $("#subject-hub-exam-prep-cta");
    const inviteOnly = invited() && !allowed(state.capabilities);
    if (entry) {
      entry.classList.toggle("is-invitation", inviteOnly);
      entry.setAttribute("data-ep-entry-mode", inviteOnly ? "invitation" : "live");
    }
    if (badge) badge.textContent = inviteOnly ? text.inviteBadge : text.entryBadge;
    if (title) title.textContent = inviteOnly ? text.inviteTitle : text.entryTitle;
    if (sub) sub.textContent = inviteOnly ? text.inviteSub : text.entryDesc;
    if (p1) p1.textContent = text.entryP1;
    if (p5) p5.textContent = text.entryP5;
    if (note) note.textContent = text.entryNote;
    if (cta) cta.textContent = inviteOnly ? text.inviteCta : text.entryCta;
  }''', 'host entry renderer')
write(host_path, host)


# 3) Live Exam Prep dashboard: change information hierarchy, not academic logic.
live_path = 'exam-prep/exam-prep-live.js'
live = read(live_path)

live = replace_once(live,
'''      actionCloseIssue: "Qolgan asosiy xatoni yoping", actionShort: "Qisqa maqsadli mashq", actionTiming: "Vaqt va imtihon tartibini tekshirish", actionTaper: "Yuklamani kamaytirish va natijani saqlash"''',
'''      dashboardEyebrow: "Sizning yo‘lingiz", dashboardTitle: "P1 va P5 bo‘yicha tayyorgarlik", dashboardText: "Har bir komponent o‘z bosqichi, dalillari va keyingi qadami bilan alohida yuradi.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "ko‘nikma",
      actionCloseIssue: "Qolgan asosiy xatoni yoping", actionShort: "Qisqa maqsadli mashq", actionTiming: "Vaqt va imtihon tartibini tekshirish", actionTaper: "Yuklamani kamaytirish va natijani saqlash"''', 'live uz dashboard copy')

live = replace_once(live,
'''      actionCloseIssue: "Close the main remaining issue", actionShort: "Short targeted practice", actionTiming: "Check timing and exam logistics", actionTaper: "Reduce workload and protect performance"''',
'''      dashboardEyebrow: "Your route", dashboardTitle: "Preparation for P1 and P5", dashboardText: "Each component moves separately with its own phase, evidence and next action.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "skills",
      actionCloseIssue: "Close the main remaining issue", actionShort: "Short targeted practice", actionTiming: "Check timing and exam logistics", actionTaper: "Reduce workload and protect performance"''', 'live en dashboard copy')

live = replace_once(live,
'''      actionCloseIssue: "Закройте оставшуюся ключевую ошибку", actionShort: "Короткая целевая практика", actionTiming: "Проверьте время и организацию экзамена", actionTaper: "Снизьте нагрузку и сохраните результат"''',
'''      dashboardEyebrow: "Ваш маршрут", dashboardTitle: "Подготовка по P1 и P5", dashboardText: "Каждый компонент идёт отдельно: со своим этапом, подтверждениями и следующим действием.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "навыков",
      actionCloseIssue: "Закройте оставшуюся ключевую ошибку", actionShort: "Короткая целевая практика", actionTiming: "Проверьте время и организацию экзамена", actionTaper: "Снизьте нагрузку и сохраните результат"''', 'live ru dashboard copy')

old_component = '''  function componentCard(component, progress, statePayload) {
    const c = copy(), s = progress?.screening || {}, summary = componentSummary(component, statePayload);
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0), reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true, active = progress?.active_session;
    const stage = Number(summary?.operational_stage || 0), coverage = Number(summary?.coverage_pct || 0);
    const actions = [];
    if (complete) {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-plan="${component}">${esc(c.openPlan)}</button>`);
      if (stage >= 2) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-timed="${component}">${esc(c.openTimed)}</button>`);
      if (stage >= 5) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-readiness="${component}">${esc(c.openReadiness)}</button>`);
    } else {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`);
    }
    const status = complete
      ? `<div class="ep-live-notice"><strong>${esc(c.stageTitle)}: ${esc(stageLabel(stage))}</strong><div class="ep-live-meta">${esc(c.coverage)}: ${coverage.toFixed(0)}%</div></div>`
      : `<div><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div></div>`;
    return `<div class="ep-live-card"><strong>${component}</strong>${status}<div class="ep-live-actions">${actions.join("")}</div></div>`;
  }'''
new_component = '''  function componentCard(component, progress, statePayload) {
    const c = copy(), s = progress?.screening || {}, summary = componentSummary(component, statePayload);
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0), reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true, active = progress?.active_session;
    const stage = Number(summary?.operational_stage || 0), coverage = Number(summary?.coverage_pct || 0);
    const componentName = component === "P1" ? c.componentP1 : c.componentP5;
    const skillCount = component === "P1" ? 45 : 36;
    const actions = [];
    if (complete) {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-plan="${component}">${esc(c.openPlan)}</button>`);
      if (stage >= 2) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-timed="${component}">${esc(c.openTimed)}</button>`);
      if (stage >= 5) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-readiness="${component}">${esc(c.openReadiness)}</button>`);
    } else {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`);
    }
    const status = complete
      ? `<div class="ep-live-notice ep-live-component-status"><strong>${esc(c.stageTitle)}: ${esc(stageLabel(stage))}</strong><div class="ep-live-meta">${esc(c.coverage)}: ${coverage.toFixed(0)}%</div></div>`
      : `<div class="ep-live-component-status"><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div></div>`;
    return `<article class="ep-live-card ep-live-component-card" data-ep-live-component="${component}"><div class="ep-live-component-head"><span class="ep-live-component-code">${component}</span><div class="ep-live-component-copy"><strong>${esc(componentName)}</strong><span>${skillCount} ${esc(c.skillsLabel)}</span></div></div>${status}<div class="ep-live-actions">${actions.join("")}</div></article>`;
  }'''
live = replace_once(live, old_component, new_component, 'live component card structure')

live = replace_once(live,
'''    const profileLine = [state.profile?.exam_series, state.profile?.target_grade].filter(Boolean).join(" · ");
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-meta">${esc(profileLine)}</div><div class="ep-live-grid">${componentCard("P1", p1.data, s1.data)}${componentCard("P5", p5.data, s5.data)}</div>`);''',
'''    const c = copy();
    const profileLine = [state.profile?.exam_series, state.profile?.target_grade].filter(Boolean).join(" · ");
    const profileBadge = profileLine ? `<div class="ep-live-dashboard-profile">${esc(profileLine)}</div>` : "";
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<section class="ep-live-dashboard-intro"><div><div class="ep-live-dashboard-eyebrow">${esc(c.dashboardEyebrow)}</div><h3 class="ep-live-dashboard-title">${esc(c.dashboardTitle)}</h3><p class="ep-live-dashboard-text">${esc(c.dashboardText)}</p></div>${profileBadge}</section><div class="ep-live-grid">${componentCard("P1", p1.data, s1.data)}${componentCard("P5", p5.data, s5.data)}</div>`);''', 'live dashboard hierarchy')

live = replace_once(live,
'''      .ep-live-timer{font-variant-numeric:tabular-nums;font-weight:800}.ep-live-action-row{display:grid;gap:4px;padding:10px;border:1px solid rgba(127,127,127,.18);border-radius:10px}
      @media(max-width:680px){.ep-live-grid,.ep-live-form,.ep-live-stats{grid-template-columns:1fr}.ep-live-head{display:grid}.ep-live-safe{text-align:left;max-width:none}.ep-live-plan-item,.ep-live-timed-row{grid-template-columns:1fr}.ep-live-plan-item .ep-live-btn,.ep-live-timed-row .ep-live-btn{width:100%}}''',
'''      .ep-live-timer{font-variant-numeric:tabular-nums;font-weight:800}.ep-live-action-row{display:grid;gap:4px;padding:10px;border:1px solid rgba(127,127,127,.18);border-radius:10px}
      .ep-live-dashboard-intro{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;padding:12px 0}.ep-live-dashboard-eyebrow{font-size:11px;font-weight:800;letter-spacing:.06em;text-transform:uppercase;opacity:.7}.ep-live-dashboard-title{margin:4px 0 5px;font-size:19px;line-height:1.2}.ep-live-dashboard-text{margin:0;max-width:520px;font-size:13px;line-height:1.45;opacity:.76}.ep-live-dashboard-profile{flex:0 0 auto;padding:6px 9px;border:1px solid rgba(127,127,127,.24);border-radius:999px;font-size:11px;font-weight:700}.ep-live-component-head{display:flex;align-items:center;gap:10px}.ep-live-component-code{display:inline-flex;align-items:center;justify-content:center;min-width:34px;height:28px;padding:0 8px;border-radius:999px;background:rgba(127,127,127,.1);font-size:11px;font-weight:800}.ep-live-component-copy{display:grid;gap:2px;min-width:0}.ep-live-component-copy>span{font-size:11px;opacity:.68}.ep-live-component-status{display:grid;gap:7px}
      @media(max-width:680px){.ep-live-grid,.ep-live-form,.ep-live-stats{grid-template-columns:1fr}.ep-live-head{display:grid}.ep-live-safe{text-align:left;max-width:none}.ep-live-dashboard-intro{display:grid}.ep-live-dashboard-profile{width:max-content}.ep-live-plan-item,.ep-live-timed-row{grid-template-columns:1fr}.ep-live-plan-item .ep-live-btn,.ep-live-timed-row .ep-live-btn{width:100%}}''', 'live structural fallback styles')
write(live_path, live)


# 4) Host base CSS: usable hierarchy even if the premium layer is temporarily unavailable.
host_css_path = 'exam-prep/exam-prep-host.css'
host_css = read(host_css_path)
base_marker = '/* Mathematics Exam Prep feature entry — structural host layer */'
if base_marker not in host_css:
    host_css += '''\n\n/* Mathematics Exam Prep feature entry — structural host layer */\n.exam-prep-feature-card {\n  margin: 12px 0 14px;\n}\n\n.exam-prep-feature-button {\n  width: 100%;\n  display: grid;\n  gap: 10px;\n  padding: 16px;\n  border: 0;\n  background: transparent;\n  color: inherit;\n  text-align: left;\n  font: inherit;\n  cursor: pointer;\n}\n\n.exam-prep-feature-topline,\n.exam-prep-feature-footer {\n  display: flex;\n  align-items: center;\n  justify-content: space-between;\n  gap: 10px;\n}\n\n.exam-prep-feature-badge {\n  font-size: 11px;\n  font-weight: 800;\n}\n\n.exam-prep-feature-arrow {\n  width: 30px;\n  height: 30px;\n  display: grid;\n  place-items: center;\n}\n\n.exam-prep-feature-arrow svg {\n  width: 18px;\n  height: 18px;\n  fill: none;\n  stroke: currentColor;\n  stroke-width: 1.8;\n  stroke-linecap: round;\n  stroke-linejoin: round;\n}\n\n.exam-prep-feature-title {\n  font-size: 21px;\n  line-height: 1.15;\n  font-weight: 800;\n}\n\n.exam-prep-feature-description {\n  max-width: 640px;\n  font-size: 13px;\n  line-height: 1.45;\n}\n\n.exam-prep-feature-components {\n  display: grid;\n  grid-template-columns: repeat(2, minmax(0, 1fr));\n  gap: 8px;\n}\n\n.exam-prep-feature-component {\n  min-width: 0;\n  display: grid;\n  gap: 4px;\n  padding: 10px 11px;\n  border: 1px solid var(--border, rgba(127,127,127,.22));\n  border-radius: 12px;\n}\n\n.exam-prep-feature-component strong {\n  font-size: 11px;\n}\n\n.exam-prep-feature-component span {\n  font-size: 12px;\n  line-height: 1.35;\n}\n\n.exam-prep-feature-note,\n.exam-prep-feature-cta {\n  font-size: 11px;\n}\n\n.exam-prep-feature-cta {\n  font-weight: 800;\n  white-space: nowrap;\n}\n\n@media (max-width: 520px) {\n  .exam-prep-feature-components {\n    grid-template-columns: 1fr;\n  }\n\n  .exam-prep-feature-footer {\n    align-items: flex-start;\n    flex-direction: column;\n  }\n}\n'''
write(host_css_path, host_css)


# 5) Premium visual layer: make the new Mathematics capability unmistakably first-class.
premium_path = 'visual/iclub-premium-v3.css'
premium = read(premium_path)
premium_marker = '/* ===== PREMIUM MATHEMATICS EXAM PREP UX v3 ===== */'
if premium_marker not in premium:
    premium += '''\n\n/* ===== PREMIUM MATHEMATICS EXAM PREP UX v3 ===== */\n\n.iclub-visual-v3 #courses-subject-hub.exam-prep-available .subject-hub-head {\n  margin-bottom: 10px;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry.exam-prep-feature-card {\n  position: relative;\n  overflow: hidden;\n  margin: 12px 0 16px;\n  border: 1px solid #C9D7F8;\n  border-radius: var(--v3-radius-lg);\n  background:\n    radial-gradient(circle at 100% 0%, rgba(36, 87, 214, 0.12), transparent 34%),\n    linear-gradient(135deg, #FFFFFF 0%, #EEF4FF 100%);\n  box-shadow: 0 14px 34px rgba(36, 87, 214, 0.10);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry.exam-prep-feature-card::before {\n  content: \"\";\n  position: absolute;\n  inset: 0 auto 0 0;\n  width: 3px;\n  background: var(--v3-primary);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry.is-invitation {\n  border-color: #E8D7B3;\n  background:\n    radial-gradient(circle at 100% 0%, rgba(184, 132, 47, 0.10), transparent 34%),\n    linear-gradient(135deg, #FFFFFF 0%, #FFFAF1 100%);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry.is-invitation::before {\n  background: #B9832F;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button {\n  position: relative;\n  z-index: 1;\n  gap: 10px;\n  padding: 17px 17px 16px;\n  -webkit-tap-highlight-color: transparent;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-badge {\n  display: inline-flex;\n  align-items: center;\n  width: fit-content;\n  min-height: 24px;\n  padding: 4px 8px;\n  border: 1px solid #CDDAFA;\n  border-radius: 999px;\n  background: rgba(255,255,255,.72);\n  color: var(--v3-primary);\n  font-size: 9.5px;\n  font-weight: 800;\n  letter-spacing: .055em;\n  text-transform: uppercase;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry.is-invitation .exam-prep-feature-badge {\n  border-color: #E7D4AE;\n  color: #8A5B17;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-arrow {\n  flex: 0 0 30px;\n  border: 1px solid #D6E1FA;\n  border-radius: 999px;\n  background: rgba(255,255,255,.82);\n  color: var(--v3-primary);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-title {\n  color: var(--v3-text);\n  font-size: 23px;\n  line-height: 1.1;\n  font-weight: 820;\n  letter-spacing: -0.03em;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-description {\n  color: #536178;\n  font-size: 12.5px;\n  line-height: 1.5;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-components {\n  gap: 8px;\n  margin-top: 2px;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component {\n  border-color: #D8E3FA;\n  border-radius: var(--v3-radius-md);\n  background: rgba(255,255,255,.74);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component strong {\n  width: fit-content;\n  padding: 3px 6px;\n  border-radius: 999px;\n  background: var(--v3-primary-soft);\n  color: var(--v3-primary);\n  font-size: 9.5px;\n  font-weight: 810;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component span {\n  color: var(--v3-text);\n  font-size: 11px;\n  font-weight: 720;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-footer {\n  margin-top: 2px;\n  padding-top: 10px;\n  border-top: 1px solid rgba(201, 215, 248, .78);\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-note {\n  color: var(--v3-muted);\n  line-height: 1.4;\n}\n\n.iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-cta {\n  display: inline-flex;\n  align-items: center;\n  min-height: 30px;\n  padding: 6px 9px;\n  border-radius: 999px;\n  background: var(--v3-primary);\n  color: #FFFFFF;\n  font-size: 10.5px;\n  font-weight: 800;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-dashboard-intro {\n  position: relative;\n  margin-bottom: 2px;\n  padding: 14px 15px;\n  border: 1px solid #D8E2F8;\n  border-radius: var(--v3-radius-lg);\n  background: linear-gradient(135deg, #FFFFFF 0%, #F5F8FF 100%);\n  box-shadow: var(--v3-shadow-soft);\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-dashboard-eyebrow {\n  color: var(--v3-primary);\n  opacity: 1;\n  font-size: 9.5px;\n  font-weight: 810;\n  letter-spacing: .07em;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-dashboard-title {\n  margin: 4px 0 5px;\n  color: var(--v3-text);\n  font-size: 19px;\n  line-height: 1.18;\n  font-weight: 810;\n  letter-spacing: -0.02em;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-dashboard-text {\n  color: var(--v3-muted);\n  opacity: 1;\n  font-size: 11.5px;\n  line-height: 1.48;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-dashboard-profile {\n  border-color: #D8E2F8;\n  background: rgba(255,255,255,.82);\n  color: var(--v3-primary);\n  font-size: 10px;\n  font-weight: 780;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card {\n  position: relative;\n  overflow: hidden;\n  gap: 11px;\n  padding: 14px;\n  border-color: var(--v3-border);\n  background: #FFFFFF;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card::before {\n  content: \"\";\n  position: absolute;\n  inset: 0 auto 0 0;\n  width: 3px;\n  background: #B9C8EA;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-head {\n  gap: 9px;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-code {\n  min-width: 36px;\n  height: 28px;\n  border: 1px solid #D6E1FA;\n  background: var(--v3-primary-soft);\n  color: var(--v3-primary);\n  font-size: 10px;\n  font-weight: 810;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-copy strong {\n  color: var(--v3-text);\n  font-size: 13px;\n  line-height: 1.25;\n  font-weight: 780;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-copy > span {\n  color: var(--v3-muted);\n  opacity: 1;\n  font-size: 10px;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-live-notice {\n  border: 1px solid #E0E7F4;\n  background: #F8FAFD;\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-live-btn:not(.secondary) {\n  border-color: var(--v3-primary);\n  background: var(--v3-primary);\n  color: #FFFFFF;\n  box-shadow: 0 5px 14px rgba(36, 87, 214, .15);\n}\n\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-live-btn.secondary,\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-placement-btn,\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-views-btn,\n.iclub-visual-v3 #exam-prep-host-root .ep-live-component-card .ep-materials-btn {\n  border-color: #D8E1F2;\n  background: #FFFFFF;\n  color: var(--v3-text);\n  box-shadow: none;\n}\n\n@media (hover:hover) {\n  .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button:hover {\n    background: rgba(255,255,255,.22);\n  }\n}\n\n@media (max-width: 520px) {\n  .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button {\n    padding: 15px;\n  }\n\n  .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-components {\n    grid-template-columns: 1fr;\n  }\n\n  .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-footer {\n    gap: 8px;\n  }\n}\n'''
write(premium_path, premium)


# 6) Permanent regression for the screen architecture of the new Math feature.
regression_path = Path('.github/scripts/visual_v3_math_exam_prep_ux_regression.js')
regression_path.write_text(r'''const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const host = fs.readFileSync('exam-prep/exam-prep-host.js', 'utf8');
const live = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'class="subject-hub-list exam-prep-host-entry exam-prep-feature-card"',
  'id="subject-hub-exam-prep-badge"',
  'id="subject-hub-exam-prep-p1"',
  'id="subject-hub-exam-prep-p5"',
  'id="subject-hub-exam-prep-note"',
  'id="subject-hub-exam-prep-cta"',
  'data-action="open-exam-prep"'
]) assert(html.includes(token), `Math Exam Prep entry structure missing: ${token}`);

assert(/id="subject-hub-exam-prep-entry"[^>]*hidden[^>]*aria-hidden="true"/.test(html), 'Exam Prep entry must remain fail-closed by default');
assert(host.includes('hub.classList.toggle("exam-prep-available", visible === true)'), 'Host must expose presentation-only availability class');
assert(host.includes('entryDesc: "Персональный маршрут по Paper 1 и Paper 5'), 'RU learner copy missing');
assert(host.includes('entryDesc: "Paper 1 va Paper 5 bo‘yicha shaxsiy tayyorgarlik'), 'UZ learner copy missing');
assert(host.includes('entryDesc: "A personal route for Paper 1 and Paper 5'), 'EN learner copy missing');
assert(live.includes('class="ep-live-card ep-live-component-card"'), 'Live dashboard component architecture missing');
assert(live.includes('class="ep-live-dashboard-intro"'), 'Live dashboard hierarchy block missing');
assert(live.includes('componentP1: "Pure Mathematics 1"') && live.includes('componentP5: "Probability & Statistics 1"'), 'P1/P5 component names missing');
assert(!live.includes('overall readiness percentage') && !live.includes('combined mastery'), 'Combined learner truth must not be introduced');
assert(css.includes('PREMIUM MATHEMATICS EXAM PREP UX v3'), 'Premium Math Exam Prep UX marker missing');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const page = await context.newPage();
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await page.evaluate(() => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => node.classList.remove('is-active'));
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.add('is-active', 'exam-prep-available');
    hub.hidden = false;
    hub.setAttribute('aria-hidden', 'false');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    entry.hidden = false;
    entry.setAttribute('aria-hidden', 'false');
  });

  const entry = await page.evaluate(() => {
    const el = document.getElementById('subject-hub-exam-prep-entry');
    const title = el.querySelector('.exam-prep-feature-title');
    const componentGrid = el.querySelector('.exam-prep-feature-components');
    return {
      radius: getComputedStyle(el).borderRadius,
      shadow: getComputedStyle(el).boxShadow,
      titleSize: parseFloat(getComputedStyle(title).fontSize),
      componentColumns: getComputedStyle(componentGrid).gridTemplateColumns,
      width: document.documentElement.scrollWidth,
      innerWidth: window.innerWidth
    };
  });
  assert(entry.radius === '12px', `Math feature card radius drift: ${entry.radius}`);
  assert(entry.shadow !== 'none', 'Math feature card must read as a premium product surface');
  assert(entry.titleSize >= 21, `Math feature title hierarchy too weak: ${entry.titleSize}`);
  assert(entry.width <= entry.innerWidth, `Math feature entry overflow: ${JSON.stringify(entry)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.add('exam-prep-host-open');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"><div><div class="ep-live-dashboard-eyebrow">Your route</div><h3 class="ep-live-dashboard-title">Preparation for P1 and P5</h3><p class="ep-live-dashboard-text">Each component moves separately with its own phase, evidence and next action.</p></div><div class="ep-live-dashboard-profile">May/June 2027 · A</div></div><div class="ep-live-grid"><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P1</span><div class="ep-live-component-copy"><strong>Pure Mathematics 1</strong><span>45 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Open weekly plan</button></div></article><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P5</span><div class="ep-live-component-copy"><strong>Probability & Statistics 1</strong><span>36 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Start the next check section</button></div></article></div></section>`;
  });

  const dashboard = await page.evaluate(() => ({
    introRadius: getComputedStyle(document.querySelector('.ep-live-dashboard-intro')).borderRadius,
    cardCount: document.querySelectorAll('.ep-live-component-card').length,
    gridColumns: getComputedStyle(document.querySelector('#exam-prep-host-root .ep-live-grid')).gridTemplateColumns,
    primaryBg: getComputedStyle(document.querySelector('.ep-live-component-card .ep-live-btn')).backgroundColor,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(dashboard.introRadius === '12px', `Exam Prep dashboard intro radius drift: ${dashboard.introRadius}`);
  assert(dashboard.cardCount === 2, `Exam Prep dashboard must keep P1/P5 as two separate cards: ${dashboard.cardCount}`);
  assert(dashboard.width <= dashboard.innerWidth, `Exam Prep dashboard overflow: ${JSON.stringify(dashboard)}`);

  await browser.close();
  console.log('Visual v3 Math Exam Prep UX regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
''', encoding='utf-8')


# 7) Extend permanent premium gate and cache-key checks.
visual_workflow_path = '.github/workflows/visual-v3-premium.yml'
workflow = read(visual_workflow_path)
workflow = workflow.replace("      - '.github/scripts/visual_v3_assessment_regression.js'\n      - '.github/workflows/visual-v3-premium.yml'", "      - '.github/scripts/visual_v3_assessment_regression.js'\n      - '.github/scripts/visual_v3_math_exam_prep_ux_regression.js'\n      - '.github/workflows/visual-v3-premium.yml'")
workflow = workflow.replace("          test -f .github/scripts/visual_v3_assessment_regression.js\n          node --check .github/scripts/visual_v3_premium_regression.js", "          test -f .github/scripts/visual_v3_assessment_regression.js\n          test -f .github/scripts/visual_v3_math_exam_prep_ux_regression.js\n          node --check .github/scripts/visual_v3_premium_regression.js")
workflow = workflow.replace("          node --check .github/scripts/visual_v3_assessment_regression.js\n          grep -q 'visual/iclub-premium-v3.css?v=premium1' index.html", "          node --check .github/scripts/visual_v3_assessment_regression.js\n          node --check .github/scripts/visual_v3_math_exam_prep_ux_regression.js\n          grep -q 'visual/iclub-premium-v3.css?v=premium2' index.html")
workflow = workflow.replace("          grep -q 'PREMIUM ASSESSMENT FLOWS v3' visual/iclub-premium-v3.css\n          grep -q 'class=\"v3-tour-warning-icon\"' index.html", "          grep -q 'PREMIUM ASSESSMENT FLOWS v3' visual/iclub-premium-v3.css\n          grep -q 'PREMIUM MATHEMATICS EXAM PREP UX v3' visual/iclub-premium-v3.css\n          grep -q 'class=\"v3-tour-warning-icon\"' index.html")
workflow = workflow.replace("          node .github/scripts/visual_v3_assessment_regression.js\n", "          node .github/scripts/visual_v3_assessment_regression.js\n          node .github/scripts/visual_v3_math_exam_prep_ux_regression.js\n")
write(visual_workflow_path, workflow)

# Existing premium regression must follow the cache key.
premium_reg_path = '.github/scripts/visual_v3_premium_regression.js'
premium_reg = read(premium_reg_path)
premium_reg = replace_once(premium_reg, 'visual/iclub-premium-v3.css?v=premium1', 'visual/iclub-premium-v3.css?v=premium2', 'premium regression cache key')
write(premium_reg_path, premium_reg)

# Host regression workflow and legacy OFF regression must accept the new host cache key.
host_workflow_path = '.github/workflows/p0-14-host-regression.yml'
host_workflow = read(host_workflow_path)
host_workflow = replace_once(host_workflow, "grep -q 'exam-prep/exam-prep-host.js?v=p014h1' index.html", "grep -q 'exam-prep/exam-prep-host.js?v=p014ux2' index.html", 'host workflow js key')
host_workflow = replace_once(host_workflow, "grep -q 'exam-prep/exam-prep-host.css?v=p014h1' index.html", "grep -q 'exam-prep/exam-prep-host.css?v=p014ux2' index.html", 'host workflow css key')
write(host_workflow_path, host_workflow)

legacy_reg_path = '.github/scripts/p0_14_legacy_off_regression.js'
legacy_reg = read(legacy_reg_path)
legacy_reg = legacy_reg.replace("exam-prep/exam-prep-host.js?v=p014h1", "exam-prep/exam-prep-host.js?v=p014ux2")
legacy_reg = legacy_reg.replace("exam-prep/exam-prep-host.css?v=p014h1", "exam-prep/exam-prep-host.css?v=p014ux2")
write(legacy_reg_path, legacy_reg)

print('Math Exam Prep UX architecture patch staged successfully')
