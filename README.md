# PitchPulse

Runnable foundation for a future Greek Super League match centre. This slice provides an Angular shell, a Spring Boot readiness API, PostgreSQL and Flyway. It does not yet implement demo fixtures, match events, SSE, football ingestion, odds or broadcasting.

## Prerequisites

- Java **21** JDK (`JAVA_HOME` points to it); Maven is downloaded by the wrapper.
- Node **24 LTS** recommended, with npm. Angular 21 also supports Node 20.19+ or 22.12+ within those major versions.
- On Bash, `curl` or `wget` plus `unzip` (the wrapper checksum pins the ZIP distribution).
- Running Docker Desktop/Docker Engine with Compose v2. First runs need internet access for public dependencies/images; no paid credentials are required.

## Local startup

From the repository root, copy `.env.example` to the ignored `.env` and replace `DB_PASSWORD` with an unquoted alphanumeric local-only password. Compose reads `.env`; Spring Boot **does not** load this file automatically.

Recommended, in Bash (Git Bash on Windows), after creating and editing `.env`:

```bash
bash ./dev.sh
# When finished:
bash ./stop-dev.sh
```

`dev.sh` builds the backend, installs frontend dependencies when absent, and starts PostgreSQL, the API and Angular. It returns after checking readiness; `bash ./dev.sh --follow` follows logs and stops the environment on Ctrl+C. `stop-dev.sh` stops the recorded application processes and Compose services while preserving the database volume; `--keep-db` leaves PostgreSQL running. Logs and process records stay in ignored `logs/dev/` and `tmp/dev/`. The scripts require `curl`; use Git Bash on Windows. If Java 21 is not discovered, set `PITCHPULSE_JAVA_HOME` to its JDK directory for this process before starting. No global settings are changed.

Alternatively, start services manually using the following terminals. Do not run these alongside `dev.sh` on the same ports.

PowerShell, first terminal:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
# Edit .env before continuing.
docker compose up --detach --wait
$env:DB_PASSWORD = (Get-Content .env | Where-Object { $_ -match '^DB_PASSWORD=' }) -replace '^DB_PASSWORD=', ''
Set-Location server
.\mvnw.cmd spring-boot:run
```

Bash, first terminal:

```bash
cp -n .env.example .env
# Edit .env before continuing.
docker compose up --detach --wait
export DB_PASSWORD="$(sed -n 's/^DB_PASSWORD=//p' .env)"
cd server
bash ./mvnw spring-boot:run
```

Second terminal, from the repository root:

```powershell
cd client
npm ci
npm start
```

Open **http://127.0.0.1:4200**. The page checks the real backend through the Angular dev proxy and shows loading, connected or retry states. Direct API: **http://127.0.0.1:8080/api/v1/health**.

The interface defaults to **Ελληνικά (el-GR)**. Use the labelled header language selector (**Ελληνικά / English**) to switch at runtime; the preference survives reloads when localStorage is available. Missing English text falls back to Greek. Display dates/times use **Europe/Athens** in either language, while formatting follows the selected locale. No extra startup command or language build is needed.

Expected response when ready:

```json
{"status":"UP","service":"pitchpulse","database":"UP"}
```

Health checks PostgreSQL with a bounded query. It returns HTTP 503 with DOWN values if the running application loses database connectivity, without leaking connection details. Startup fails if credentials/database/migrations are unavailable; there is then no listening endpoint.

Keep default database name/user/port for the commands above. To customize them, set `DB_NAME`, `DB_USERNAME`, `DB_PORT` in `.env` for Compose and matching `DB_USERNAME` and `DB_URL` (for example `jdbc:postgresql://localhost:5433/pitchpulse`) in the backend terminal. Backend `SERVER_ADDRESS` defaults to loopback and `SERVER_PORT` to 8080. `CORS_ALLOWED_ORIGINS` is a comma-separated explicit allowlist, default `http://localhost:4200`; credentials/wildcards are disabled. The frontend proxy target is `client/proxy.conf.json` and must match any changed backend port.

The generated `pitchpulse` schema and Flyway history persist in the named Docker volume. Flyway's history schema is explicitly pinned to `public` in application configuration, so fresh startup and subsequent restarts use `public.flyway_schema_history`. No `SPRING_FLYWAY_DEFAULT_SCHEMA` environment variable or command-line workaround is required. Apply future schema changes as new migrations and qualify application objects with `pitchpulse`; never edit an already-applied migration. Do not delete the volume to fix migration failures without reviewing the data impact. See ADR-011 in `docs/decisions.md` for the resolved restart failure.

## Checks

```powershell
cd server
.\mvnw.cmd --batch-mode --no-transfer-progress verify
cd ../client
npm ci
npm run lint
npm test
npm run build
npx playwright install chromium
npm run e2e
```

On Bash use `bash ./mvnw` instead of `.\mvnw.cmd`. `verify` includes MVC unit tests and mandatory PostgreSQL/Testcontainers integration tests (Docker required). `test` alone runs MVC tests, not database integration. Browser tests require the API and Compose database already running; Playwright starts/stops its own Angular dev server on port 4200. Stop any existing Angular server first. If using `dev.sh`, run `bash ./stop-dev.sh --keep-db`, then start only the API with the manual instructions above before running browser tests. Tests verify real connectivity, loading/failure/retry, keyboard flow, overflow and axe at 390x844, 768x1024 and 1440x900. Screenshots are saved under ignored `client/test-results/` as review evidence, not approved baselines.

CI runs these builds and tests on Ubuntu, Java 21 and Node 24 in `.github/workflows/foundation.yml`, alongside existing policy/secret checks. GitHub-hosted execution has not yet been verified locally.

`npm audit --omit=dev` currently reports zero runtime dependency findings. A full audit reports 16 moderate development-tool findings in the Angular CLI dependency chain; see ADR-009 in `docs/decisions.md`. They are not suppressed or fixed through forced downgrades.

For manually started services, stop the client/API with Ctrl+C and run `docker compose stop` from the root when done. For script startup, use `bash ./stop-dev.sh`. Both preserve database data. Production hosting is deferred: the built static client needs a same-origin `/api` reverse proxy; Angular's dev server is local tooling.

Repository setup checks remain `python scripts/check_agentic_policy.py` and `python -B -m unittest discover -s scripts/tests -v`. See [AGENTS.md](AGENTS.md), [architecture](docs/architecture.md), [API contract](docs/openapi.yaml), [progress and verification](docs/progress.md), and [agent setup](README-SETUP.md).
