# MCP and hooks — least privilege setup

## Concepts
- **Hooks:** deterministic local triggers at tool/session lifecycle events; e.g. reject dangerous shell operations before running them or enforce formatting. They run with local machine permissions, so review every script and avoid untrusted commands.
- **MCP (Model Context Protocol):** protocol exposing external tools/data to an agent. E.g. GitHub repository operations, local browser automation, PostgreSQL introspection. An MCP server is NOT inherently safe or free; inspect the source, tool permissions and auth scopes.
- **Skills:** instructions teaching the agent when and how to follow a workflow; they do not create new permissions.

## Recommended for PitchPulse
1. **Playwright CLI/test runner** through the repository first — no MCP required to test a browser. Optionally add an official Playwright browser MCP in a trusted local environment for interactive inspection.
2. **GitHub** connector or `gh` CLI for PR/issues, using repository-scoped least-privilege access. Read-only first; write access only when explicitly necessary.
3. **PostgreSQL**: prefer normal integration tests and read-only local psql for inspection. Don't expose production write credentials to agents.
4. **Documentation MCP** only when a task needs a current external API and the server is trusted; avoid unrelated MCP servers by default.

## Important boundaries
- No third-party community MCP servers blindly installed with `npx`.
- Do not put tokens/passwords in `.mcp.json`, `AGENTS.md`, CI configs or commits.
- Claude project-level MCP may be stored in `.mcp.json`; Codex CLI/IDE MCP has separate user settings. Auth flows and capabilities differ by tool/version.
- This repository deliberately ignores and prohibits tracking `.mcp.json` and `.mcp.local.json` for now. Shared MCP configuration is not approved or implemented in this setup; any later exception needs a separate reviewed policy change. Allowing safe shared Claude settings does not authorize MCP server installation or activation.
- Start MCP integrations read-only. Network tools can send repo/source content externally; review privacy implications.
- The former `.claude/hooks/safe-shell-guard.py` and its example registration were removed. It failed open on malformed input and regex matching could miss shell syntax, alternate commands, interpreters and PowerShell. It provided no complete command security.
- `.claude/settings.example.json` is inactive and has an empty `hooks` object. Do not copy the old hook registration into active settings. Existing machine/user settings are outside this remediation; inspect them manually for stale registrations. No global settings were changed.
- `.claude/settings.json` is an optional, trackable shared project file. The policy checker permits only empty hooks and deny/ask permission lists; unsupported fields, tool grants, environment settings and permission-mode overrides fail validation. No shared active settings file is created here. `.claude/settings.local.json` and its variants remain ignored and prohibited from tracking; secrets must never be placed in shared settings. Review changes before opening a trusted agent session, since post-push CI is not a runtime sandbox.
- Standard SSH private-key filenames (`id_rsa`, `id_dsa`, `id_ecdsa`, `id_ed25519` and security-key variants) and PuTTY `.ppk` files are ignored and prohibited from tracking even outside `.ssh/`. Public `.pub` files outside `.ssh/` remain trackable. Filename rules are limited; Gitleaks also scans file contents and neither control guarantees detection of all secrets.
- Use runtime permissions, isolated environments, explicit authorization and reviewed CI as separate controls. Instruction files, tool allowlists, ignore rules and secret scans are limited safeguards, not a security sandbox.
- Reviewer definitions allow only Read, Grep and Glob. They cannot run shell/tests/browser tools or MCP tools; the lead supplies redacted output and screenshots. Read access can still expose files allowed by the host, so keep real credentials out of the review workspace.

## Manual verification
- Claude Code: inspect `/mcp`, `/hooks`, `/agents` and available skills after restarting the session.
- Codex: `codex mcp list` in an environment with Codex CLI; verify skills through actual task invocation.
- Keep sensitive approvals human-driven; do not run in unrestricted YOLO/dangerously-skip-permissions mode.

## Secret scanning
CI downloads the standalone [Gitleaks v8.24.3 CLI](https://github.com/gitleaks/gitleaks/releases/tag/v8.24.3), verifies a repository-pinned SHA-256, and scans checkout contents plus all fetched Git history with redacted output. No Gitleaks action license, paid service or API secret is required. The version is a reproducible pin, not a claim that it is the latest or free of vulnerabilities; review updates periodically.

With a separately verified local Gitleaks binary, run from the repository root:

```powershell
gitleaks dir . --redact --no-banner --ignore-gitleaks-allow
gitleaks git . --log-opts=--all --redact --no-banner --ignore-gitleaks-allow
```

Directory scanning includes untracked setup changes; history scanning cannot inspect commits absent from the local clone. CI fetches full available history. There are no project-wide scan exclusions or baselines. Do not silence findings without reviewing and documenting false positives. Scans do not guarantee the absence of secrets, and `.gitignore` does not untrack existing files or erase history.

Configuration references: [Claude instruction imports](https://code.claude.com/docs/en/memory#import-additional-files), [subagent tool restrictions](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use), and [Gitleaks commands](https://github.com/gitleaks/gitleaks#usage). The installed agent runtime must still be verified locally.
