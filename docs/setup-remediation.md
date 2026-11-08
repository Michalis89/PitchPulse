# Agentic setup remediation — 2026-11-08

Implementer: Codex. Scope: local agent configuration, policy checks and documentation. Completed independent Claude review and approval for commit with six non-blocking P3 findings are recorded in the saved second review (2026-11-08). Requested N1–N6 cleanup is local and uncommitted; no re-review of that cleanup is claimed. No application scaffold, MCP installation, paid service, global settings change, commit, push or merge.

## Audit availability
The audit was absent at first inspection and then appeared at `docs/reviews/agentic-setup-audit.md` during the task. It was read in full. At the owner's later request (N4), headings, wildcard corruption and JSON command escaping were repaired; all 17 original finding headings and their conclusions remain. The complete independent second review is saved at `docs/reviews/agentic-setup-rereview.md` and was read before finishing N1–N6. Its commit approval does not override the current no-commit instruction. Historical runtime claims are distinguished from implementer verification.

## Second-review cleanup
| ID | Status | Evidence and limits |
|---|---|---|
| N1 | Fixed | Shared `.claude/settings.json` is trackable and checked with a deny/ask-only schema, optional empty hooks and no grants/env/unknown fields. Local settings and secrets stay ignored/prohibited. `.mcp.json` remains deliberately excluded, documented in mcp-and-hooks.md. No active settings file or MCP server is created. |
| N2 | Fixed | `scripts/check_agentic_policy.py` validates exact reviewer name/description/tools/model fields and rejects duplicate/unknown fields, including permissionMode, mcpServers, hooks and disallowedTools. A closed plain-scalar YAML subset avoids silently accepting unsupported security fields. Regression tests exercise bypasses and malformed definitions. |
| N3 | Fixed | Reviewer restrictions apply only to EXPECTED_REVIEWERS. A regression fixture with a shell/edit-capable implementation helper passes; no such helper is added to this repository. Future agent types require their own review. |
| N4 | Fixed | Saved original audit has a formatting note, Markdown headings, restored `.env.*`/`*.log` and a valid escaped JSON command example. All 17 original finding headings are preserved; historical hook advice is not activated. |
| N5 | Fixed in design guidance | Focus is `#E5F0FF`, distinct from warning `#F4BE5A`. Visible team names/legends plus different solid/hatched, line and marker styles are specified. Proposed colors alone are not claimed to provide accessible team differentiation; actual UI verification is deferred. |
| N6 | Fixed for setup | ADR-008/progress record completed independent review and distinguish this local cleanup. `.gitattributes` sets LF text and preserves binary files. Standard SSH private-key names and `.ppk` files are ignored and prohibited from tracking; public `.pub` files outside `.ssh/` stay trackable. Tests cover attributes, ignores and key paths. |

| ID | Status | Current evidence and disposition |
|---|---|---|
| H1 | Independent review approved; publication pending | `git ls-files` still lists only README.md. `docs/agent-workflow.md` warns that new worktrees lack untracked policy; a frozen local review including untracked files is supported. Claude's approval for commit is recorded, but the current task explicitly prohibits commit/push/merge; GitHub CI execution remains undone. |
| H2 | Fixed | Root `.gitignore` covers local environments/settings, credentials, build/test output and worktrees. Regression tests confirm ignored paths and preserved placeholder examples, skills, lockfiles and Maven wrapper. Ignore rules do not erase tracked secrets. |
| H3 | Safely disabled | The guard script is absent and `.claude/settings.example.json` has `hooks: {}`. Policy checks reject restoring that script or enabling example hooks. Interpreter/path/matcher/pattern repairs and executable hook tests no longer apply to the retired guard. Existing user-level hooks remain outside scope. |
| M1 | Fixed in repository; Claude runtime unverified | CLAUDE.md imports `@AGENTS.md`; shared functional-validation and MCP permission rules are in AGENTS.md. The audit's absolute automatic-loading claim is version-dependent; explicit import avoids that dependency. |
| M2 | Fixed | AGENTS.md hands off to the other assigned agent. CLAUDE.md and the specialist descriptions/bodies distinguish specialist support from independent cross-agent review. |
| M3 | Fixed in definitions; runtime unverified | All three `.claude/agents` definitions allow only Read/Grep/Glob; no Bash, PowerShell, write or MCP tools are listed. Lead-supplied execution evidence is required. |
| M4 | Fixed | `docs/design-system.md` owns the viewport matrix: 390x844, 768x1024, 1440x900; 1920x1080 broadcast is Phase 3. Both visual skills, testing docs, UX reviewer and PR template reference it; tablet is included. |
| M5 | Documentation/token fixes complete; app enforcement deferred | Home color differs from interactive accent. Dedicated control/focus colors exceed 3:1 against all proposed surfaces; decorative border usage is restricted. `client/src/styles/tokens.css`, Tailwind mapping, Stylelint and axe are explicitly planned for scaffolding. No app files or rendered accessibility checks exist, by user instruction. |
| M6 | Fixed; discovery evidence limited to this session | CI/local checks enforce all seven SKILL.md inventories and normalized text parity; regression tests detect missing copies and drift. All seven repository skills are exposed in this Codex session and release-validation was applied. Claude runtime discovery was not re-tested. |
| M7 | Fixed for setup; app gates deferred | Workflow runs policy tests and redacted Gitleaks directory/history scans; checkout is SHA-pinned and scanner archive checksum-pinned. Documentation distinguishes current checks from future app/migration gates. GitHub execution remains unverified under H1. |
| L1 | Fixed | AGENTS.md includes agent/configuration/docs paths and marks future paths as planned. Architecture uses root `compose.yaml`; `infra/` is optional. |
| L2 | Fixed | README and setup guide describe current setup, not ZIP installation or unverified remote state. Unsupported multi-match claims and stale reconciliation instructions were removed. |
| L3 | Fixed | AGENTS.md defines P0/Critical, P1/High, P2/Medium and P3/Low; unverified suggestions are separate. |
| L4 | Preventive documentation complete; runtime unverified | Task brief/PR template record ownership; only integrating lead updates shared progress. Mirrored feature skills follow that rule. Future parallel Compose runs require distinct projects/volumes/ports and separate database names when sharing a server. No observed collision or Compose runtime exists to reproduce. |
| L5 | Limitation documented | Read denial is inactive and tool-specific; it is not shell/MCP protection. README-SETUP.md and mcp-and-hooks.md state this explicitly, including blocked `.env.example` reads. No replacement security claim or regex guard was added. |
| L6 | Fixed | AGENTS.md narrows untrusted inputs to third-party/MCP/external content and retains canonical policy. Required-file checks include progress/workflow docs and all skill pairs. |
| L7 | Unverified suggestion; no relocation warranted | Python/Git/Gitleaks/Actionlint checks run from the Unicode path. Maven, Testcontainers and Chromium remain untested until app scaffolding. Do not move the repository speculatively. |

## Verified issues addressed
| Priority | Evidence before remediation | Resolution |
|---|---|---|
| High | No root ignore policy for local credentials, environments or outputs | Root `.gitignore`, tracked sensitive-path checks and redacted Gitleaks content/history scans |
| High | Regex Bash guard failed open on invalid JSON and could not parse general shell commands | Removed script and registration; example hooks explicitly empty |
| Medium | All three read-only reviewer definitions allowed Bash | Explicit Read/Grep/Glob allowlist; lead supplies execution evidence |
| Medium | CLAUDE.md mentioned AGENTS.md in prose without importing it | Standalone `@AGENTS.md` import |
| Medium | CI checked only existence and common env filenames | Policy/skill parity checks, failure-case tests and checksum-pinned CLI scanner |
| Medium | Design foundations and screenshot viewports disagreed | One viewport matrix referenced by docs, mirrored visual-testing skills and UX reviewer |
| Medium | Phase 1 architecture included future players/standings/ingestion and ADR-007 suggested early odds modeling | Explicit phase boundaries and superseding ADR-008 |
| Low | Fixed Claude handoff conflicted with rotating implementer ownership | Handoff targets the other assigned agent; specialist assistance does not replace independent review |
| Low | README described future features without setup status; setup guide asserted remote state and ZIP installation | Document current checkout, validation and deferred app startup; remove unsupported remote claim |

## Remaining risks and unverified suggestions
- The second review reports no stale user-level hook registration and confirms Claude skill discovery. It could not verify runtime imports because nested sessions were blocked, and its session retained previously loaded Bash-capable reviewer definitions. Restart Claude and check imports/effective tools. No Claude session was launched by this implementer; static checks do not prove runtime enforcement.
- The example Read denials are limited, inactive, and also cover `.env.example`; they do not secure Bash, MCP or other tools. Actual credentials must remain outside agent review contexts. No active permissions were changed.
- Ignore rules do not protect already-tracked content or force-add operations. Secret scanners have false positives and false negatives; no comprehensive command security or absence-of-secrets guarantee is claimed.
- GitHub-hosted CI execution and branch protection are unverified; required-check configuration remains owner-controlled. Pull-request CI runs untrusted repository code with read-only contents permission and no persisted checkout credentials; do not add repository secrets or use `pull_request_target` to execute PR code.
- Scanner/action pins are reproducible reviewed inputs, not a vulnerability audit. Download availability and runner images remain external dependencies. Review version/checksum updates together.
- External API licenses, rendered accessibility, browser behavior, SSE replay bounds and application quality gates are future implementation work. Token contrast calculations do not establish browser accessibility. No paid integration or legal assumption was adopted.

## Review handoff
All setup files except the original README were untracked at intake. Ordinary `git diff` alone therefore omits most work; inspect untracked files too. Base/local HEAD: `18c010ae87dd4d2581971f5a5b225435b8314a8f`, branch `develop`; no remediation commit exists. Review the supplied audit, this document, `docs/progress.md`, the policy script/tests, workflow, instruction import, reviewer definitions and ignore rules together. Independent Claude review was completed per the owner's report; the final cleanup remains available for read-only re-review. The current task explicitly prohibits commits.

Actual commands and results are recorded in `docs/progress.md`.
