from pathlib import Path

css_path = Path('visual/iclub-premium-v3.css')
css = css_path.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM ASSESSMENT FLOWS v3 ===== */'
if marker in css:
    raise SystemExit('premium assessment layer already present')

css += r'''

/* ===== PREMIUM ASSESSMENT FLOWS v3 ===== */

/* Practice and Tours share the same academic surface language. */
.iclub-visual-v3 #courses-practice-start,
.iclub-visual-v3 #courses-practice-quiz,
.iclub-visual-v3 #courses-practice-result,
.iclub-visual-v3 #courses-practice-review,
.iclub-visual-v3 #courses-practice-recs,
.iclub-visual-v3 #courses-tours,
.iclub-visual-v3 #courses-tour-rules,
.iclub-visual-v3 #courses-tour-quiz,
.iclub-visual-v3 #courses-tour-result,
.iclub-visual-v3 #courses-tour-review,
.iclub-visual-v3 #courses-books,
.iclub-visual-v3 #courses-my-recs,
.iclub-visual-v3 #courses-my-rec-detail {
  width: 100%;
  max-width: 700px;
  margin-inline: auto;
  padding-bottom: 24px;
}

.iclub-visual-v3 #courses-practice-start > .section,
.iclub-visual-v3 #courses-practice-result > .section,
.iclub-visual-v3 #courses-practice-review > .section,
.iclub-visual-v3 #courses-practice-recs > .section,
.iclub-visual-v3 #courses-tours > .section,
.iclub-visual-v3 #courses-tour-rules > .section,
.iclub-visual-v3 #courses-tour-result > .section,
.iclub-visual-v3 #courses-tour-review > .section,
.iclub-visual-v3 #courses-books > .section,
.iclub-visual-v3 #courses-my-recs > .section,
.iclub-visual-v3 #courses-my-rec-detail > .section {
  margin-bottom: 12px;
}

.iclub-visual-v3 #courses-practice-start .h1,
.iclub-visual-v3 #courses-practice-result .h1,
.iclub-visual-v3 #courses-practice-review .h1,
.iclub-visual-v3 #courses-practice-recs .h1,
.iclub-visual-v3 #courses-tours .h1,
.iclub-visual-v3 #courses-tour-rules .h1,
.iclub-visual-v3 #courses-tour-result .h1,
.iclub-visual-v3 #courses-tour-review .h1,
.iclub-visual-v3 #courses-books .h1,
.iclub-visual-v3 #courses-my-recs .h1,
.iclub-visual-v3 #courses-my-rec-detail .h1 {
  color: var(--v3-text);
  font-size: 22px;
  line-height: 1.15;
  font-weight: 800;
  letter-spacing: -0.024em;
}

/* Practice start */
.iclub-visual-v3 #courses-practice-start .practice-tour-picker {
  margin: 10px 0 12px;
}

.iclub-visual-v3 #courses-practice-start .practice-tour-picker-head {
  margin-bottom: 7px;
  color: var(--v3-muted);
  font-size: 10.5px;
  font-weight: 760;
  letter-spacing: 0.045em;
  text-transform: uppercase;
}

.iclub-visual-v3 #courses-practice-start .practice-tour-picker button,
.iclub-visual-v3 #courses-practice-start .practice-tour-picker .chip {
  min-height: 34px;
  border: 1px solid var(--v3-border);
  border-radius: 999px;
  background: var(--v3-card);
  color: var(--v3-muted);
  box-shadow: none;
}

.iclub-visual-v3 #courses-practice-start .practice-tour-picker button.is-active,
.iclub-visual-v3 #courses-practice-start .practice-tour-picker .chip.is-active {
  border-color: #D0DCFB;
  background: var(--v3-primary-soft);
  color: var(--v3-primary);
}

.iclub-visual-v3 #courses-practice-start .practice-hero,
.iclub-visual-v3 #courses-tours .tours-hero {
  position: relative;
  overflow: hidden;
  margin: 0 0 12px;
  padding: 15px;
  border: 1px solid var(--v3-premium-blue-line);
  border-radius: var(--v3-radius-lg);
  background: linear-gradient(135deg, #FFFFFF 0%, #F3F7FF 100%);
  color: var(--v3-text);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #courses-practice-start .practice-hero::before,
.iclub-visual-v3 #courses-tours .tours-hero::before {
  content: "";
  position: absolute;
  inset: 0 auto 0 0;
  width: 3px;
  background: var(--v3-primary);
}

.iclub-visual-v3 #courses-practice-start .practice-hero-kicker,
.iclub-visual-v3 #courses-tours .tours-hero-kicker {
  color: var(--v3-primary);
  opacity: 1;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.075em;
}

.iclub-visual-v3 #courses-practice-start .practice-hero-title,
.iclub-visual-v3 #courses-tours .tours-hero-title {
  margin-top: 4px;
  color: var(--v3-text);
  font-size: 20px;
  line-height: 1.15;
  font-weight: 810;
  letter-spacing: -0.022em;
}

.iclub-visual-v3 #courses-practice-start .practice-hero-stage,
.iclub-visual-v3 #courses-tours .tours-hero-sub {
  color: var(--v3-muted);
  opacity: 1;
  font-size: 11px;
  font-weight: 700;
}

.iclub-visual-v3 #courses-practice-start .practice-hero-metrics,
.iclub-visual-v3 #courses-tours .tours-hero-metrics {
  gap: 8px;
  margin-top: 12px;
}

.iclub-visual-v3 #courses-practice-start .practice-metric,
.iclub-visual-v3 #courses-tours .tours-metric {
  min-width: 0;
  padding: 10px 11px;
  border: 1px solid #DEE7FA;
  border-radius: var(--v3-radius-md);
  background: rgba(255, 255, 255, 0.82);
}

.iclub-visual-v3 #courses-practice-start .practice-metric-label,
.iclub-visual-v3 #courses-tours .tours-metric-label {
  color: var(--v3-muted);
  opacity: 1;
  font-size: 10.5px;
  line-height: 1.3;
}

.iclub-visual-v3 #courses-practice-start .practice-metric-value,
.iclub-visual-v3 #courses-tours .tours-metric-value {
  margin-top: 4px;
  color: var(--v3-text);
  font-size: 17px;
  font-weight: 810;
  letter-spacing: -0.015em;
}

.iclub-visual-v3 #courses-practice-start .practice-metric-sub,
.iclub-visual-v3 #courses-tours .tours-metric-sub {
  color: var(--v3-muted);
  opacity: 1;
  font-size: 10px;
}

.iclub-visual-v3 #courses-practice-start .practice-micro,
.iclub-visual-v3 #courses-tours .tours-micro {
  margin-top: 11px;
  padding-top: 9px;
  border-top-color: var(--v3-border);
}

.iclub-visual-v3 #courses-practice-start .practice-micro-label,
.iclub-visual-v3 #courses-practice-start .practice-micro-delta,
.iclub-visual-v3 #courses-tours .tours-micro-label,
.iclub-visual-v3 #courses-tours .tours-micro-delta {
  color: var(--v3-muted);
  opacity: 1;
  font-size: 10.5px;
}

.iclub-visual-v3 #courses-practice-start .practice-micro-bar,
.iclub-visual-v3 #courses-tours .tours-micro-bar {
  border-color: #D7E2FB;
  background: #DDE6F8;
}

.iclub-visual-v3 #courses-practice-start .practice-micro-bar.is-last,
.iclub-visual-v3 #courses-tours .tours-micro-bar.is-last {
  border-color: #B8CAF4;
  background: var(--v3-primary);
}

.iclub-visual-v3 #courses-practice-start .practice-last,
.iclub-visual-v3 #courses-tours .tours-history,
.iclub-visual-v3 #courses-tours .tours-status {
  margin: 0 0 10px;
  padding: 14px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #courses-practice-start .practice-last-head .card-title,
.iclub-visual-v3 #courses-tours .tours-history-title,
.iclub-visual-v3 #courses-tours .tours-status-title {
  color: var(--v3-text);
  font-size: 13px;
  font-weight: 770;
}

.iclub-visual-v3 #courses-practice-start .practice-table-wrap {
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
}

.iclub-visual-v3 #courses-practice-start .practice-table thead th {
  padding: 9px 10px;
  background: #F7F9FD;
  color: var(--v3-muted);
  font-size: 9.5px;
  letter-spacing: 0.055em;
}

.iclub-visual-v3 #courses-practice-start .practice-table tbody td {
  padding: 10px;
  border-top-color: var(--v3-border);
}

.iclub-visual-v3 #courses-practice-start .practice-start-actions,
.iclub-visual-v3 #courses-tours .tours-open-wrap {
  margin: 12px 0 0;
}

/* Practice quiz */
.iclub-visual-v3 #courses-practice-quiz .quiz-top {
  margin: 6px 0 12px;
  padding: 9px 10px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: rgba(255, 255, 255, 0.88);
}

.iclub-visual-v3 #courses-practice-quiz .quiz-progress {
  color: var(--v3-text);
  font-size: 12px;
  font-weight: 760;
}

.iclub-visual-v3 #courses-practice-quiz .pill {
  border-color: #D6E1FA;
  background: var(--v3-primary-soft);
  color: var(--v3-primary);
  box-shadow: none;
  font-size: 10.5px;
  font-weight: 800;
}

.iclub-visual-v3 #courses-practice-quiz > .card,
.iclub-visual-v3 #courses-tour-quiz > .card,
.iclub-visual-v3 #courses-tour-rules > .card,
.iclub-visual-v3 #courses-tour-result > .card,
.iclub-visual-v3 #courses-tour-review > .card,
.iclub-visual-v3 #courses-practice-result > .card,
.iclub-visual-v3 #courses-practice-review > .card,
.iclub-visual-v3 #courses-practice-recs > .card {
  padding: 14px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #courses-practice-quiz .question-text,
.iclub-visual-v3 #courses-tour-quiz .question-text {
  margin-bottom: 12px;
  color: var(--v3-text);
  font-size: 15px;
  line-height: 1.48;
  font-weight: 720;
  letter-spacing: -0.006em;
}

.iclub-visual-v3 #courses-practice-quiz .options,
.iclub-visual-v3 #courses-tour-quiz .options {
  gap: 8px;
}

.iclub-visual-v3 #courses-practice-quiz .option,
.iclub-visual-v3 #courses-tour-quiz .option {
  min-height: 48px;
  padding: 11px 12px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FBFCFF;
  box-shadow: none;
}

.iclub-visual-v3 #courses-practice-quiz .option.is-selected,
.iclub-visual-v3 #courses-tour-quiz .option.is-selected {
  border-color: #AFC3F4;
  background: var(--v3-primary-soft);
  box-shadow: 0 0 0 2px rgba(36, 87, 214, 0.08);
}

.iclub-visual-v3 #courses-practice-quiz .option .dot,
.iclub-visual-v3 #courses-tour-quiz .option .dot {
  width: 9px;
  height: 9px;
  flex-basis: 9px;
  border-color: #A8B7D5;
}

.iclub-visual-v3 #courses-practice-quiz .option.is-selected .dot,
.iclub-visual-v3 #courses-tour-quiz .option.is-selected .dot {
  border-color: var(--v3-primary);
  background: var(--v3-primary);
}

.iclub-visual-v3 #courses-practice-quiz .input-wrap,
.iclub-visual-v3 #courses-tour-quiz .input-wrap {
  padding: 10px;
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FBFCFF;
}

.iclub-visual-v3 #courses-practice-quiz .text-input,
.iclub-visual-v3 #courses-tour-quiz .text-input {
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FFFFFF;
}

/* Practice result/review */
.iclub-visual-v3 #courses-practice-result .cards-grid,
.iclub-visual-v3 #courses-tour-result .cards-grid {
  gap: 10px;
}

.iclub-visual-v3 #courses-practice-result .card-btn,
.iclub-visual-v3 #courses-tour-result .card-btn {
  min-height: 72px;
  padding: 13px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-premium-shadow);
  text-align: left;
}

.iclub-visual-v3 #courses-practice-review .list > *,
.iclub-visual-v3 #courses-practice-recs .list > *,
.iclub-visual-v3 #courses-tour-review .list > *,
.iclub-visual-v3 #courses-books .list > *,
.iclub-visual-v3 #courses-my-recs .list > *,
.iclub-visual-v3 #courses-my-rec-detail .list > * {
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-shadow-soft);
}

/* Tours overview */
.iclub-visual-v3 #courses-tours .tours-history-row {
  padding: 10px 11px;
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FBFCFF;
}

.iclub-visual-v3 #courses-tours .tours-open-wrap + .actions-row,
.iclub-visual-v3 #courses-tours > .actions-row {
  margin-top: 10px;
}

/* Tour rules */
.iclub-visual-v3 #courses-tour-rules > .card {
  margin-top: 10px;
}

.iclub-visual-v3 #courses-tour-rules .checkbox {
  display: flex;
  align-items: flex-start;
  gap: 9px;
  margin-top: 12px;
  padding: 11px 12px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FBFCFF;
  color: var(--v3-text);
  font-size: 12px;
  line-height: 1.4;
}

/* Tour quiz */
.iclub-visual-v3 #courses-tour-quiz .tour-head {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 36px;
  gap: 10px;
  align-items: start;
  margin: 4px 0 10px;
  padding: 11px 12px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-shadow-soft);
}

.iclub-visual-v3 #courses-tour-quiz .tour-qof {
  color: var(--v3-text);
  font-size: 12px;
  font-weight: 780;
}

.iclub-visual-v3 #courses-tour-quiz .tour-progress-row {
  margin-top: 6px;
}

.iclub-visual-v3 #courses-tour-quiz .tour-progress-label,
.iclub-visual-v3 #courses-tour-quiz .tour-progress-pct {
  color: var(--v3-muted);
  font-size: 10px;
  font-weight: 760;
}

.iclub-visual-v3 #courses-tour-quiz .tour-progress-bar {
  height: 5px;
  margin-top: 5px;
  border-radius: 999px;
  background: #E8EDF5;
}

.iclub-visual-v3 #courses-tour-quiz .tour-progress-fill {
  border-radius: inherit;
  background: var(--v3-primary);
}

.iclub-visual-v3 #courses-tour-quiz .tour-warn {
  width: 36px;
  height: 36px;
  display: grid;
  place-items: center;
  padding: 0;
  border: 1px solid #F0D8A9;
  border-radius: var(--v3-radius-md);
  background: #FFF9ED;
  color: #9A6418;
  font-size: 0;
  box-shadow: none;
}

.iclub-visual-v3 #courses-tour-quiz .v3-tour-warning-icon {
  width: 18px;
  height: 18px;
  display: block;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.iclub-visual-v3 #courses-tour-quiz .tour-badges {
  margin: 0 0 9px;
}

.iclub-visual-v3 #courses-tour-quiz .tour-badge {
  display: inline-flex;
  align-items: center;
  min-height: 26px;
  padding: 5px 8px;
  border: 1px solid #D5E0FA;
  border-radius: 999px;
  background: var(--v3-primary-soft);
  color: var(--v3-primary);
  font-size: 9.5px;
  font-weight: 800;
  letter-spacing: 0.045em;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timers {
  gap: 8px;
  margin: 0 0 10px;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timer-card {
  min-width: 0;
  padding: 10px 11px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: #FBFCFF;
  box-shadow: none;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timer-card.danger {
  border-color: #F0D5D0;
  background: #FFF5F3;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timer-cap {
  color: var(--v3-muted);
  font-size: 9px;
  font-weight: 780;
  letter-spacing: 0.055em;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timer-val {
  margin-top: 4px;
  color: var(--v3-text);
  font-size: 18px;
  font-weight: 810;
  letter-spacing: -0.015em;
}

.iclub-visual-v3 #courses-tour-quiz .tour-timer-card.danger .tour-timer-val,
.iclub-visual-v3 #courses-tour-quiz .tour-timer-card.danger .tour-timer-delta {
  color: var(--v3-danger);
}

.iclub-visual-v3 #courses-tour-quiz .tour-monitor {
  margin-top: 9px;
  padding: 8px 10px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-sm);
  background: #F8FAFD;
  color: var(--v3-muted);
  font-size: 9px;
  font-weight: 760;
  letter-spacing: 0.045em;
  text-align: center;
}

/* Assessment actions */
.iclub-visual-v3 #courses-practice-start .btn,
.iclub-visual-v3 #courses-practice-quiz .btn,
.iclub-visual-v3 #courses-practice-result .btn,
.iclub-visual-v3 #courses-practice-review .btn,
.iclub-visual-v3 #courses-practice-recs .btn,
.iclub-visual-v3 #courses-tours .btn,
.iclub-visual-v3 #courses-tour-rules .btn,
.iclub-visual-v3 #courses-tour-quiz .btn,
.iclub-visual-v3 #courses-tour-result .btn,
.iclub-visual-v3 #courses-tour-review .btn,
.iclub-visual-v3 #courses-my-rec-detail .btn {
  min-height: 42px;
  border-radius: var(--v3-radius-md);
  box-shadow: none;
}

.iclub-visual-v3 #courses-practice-start .btn.primary,
.iclub-visual-v3 #courses-practice-quiz .btn.primary,
.iclub-visual-v3 #courses-practice-result .btn.primary,
.iclub-visual-v3 #courses-practice-review .btn.primary,
.iclub-visual-v3 #courses-practice-recs .btn.primary,
.iclub-visual-v3 #courses-tours .btn.primary,
.iclub-visual-v3 #courses-tour-rules .btn.primary,
.iclub-visual-v3 #courses-tour-quiz .btn.primary,
.iclub-visual-v3 #courses-tour-result .btn.primary,
.iclub-visual-v3 #courses-tour-review .btn.primary,
.iclub-visual-v3 #courses-my-rec-detail .btn.primary {
  border-color: var(--v3-primary);
  background: var(--v3-primary);
  color: #FFFFFF;
  box-shadow: 0 5px 14px rgba(36, 87, 214, 0.16);
}

.iclub-visual-v3 #courses-my-rec-detail .btn.danger {
  border-color: #F1D2CF;
  background: var(--v3-danger-soft);
  color: var(--v3-danger);
  box-shadow: none;
}

@media (max-width: 430px) {
  .iclub-visual-v3 #courses-practice-start .practice-hero-metrics,
  .iclub-visual-v3 #courses-tours .tours-hero-metrics,
  .iclub-visual-v3 #courses-tour-quiz .tour-timers {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .iclub-visual-v3 #courses-practice-quiz .question-text,
  .iclub-visual-v3 #courses-tour-quiz .question-text {
    font-size: 14px;
  }
}

@media (max-width: 340px) {
  .iclub-visual-v3 #courses-practice-start .practice-hero-metrics,
  .iclub-visual-v3 #courses-tours .tours-hero-metrics,
  .iclub-visual-v3 #courses-tour-quiz .tour-timers {
    grid-template-columns: 1fr;
  }
}
'''

css_path.write_text(css, encoding='utf-8')

index_path = Path('index.html')
index = index_path.read_text(encoding='utf-8')
old = '''<button id="tour-warn-btn" class="tour-warn" type="button" aria-label="Warning" style="display:none">
      ⚠️
    </button>'''
new = '''<button id="tour-warn-btn" class="tour-warn" type="button" aria-label="Warning" style="display:none">
      <svg class="v3-tour-warning-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4l9 16H3z"/><path d="M12 9v5"/><path d="M12 17h.01"/></svg>
    </button>'''
if index.count(old) != 1:
    raise SystemExit(f'tour warning anchor count={index.count(old)}')
index_path.write_text(index.replace(old, new, 1), encoding='utf-8')

print('Premium assessment flow patch prepared')
