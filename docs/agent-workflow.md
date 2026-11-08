# Codex + Claude workflow

## Per task
1. Human chooses lead: Codex **or** Claude. Other agent is independent reviewer.
2. Lead edits the assigned local checkout; use isolated branches/worktrees when parallel writing is assigned. Do not commit, push or merge without explicit owner instruction.
3. Lead runs available relevant checks, supplies a frozen diff plus untracked-file inventory and screenshots where relevant, and lists gaps. App checks are unavailable until scaffolding exists.
4. Human approves creation/push of PR or shares a frozen diff with reviewer.
5. Reviewer assesses correctness, data integrity, security, design and tests; starts read-only.
6. Lead fixes findings, adds regression tests, revalidates. Reviewer rechecks blockers.
7. Human approves merge/deploy. No agent auto-merge or production changes.

## Review handoff
Include: goal, branch/base/head SHA (if available), changed areas, exact validation commands/results, screenshots, risks and open questions.

## Parallel task isolation
For owner-authorized concurrent implementation, create separate branches/worktrees from the agreed base. Never let two writing agents share one working tree. Worktrees do not replace review. The exact base is task-specific; do not assume a local `develop` branch exists. A new worktree contains only committed base files: while this setup is untracked, review the frozen local files and do not assume policy follows into a new worktree. The owner must authorize committing/publishing the setup before future task worktrees or remote CI can rely on it.

Each parallel task brief records its lead, owned files/areas and integration strategy. Only the integrating lead updates shared `docs/progress.md`; task leads supply progress notes with their handoff. Once Compose exists, parallel runs need distinct `COMPOSE_PROJECT_NAME`, database volumes and host ports; if sharing a database server, use distinct database names as well. These runtime settings are planned and untested until scaffolding.

## Skills
Shared skill topics exist in both agent-specific directories. Paired SKILL.md paths and content must match (line endings are normalized when checked). A platform-specific exception requires an explicit reviewed change to the parity check, not merely a note in prose.

## Specialist reviewers
The `.claude/agents` definitions use an explicit Read/Grep/Glob allowlist. They provide source/screenshot review assistance to the lead. They cannot run tests or inspect a Git diff through shell commands; supply reviewable files and redacted execution evidence. They do not count as the other agent's independent review. Do not expand their tools to obtain execution evidence.

The policy checker applies the reviewer schema only to `code-reviewer.md`, `security-reviewer.md` and `ux-reviewer.md`. Each must have exactly `name`, `description`, `tools` and `model` as flat plain-scalar frontmatter: matching filename identity, a plain one-line description, Read/Grep/Glob and `model: inherit`. Duplicate/unknown fields, nested YAML, aliases, permission modes, hooks, MCP servers, skills and memory are rejected. Schema changes require review. Other agent definitions are outside this reviewer-only check and require their own task-appropriate review; this check is not a security guarantee for all future agents.
