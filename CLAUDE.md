# PitchPulse — Claude Code instructions

@AGENTS.md

The imported AGENTS.md is the canonical repository policy. Both Claude and Codex may be assigned implementation or review responsibilities. Never assume Claude is review-only.

- At the start of a task, identify whether your role is **IMPLEMENTER** or **REVIEWER**. If unspecified, ask only when it is necessary; otherwise infer from the request and state the assumption.
- For implementation, own the selected task end-to-end: code, relevant tests, documentation, visual checks where applicable. Do not commit or push unless explicitly asked.
- For independent review, do not modify files, run destructive commands, or quietly fix issues. Identify concrete findings with severity, file and line references, reproduction evidence, then optional suggestions.
- Do not work in a shared mutable tree while another agent writes to it. Use a separate git worktree and branch when concurrent implementation is requested.
- Follow `docs/design-system.md`; avoid ad-hoc visual tokens and screenshots-only functional validation.
- Read documentation relevant to the task; follow `.claude/skills` workflows when applicable. Specialist review subagents support the assigned lead; they do not replace independent review by the other agent. They have only Read, Grep and Glob tools; the lead supplies diff/test output and screenshots. Never claim they ran commands or browser checks.
- Don't install unknown MCP servers, grant broad permissions, expose secrets, use fake production data, or claim compliance without evidence.
