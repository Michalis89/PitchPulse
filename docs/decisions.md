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

## ADR-009 — Runnable foundation before the demo match centre (2026-11-08)
- **Status:** Implemented on `feature/phase1-foundation`; owner authorized final validation, commit and push. Setup commit `fdef4538bba72b97fb18288c49a75454e928a61d` was fast-forwarded into local `develop`. The full demo match centre remains future work.
- **Context:** Establish reproducible builds, persistence startup and browser/backend connectivity before domain features. The request intentionally narrows the full Phase 1 vertical slice.
- **Decision:** Angular 21 LTS standalone/strict with Tailwind 4 and Vitest; Java 21/Spring Boot 3.5 with JDBC and a database-backed readiness endpoint. Use the official checksum-pinned Maven wrapper and npm lockfile. PostgreSQL 17.10 is provided by Compose locally and Testcontainers for backend integration tests. No JPA/entities, dummy health table, fixtures, event simulator or SSE yet.
- **Alternatives:** An HTTP-only ping would not verify persistence connectivity; an artificial domain table would expand the scope. V1 creates only the application schema; future migrations add real domain structures. No rollback drops are provided; forward-fix with new migrations after V1 is applied.
- **Consequences:** Startup requires PostgreSQL and a password supplied through environment variables. Angular uses relative URLs with a development proxy; production reverse-proxy/deployment assets are deferred. Node 24 LTS is recommended and used in CI; the installed Node 20.19 also satisfies Angular 21's documented compatibility range. No global tool settings are changed.
- **Known dependency risk:** At validation time `npm audit` reports 16 moderate development-only findings, rooted in CLI transitive glob/minimatch dependencies. `npm audit --omit=dev` reports zero. Same-major upstream fixes are not available; forced npm remediation proposes an incompatible CLI downgrade, while overriding transitive major versions would require additional compatibility validation. No forced downgrade/override or advisory suppression is applied. Recheck supported upstream releases before public release. No claim of a complete dependency security audit is made.

## ADR-010 — Greek-first runtime internationalization (2026-11-08)
- **Status:** Implemented on `feature/phase1-foundation`, included in the owner's authorization to validate, commit and push the completed foundation.
- **Context:** Greek is the primary audience, while English must be available from the MVP. Language changes must survive reloads and must not change the football display timezone or backend contracts.
- **Alternatives:** Compile-time Angular localization would create separate language builds/routes; a translation service would add an external dependency. Runtime Transloco allows one build with an immediate in-page switch.
- **Decision:** Use stable Transloco/Transloco Locale 8.4.0, full `el-GR`/`en-US` IDs and structured local JSON catalogs. Bundle Greek as the deterministic fallback; fetch English as a same-origin asset. Initialize from an allowlisted localStorage preference, default to Greek without browser-language detection, and localize page metadata and document language. Use locale pipes for formatting with Europe/Athens independent of language.
- **Consequences:** Missing/empty English keys show Greek; an English asset failure returns the whole selection to Greek. Blocked storage degrades to session-only switching. Last-request ordering and focus retention prevent stale loads from undoing a choice. Both catalogs must remain complete; no invented translation can recover a key absent in Greek too. No backend identifiers/contracts, football features, account settings, remote translation service or new deployment architecture are introduced.
- **Validation boundary:** Unit/browser tests cover real runtime switching and formatter configuration. Future UI features must add catalog entries and use the shared locale rules; generic plural-heavy domain copy is not implemented or claimed by this foundation.

## ADR-011 — Stable Flyway history schema across restarts (2026-11-08)
- **Status:** Implemented and locally verified for fresh initialization and retained-volume restarts; included in the owner-authorized foundation publication.
- **Context:** Compose creates a PostgreSQL login/database named `pitchpulse`. PostgreSQL defaults to `"$user", public`; before V1 the effective schema is public, but after V1 creates `pitchpulse`, subsequent connections resolve that schema first. Flyway had no explicit default schema, so it missed its successful public V1 history and attempted initialization in a different schema. An empty application schema produced the reported duplicate-schema failure; a populated application schema instead causes the nonempty-schema/no-history safety check to fail.
- **Decision:** Set `spring.flyway.default-schema: public` in checked-in application configuration. Preserve the authoritative `public.flyway_schema_history`, V1 checksum, existing namespace and all volume data. Leave the empty shadow history table untouched. No automatic baseline, repair, history relocation, role search-path changes or volume/database resets.
- **Alternatives:** Making the already-applied V1 idempotent would change its checksum and conceal the missing-history cause. Moving history or changing database/role defaults would add unnecessary state changes. A shell-only override would leave other startup paths broken.
- **Consequences:** Fresh and existing database starts use the same history through normal Maven/JAR/dev-script startup. Future application DDL must explicitly name the `pitchpulse` schema. Existing deployments with a different authoritative history location require inspection rather than blind history migration. A PostgreSQL Testcontainers regression uses the production username, closes one full application context, starts a new one on the same database, and verifies history, API readiness and persisted probe data. Applied V1 is unchanged; future schema evolution remains additive.
