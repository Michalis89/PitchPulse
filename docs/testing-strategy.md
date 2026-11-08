# Testing strategy

## Levels
- Backend: JUnit unit tests for rules, integration tests for DB migrations, REST DTOs and SSE idempotency/reconnect. Testcontainers if runtime/Docker available; document skips.
- Frontend: Angular unit tests for typed views/state, Playwright browser smoke tests for home, match center, reconnect and responsive layout.
- Data integrity: duplicated events, out-of-order events, corrections, HT/FT, suspended/postponed matches, UTC/Athens dates.
- Accessibility: semantic roles, keyboard order, contrast checks and reduced motion; automated a11y checks supplement manual review.
- Visual: Playwright `toHaveScreenshot` with deterministic demo data and stable browser/OS. Use the canonical viewport matrix in `docs/design-system.md`; broadcast applies only in Phase 3. Initial snapshot creation needs human approval and review of the baseline.

## Quality gates
- Current setup checks: `python scripts/check_agentic_policy.py`, `python -m unittest discover -s scripts/tests -v`, and Gitleaks directory/history scans in `.github/workflows/agentic-policy.yml`. No app checks exist yet.
- Phase 1 required PR checks once implemented: compile, lint, unit, database-backed integration, Playwright smoke, secret scan and migration validation. CI must provision required database infrastructure; a local infrastructure skip is a reported gap, never a Phase 1 acceptance pass.
- No passing result may be claimed without explicit command output. Do not disable tests or adjust screenshots solely to hide regressions.
- Screenshot baselines may vary across OS; use a pinned CI image and browser version for comparisons.
- Agent reports test commands, pass/fail, skips and missing prerequisites in handoff.
