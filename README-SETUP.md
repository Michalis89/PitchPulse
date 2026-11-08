# PitchPulse agentic setup

This repository contains an agent setup, not an application implementation. AGENTS.md is canonical; CLAUDE.md imports it using `@AGENTS.md`. Either Codex or Claude may implement a task, with the other independently reviewing a stable diff.

## Local setup (Windows PowerShell)
1. Open the repository root and inspect `git status` and the policy files before editing. Untracked files are not included in ordinary `git diff`; include them in review.
2. Restart agent sessions after changing instruction, skill or subagent files. Inspect Claude's loaded memory/context and `/agents` to confirm the import and restricted tools; exact diagnostics depend on the installed version.
3. Shared skills are in `.agents/skills` and `.claude/skills`; their relative paths and contents must match. Validate with `python scripts/check_agentic_policy.py` and `python -m unittest discover -s scripts/tests -v`.
4. `.claude/settings.example.json` is an inactive example. If manually adopted later, review it first; it registers no hooks. Its broad `.env.*` Read denial also blocks placeholder examples. It does not prevent secret access through other tools and is not a sandbox.
   Shared `.claude/settings.json` may be committed after review and policy validation; it is not created by this setup. The accepted schema permits only optional empty `hooks` and `permissions.deny`/`permissions.ask` lists of nonempty strings. Tool grants, permission-mode overrides, environment values and other fields are rejected. Keep secrets and machine-specific settings in ignored local files, never in shared configuration.
5. Leave MCP servers and hooks disabled unless a separate task needs and authorizes them. No global configuration is required by this setup.
6. Assign one lead and one independent reviewer per task. No commit, push, merge or deployment without explicit owner instruction. Phase 1 scaffolding is a separate task.

## What's included
- AGENTS.md, CLAUDE.md, design/testing/agent docs, patched architecture and decisions
- Paired Codex/Claude repo-local SKILL.md workflows
- Claude code-review specialist subagents
- Inactive Claude settings example; the unreliable regex shell guard has been removed
- Suggested MCP tooling guidance (no credentials or services auto-enabled)
- CI policy validation, mirrored skill checks, failure-case tests and pinned Gitleaks content/history scanning

## Example prompt for a later Phase 1 task
`ROLE: IMPLEMENTER. You are the lead implementer for PitchPulse Phase 1. Read AGENTS.md and relevant docs; reconcile existing repo state; implement one runnable vertical slice with a PostgreSQL-backed demo match, Spring Boot REST/SSE and Angular match center. Use relevant skills. Follow design tokens. Run and report actual checks, document blockers. Do not commit or push. Prepare a frozen diff for independent review by the other agent.`

## Important
This setup does not verify or change the remote repository. Local files are not uploaded until explicitly committed and pushed. See `docs/setup-remediation.md` for local verification and known limits.

`.gitattributes` normalizes text to LF without global Git changes; binary formats are excluded from text conversion.
