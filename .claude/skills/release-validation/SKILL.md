---
name: release-validation
description: Use before handing off a meaningful code change, PR or MVP milestone.
---

# Release Validation

Inspect git diff and worktree status. Run actual available formatting, lint, typecheck, backend tests, DB integration tests, frontend tests and browser smoke; record exact commands/results/skips. Verify secrets, env placeholders, docs, DEMO labeling, CI and accessibility. Do not bypass failures, update baselines blindly or report unrun checks as passes. Produce handoff summary.
