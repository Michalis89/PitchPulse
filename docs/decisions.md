# Architecture Decision Log — PitchPulse

Historical entries retain their original status. The current user-supplied AGENTS.md governs implementation where it supersedes a proposal. Add dated decisions with context, alternatives, decision and consequences; do not silently overwrite history.

## ADR-001 — Angular + Spring Boot modular monolith
- **Status:** Proposed
- **Context:** Rapid MVP, existing team familiarity, clean future growth.
- **Options:** Angular/Spring Boot monolith; Next.js/Node; microservices.
- **Decision:** Angular standalone frontend; Java 21/Spring Boot 3.x modular backend.
- **Consequences:** Single deployable API, simpler operations; Java and TypeScript builds both maintained.

## ADR-002 — PostgreSQL is our system of record
- **Status:** Proposed
- **Context:** Minimize external calls and own match history.
- **Decision:** Persist normalized fixtures/events/stats and source provenance in PostgreSQL; query our API for history.
- **Consequences:** Migrations, corrections, indexing and retention policies required. Storage/redistribution rights must be verified before using commercial feeds.

## ADR-003 — REST + SSE for live updates
- **Status:** Proposed
- **Context:** Clients primarily receive updates, not send them.
- **Decision:** REST snapshots plus SSE incremental updates with event IDs and reconnect handling.
- **Consequences:** Simpler than WebSockets; design fan-out and replay carefully.

## ADR-004 — Demo-first provider abstraction
- **Status:** Proposed
- **Context:** Live API prices, coverage and licenses are unverified.
- **Decision:** Mock/replay provider first; real providers through server-side adapters only.
- **Consequences:** MVP works without paid credentials; real-world data quality validated later.

## ADR-005 — Task-based code ownership and independent review
- **Status:** Accepted by product owner (2026-11-08; supersedes previous Codex-only implementation rule)
- **Context:** Both tools should support implementation and independent review without workspace conflicts.
- **Decision:** Codex or Claude can implement a task. Assign one lead implementer and the other independent reviewer per PR. Isolate concurrent changes using branches/worktrees.
- **Consequences:** Role is explicit for each task; stable diffs for review; owner approves merges.

## ADR-006 — Greek Super League only for MVP
- **Status:** Accepted by product owner
- **Context:** Limit scope and API costs.
- **Decision:** Only Super League active; other leagues displayed as coming soon.
- **Consequences:** Design extensible competition model but do not implement other league integrations.

## ADR-007 — Odds and YouTube automation staged
- **Status:** Proposed
- **Context:** Provider licensing, compliance and encoding infrastructure are uncertain.
- **Decision:** Model odds and design broadcast-ready view; defer paid odds feeds and automatic YouTube stream orchestration until approved.
- **Consequences:** Earlier functional match-center release; later integrations require validation.

## ADR-008 — Setup remediation and scope clarification (2026-11-08)
- **Status:** Independently reviewed by Claude and approved for commit with six non-blocking P3 findings; complete review saved at `docs/reviews/agentic-setup-rereview.md` (2026-11-08). Final cleanup is local and uncommitted; no commit/push/merge is authorized by this task.
- **Context:** The setup had missing ignore rules, a bypassable regex guard, shell-capable reviewers, incomplete CI and conflicting phase/viewports documentation.
- **Alternatives:** Attempt to parse arbitrary shell syntax; remove the guard and retain runtime permission boundaries. Duplicate platform skill copies without enforcement; enforce parity in CI.
- **Decision:** Remove the guard and disable example hooks; restrict specialist tools to Read/Grep/Glob; import canonical policy explicitly; add policy regression checks and checksum-pinned Gitleaks scanning. Use the design-system viewport matrix everywhere.
- **Consequences:** Review specialists need supplied test evidence. No hook claims comprehensive command security. No MCP/global configuration changes. CI and scanner pins need maintenance.
- **Scope clarification:** ADR-001/002/003 align with current AGENTS.md technology decisions; their runtime implementation remains unverified. ADR-004 means a minimal fictional demo simulator in Phase 1, with external-provider abstractions deferred to Phase 2. ADR-007's odds modeling and broadcast view are Phase 3 only; no such tables, modules or routes are required in Phase 1. Root `compose.yaml` is planned; `infra/` is optional.
- **Final cleanup:** N1 permits reviewed shared `.claude/settings.json` under a restricted deny/ask-only schema while retaining local/secret ignores; shared MCP configuration remains deliberately excluded. N2/N3 enforce a closed, duplicate-free frontmatter schema only for the three expected reviewer agents. N4 repairs saved-audit Markdown/escaping without changing its findings. N5 separates focus/warning colors and specifies team labels/patterns/markers. N6 records review completion, establishes LF text via `.gitattributes` and protects standard private-key filenames. No hooks or project settings are activated. These follow-up edits have local verification; no Claude re-review of them is claimed.
