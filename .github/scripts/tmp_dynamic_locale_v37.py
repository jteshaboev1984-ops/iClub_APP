from pathlib import Path
from textwrap import dedent

CSS = Path('visual/iclub-premium-v3.css')
css = CSS.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM DYNAMIC LOCALE SURFACES v3.7 ===== */'
if marker in css:
    raise SystemExit('Dynamic locale v3.7 already present')

block = dedent('''
/* ===== PREMIUM DYNAMIC LOCALE SURFACES v3.7 ===== */
/* Generated learner data keeps the same premium hierarchy as the static shell. */
.iclub-visual-v3 #view-profile .slot-list {
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
  margin-top: 10px;
}

.iclub-visual-v3 #view-profile .slot-card {
  min-width: 0;
  padding: 12px 13px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: #FFFFFF;
  color: var(--v3-text);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #view-profile .slot-card.is-empty {
  border-style: dashed;
  background: #FAFBFD;
  color: var(--v3-muted);
  box-shadow: none;
}

.iclub-visual-v3 #view-profile .slot-title {
  min-width: 0;
  color: var(--v3-text);
  font-size: 12.5px;
  line-height: 1.32;
  font-weight: 780;
  letter-spacing: -0.006em;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-profile .profile-credentials-grid {
  gap: 8px;
  margin-top: 10px;
}

.iclub-visual-v3 #view-profile .credential-card {
  min-width: 0;
  padding: 12px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: #FFFFFF;
  color: var(--v3-text);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #view-profile .credential-item {
  min-width: 0;
  gap: 10px;
  align-items: flex-start;
}

.iclub-visual-v3 #view-profile .credential-ico {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  display: grid;
  place-items: center;
  border: 1px solid #D8E3FB;
  border-radius: var(--v3-radius-sm);
  background: var(--v3-primary-soft);
  color: var(--v3-primary);
  font-size: 14px;
  font-weight: 800;
  box-shadow: none;
}

.iclub-visual-v3 #view-profile .credential-title {
  min-width: 0;
  color: var(--v3-text);
  font-size: 12.5px;
  line-height: 1.35;
  font-weight: 770;
  letter-spacing: -0.006em;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-profile .credential-meta {
  min-width: 0;
  margin-top: 3px;
  color: var(--v3-muted);
  font-size: 10.5px;
  line-height: 1.42;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-profile .cred-progress-item {
  min-width: 0;
  margin-top: 9px;
  padding: 9px 10px;
  border: 1px solid #E5EAF2;
  border-radius: var(--v3-radius-sm);
  background: #F8FAFD;
  color: var(--v3-muted);
  font-size: 10.5px;
  line-height: 1.4;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-ratings .lb-row {
  grid-template-columns: 38px minmax(0, 1fr) 56px 52px;
  gap: 7px;
  min-height: 58px;
  padding: 9px 10px;
  align-items: center;
}

.iclub-visual-v3 #view-ratings .lb-rank,
.iclub-visual-v3 #view-ratings .lb-score,
.iclub-visual-v3 #view-ratings .lb-time {
  min-width: 0;
  color: var(--v3-text);
  font-size: 11.5px;
  line-height: 1.25;
  font-weight: 780;
}

.iclub-visual-v3 #view-ratings .lb-score,
.iclub-visual-v3 #view-ratings .lb-time {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.iclub-visual-v3 #view-ratings .lb-student,
.iclub-visual-v3 #view-ratings .lb-student-txt {
  min-width: 0;
}

.iclub-visual-v3 #view-ratings .lb-student {
  gap: 8px;
}

.iclub-visual-v3 #view-ratings .lb-avatar {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  border: 1px solid #D8E3FB;
  border-radius: var(--v3-radius-sm);
  background: var(--v3-primary-soft);
  color: var(--v3-primary);
  font-size: 10.5px;
  font-weight: 800;
  box-shadow: none;
}

.iclub-visual-v3 #view-ratings .lb-name {
  min-width: 0;
  color: var(--v3-text);
  font-size: 12.5px;
  line-height: 1.24;
  font-weight: 780;
  letter-spacing: -0.006em;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-ratings .lb-meta {
  min-width: 0;
  margin-top: 3px;
  color: var(--v3-muted);
  font-size: 10.5px;
  line-height: 1.28;
  font-weight: 600;
  white-space: normal;
  overflow-wrap: break-word;
}

/* LANGUAGE-SAFE WRAPPING */
.iclub-visual-v3 #view-home .home-block-title,
.iclub-visual-v3 #view-home .home-block-sub,
.iclub-visual-v3 #view-home .home-pinned-title,
.iclub-visual-v3 #view-home .home-pinned-meta,
.iclub-visual-v3 #view-courses .section-title,
.iclub-visual-v3 #view-courses .subject-mode-status,
.iclub-visual-v3 #view-courses .subject-mode-title,
.iclub-visual-v3 #view-courses .subject-mode-description,
.iclub-visual-v3 #view-courses .settings-nav-text,
.iclub-visual-v3 #view-courses .settings-nav-title,
.iclub-visual-v3 #view-courses .settings-nav-sub,
.iclub-visual-v3 #view-profile .profile-section-title,
.iclub-visual-v3 #view-profile .profile-row-mid,
.iclub-visual-v3 #view-profile .profile-row-title,
.iclub-visual-v3 #view-profile .profile-row .muted,
.iclub-visual-v3 #view-ratings .seg-btn,
.iclub-visual-v3 #view-ratings .lb-filter-label,
.iclub-visual-v3 #view-ratings .lb-hint,
.iclub-visual-v3 #view-notifications .notification-title,
.iclub-visual-v3 #view-notifications .notification-body,
.iclub-visual-v3 #view-support .card-title,
.iclub-visual-v3 #view-support-topic .card-title,
.iclub-visual-v3 #view-support-topic .muted,
.iclub-visual-v3 #modal-root .modal-title,
.iclub-visual-v3 #modal-root .modal-text {
  min-width: 0;
  max-width: 100%;
  white-space: normal;
  overflow-wrap: break-word;
}

.iclub-visual-v3 #view-registration .reg-consent,
.iclub-visual-v3 #view-registration .field-hint,
.iclub-visual-v3 #view-registration .field-note {
  overflow-wrap: break-word;
}

@media (max-width: 350px) {
  .iclub-visual-v3 #view-ratings .lb-row {
    grid-template-columns: 32px minmax(0, 1fr) 48px 44px;
    gap: 5px;
    padding: 8px 7px;
  }

  .iclub-visual-v3 #view-ratings .lb-avatar {
    width: 30px;
    height: 30px;
    flex-basis: 30px;
    font-size: 9.5px;
  }

  .iclub-visual-v3 #view-ratings .lb-name {
    font-size: 11.5px;
  }

  .iclub-visual-v3 #view-ratings .lb-meta {
    font-size: 9.5px;
  }

  .iclub-visual-v3 #view-ratings .lb-rank,
  .iclub-visual-v3 #view-ratings .lb-score,
  .iclub-visual-v3 #view-ratings .lb-time {
    font-size: 10.5px;
  }

  .iclub-visual-v3 #view-profile .credential-card,
  .iclub-visual-v3 #view-profile .slot-card {
    padding: 11px;
  }
}
''').strip()

CSS.write_text(css.rstrip() + '\n\n' + block + '\n', encoding='utf-8')
