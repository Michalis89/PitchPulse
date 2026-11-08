# Architecture — PitchPulse

Status: Target architecture governed by AGENTS.md; no application is implemented yet. Runtime behavior remains to be validated in Phase 1.

## Product boundary
Public Greek Super League match center. Other leagues are shown as coming soon. Demo/replay mode is the only required source for Phase 1. Never present synthetic data as live.

## Monorepo
- `client`: Angular standalone application, lazy routes, signals, Tailwind, ECharts and PixiJS pitch rendering.
- `server`: Java 21, Spring Boot 3.x modular monolith, REST, SSE, Flyway and PostgreSQL.
- Root `compose.yaml`: future local dependencies; `infra/` only when supporting operational assets are needed.
- `docs`: architecture, decisions, progress, contracts and provider licensing notes.

## Backend modules
Phase 1: minimal `catalog` (competitions, teams) and `matches` (fixtures, events, statistics), plus a development demo simulator. Add no empty future modules or generic external-provider framework.

Phase 2: players, standings and external-provider ingestion/mapping as needed. Phase 3: odds and broadcast view.

## Data flow
Phase 1: demo simulator -> validation -> idempotent PostgreSQL persistence -> REST snapshot and SSE event publication -> Angular match center. Publish only persisted events. Specify replay bounds and expired-window recovery in the Phase 1 contract before frontend integration; these are not implemented yet.

Later phases add provider adapters and a broadcast view behind the same backend read model.

All client requests use our API. Historical queries read PostgreSQL, subject to retention and redistribution rights. External IDs are mapped to canonical internal IDs.

## Realtime contract
REST delivers the current match snapshot and ordered events; SSE sends incremental event IDs and supports reconnect/deduplication. Corrections and VAR reversals must update prior state deterministically. UTC timestamps stored; Europe/Athens display default.

## Visualization truthfulness
Pitch graphics animate only supported event coordinates; any interpolation is illustrative. Do not simulate full tracking as factual. Synthetic fixtures, statistics and odds are labeled.

## Operational defaults
Local Docker Compose, `.env.example`, no credentials needed for demo. No Redis/Kafka/microservices for MVP. Add metrics, bounded retries, logging, basic rate limiting, migrations, and automated tests.

## Security and legal gates
Provider credentials server-side only. Public APIs read-only. Data retention, public display, odds, logos and YouTube rebroadcast rights require verification before live-provider integration.

## Phase 1 acceptance
One seeded match persisted in PostgreSQL, API and SSE simulator, Angular fixtures and match center, animated pitch, tests, CI and documented local startup. YouTube automation and licensed data ingestion are later phases.
