---
name: visual-testing
description: Use when verifying browser UI, responsive behavior and screenshot regressions.
---

# Visual Testing

Use Playwright with seeded fixtures, controlled clock, stable fonts, animations disabled/reduced, and a consistent browser/OS. Test home and match center using the canonical viewport matrix in docs/design-system.md; broadcast applies only in Phase 3 after that route is implemented. Review failed screenshot differences before updating baselines; never auto-approve changed baselines. Inspect console errors, keyboard flow, overlays, overflow and aria roles. Report screenshot paths and exact test commands.
