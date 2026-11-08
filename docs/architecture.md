# Architecture — PitchPulse

Status: Runnable foundation implemented: Angular shell, Spring Boot readiness API, PostgreSQL and Flyway. The full Phase 1 demo match centre below remains a target, not implemented behavior.

## Product boundary
Foundation: one page identifying Greek Super League and showing backend/database connectivity. No football facts, demo fixtures, live feeds, match routes or other leagues are implemented. Full Phase 1 will be a public Greek Super League demo match centre. Never present synthetic data as live.

## Monorepo
- `client`: Angular 21 standalone application, strict templates/TypeScript, lazy home route, signals, Tailwind 4 and centralized CSS tokens. Charts and pitch rendering are deferred.
- `server`: Java 21, Spring Boot 3.5.16, MVC, JDBC, Flyway and PostgreSQL. SSE and football modules are deferred.
- Root `compose.yaml`: PostgreSQL 17.10 with loopback-only host port, required local password, persistent named volume and healthcheck. `infra/` only when operational assets are needed.
- `docs`: architecture, decisions, progress, contracts and provider licensing notes.

## Runtime internationalization
Angular uses stable `@jsverse/transloco` and `@jsverse/transloco-locale` 8.4.0 with one build, not separate compile-time language builds. Greek (`el-GR`) is the application default regardless of browser language; English (`en-US`) is available immediately. Backend DTOs, status enums, paths and technical identifiers remain unchanged and language-neutral.

Translation dictionaries are separate structured JSON files at `client/public/i18n/el-GR.json` and `en-US.json`. Namespaces cover `brand`, `metadata`, `navigation`, `language`, `home`, `connectivity` and `empty`. `i18n.providers.ts` supplies the loader/configuration; Greek is imported into the bundle from that same JSON source and English is loaded over same-origin `i18n/en-US.json` HTTP with a four-second timeout and no retries. Angular copies the public dictionaries into the production assets. Translation changes require rebuilding/deploying matching code/assets; no remote translation service is used.

`app.config.ts` awaits `LocalizationService.initialize()` before rendering: cache bundled Greek, read the allowlisted `pitchpulse.language` localStorage value, load the selected language, then update Transloco, `<html lang>`, page title and description. Only `el-GR`/`en-US` are accepted; absent/unsupported preferences choose Greek. Accepted selections are stored and restored on reload. Storage read/write failures are caught: switching still works for the session, but persistence cannot be guaranteed when storage is blocked. The most recent request wins if loads overlap. `LanguageSwitcher` keeps native keyboard focus and indicates a pending load with `aria-busy`.

Transloco has `fallbackLang: el-GR`, `useFallbackTranslation: true` and `allowEmpty: false`. Missing/empty English entries resolve to bundled Greek while the selected locale stays English. If the entire English asset fails, selection, metadata, formatting and stored preference return to Greek, with a translated alert. Greek needs no network request. A key absent in both dictionaries has no recoverable translation; Transloco exposes the key and warns in development. Catalog tests require matching, nonempty key sets; feature review must verify newly referenced keys are present.

Transloco Locale maps the active full language tag to the same locale, using browser `Intl` formatting. The configured `translocoDate` pipe defaults to `Europe/Athens`, with localized calendar date, hour/minute and timezone name; language choice never changes that timezone. The UI displays the actual completed connectivity-check timestamp in `<time datetime="ISO-UTC">`. Numeric values should use `translocoDecimal`/other locale pipes, not manually inserted separators; number formatting is covered by a test-only host and no synthetic numeric metrics were added to the UI. Angular's static `LOCALE_ID` and bare `DatePipe`/`DecimalPipe` are not used for runtime localization. Programmatic date formatting must explicitly pass the shared `DATE_FORMAT` (including timezone); raw locale-service methods do not inherit the pipe defaults in this plugin version.

## Backend modules
Current: `health` and `config` only. `GET /api/v1/health` executes bounded `SELECT 1`, returns 200/UP or 503/DOWN with no connection details, and disables response caching. Initial Flyway migration creates only the `pitchpulse` schema; no business tables or synthetic data are seeded. Startup requires PostgreSQL and successful migrations. A failed startup exposes no health endpoint; readiness can report 503 after a running application's database becomes unavailable.

Flyway explicitly uses `spring.flyway.default-schema: public` in `server/src/main/resources/application.yml`, keeping its authoritative history at `public.flyway_schema_history` for both initialization and restarts. With the Compose username `pitchpulse`, PostgreSQL's default `"$user", public` search path starts resolving `pitchpulse` after V1 creates that schema. Relying on the implicit connection schema would therefore move Flyway's history lookup on subsequent connections. The configuration fixes that lookup without changing V1, moving history, altering role/database search paths or resetting data. Future application migrations must qualify objects as `pitchpulse.<name>` rather than assume Flyway's default schema is the application namespace. The existing empty `pitchpulse.flyway_schema_history` left by failed starts is not used or removed. `dev.sh` packages/starts the configured JAR and `stop-dev.sh` stops services while preserving the volume; neither needs a Flyway override or source change.

The browser requests relative `/api/v1/health`. Angular's local dev proxy forwards `/api/**` to `127.0.0.1:8080`; production hosting will need an equivalent same-origin reverse proxy and is not supplied here. Optional direct browser access is restricted to the configured CORS origin allowlist (default `http://localhost:4200`, GET only, no credentials). Client timeouts and retry/loading/error states are implemented. API is loopback-bound by default.

Future Phase 1: minimal `catalog` (competitions, teams) and `matches` (fixtures, events, statistics), plus a development demo simulator. Add no empty future modules or generic external-provider framework.

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
