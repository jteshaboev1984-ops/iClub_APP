# Economics Diagnostic Pilot — Risk Register

Date: 2026-07-03

## Risk 1 — rewriting old options

Status: avoided.

Control:

- old options were not rewritten;
- diagnostic mapping was added separately.

## Risk 2 — changing old scores

Status: avoided.

Control:

- no `practice_answers` or `tour_answers` rows were changed;
- no historical recalculation was run.

## Risk 3 — false-negative input answers

Status: handled for future flow.

Control:

- future evaluator accepts conceptually correct unit variants for question `1018`;
- old score recalculation remains blocked until explicit approval.

## Risk 4 — answer key exposure

Status: still legacy risk in current app; partially mitigated for pilot.

Control:

- pilot should use safe question delivery;
- old public read policy must not be removed until pilot frontend is tested.

## Risk 5 — full subject overclaim

Status: avoided.

Control:

- Economics full-subject diagnostic audit remains not ready;
- only the selected pilot subset is treated as demo-ready at the data layer.

## Risk 6 — frontend disruption

Status: pending.

Control:

- next UI work must be hidden/demo route only;
- do not replace live practice/tour screens first.
