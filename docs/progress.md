# Progress

## Current status
The reviewed agent setup is committed as `fdef4538bba72b97fb18288c49a75454e928a61d` and was fast-forward merged into local `develop` under explicit owner instruction. Foundation work on `feature/phase1-foundation` is complete and the owner has authorized final validation, commit and push of this branch only, without a merge or PR. Angular, Spring Boot, PostgreSQL/Flyway, readiness connectivity and foundation tests run locally. The full Phase 1 demo match centre is not implemented. No external football/odds/broadcast integration, MCP installation or global configuration changes were added. Historical logs below retain their state at execution time, including earlier uncommitted and review-pending descriptions.

Greek-first runtime i18n is implemented on the foundation branch: el-GR/en-US, accessible switcher, persisted preference, Greek fallback and Athens-time formatting. The database restart issue discovered during i18n verification is fixed with an explicit Flyway history schema; fresh and preserved-volume restart verification is recorded below. The current publication task adds no independent review assertion.

## Phase 1 plan
- [x] Reconcile setup policy/docs and add local/CI checks (Codex implementer; independent Claude review completed, N1–N6 cleanup applied locally).
- [x] Assign Codex as lead for the limited foundation task.
- [x] Scaffold `client/` and `server/` with lockfile/Maven wrapper and Docker Compose; foundation health API contract defined.
- [ ] Define demo fixture DB schema and match contracts (foundation creates only an application namespace).
- [ ] Implement REST + SSE and tests.
- [ ] Implement Angular match center and illustrative pitch.
- [ ] Add app CI, E2E tests and screenshot baselines (setup CI already defined, not run on GitHub).
- [ ] Handoff future Phase 1 application diff to second agent for review (setup review already completed).

## Verification log
### 2026-11-08 — Foundation publication validation
Owner authorized staging, committing and pushing `feature/phase1-foundation` only; no merge, force-push or PR. Inspected tracked changes and all nonignored new files, including source/configuration/tests, package-lock registry URLs, Maven wrapper pins and Claude's dev scripts. README now documents actual script startup/shutdown, process-local JDK selection and Playwright's exclusive frontend port. ADR status text reflects this publication task; earlier task logs remain historical.

| Command/check | Result |
|---|---|
| `server/mvnw.cmd --batch-mode --no-transfer-progress verify` from `server/` with Java 21 | PASS: executable JAR; 3 MVC tests and 2 PostgreSQL integration tests, zero failures/errors/skips, including fresh Flyway initialization and restart |
| `npm ci`, `npm run lint`, `npm test`, `npm run build` from `client/` | PASS: reproducible install, CSS lint, 14 unit tests and production build (280.65 kB initial raw bundle) |
| `npm run e2e` from `client/`, real packaged API and retained Compose database | PASS: all 21 Playwright checks at mobile/tablet/desktop, 19.0 seconds; connectivity, Greek/English switching, persistence, fallback, dates, keyboard flow, overflow and axe |
| `npm audit --omit=dev` | PASS: zero runtime findings |
| `npm audit --json` | FAIL (exit 1): 16 moderate development-tool findings, zero high/critical. Existing ADR-009 risk retained; no suppression, forced downgrade or incompatible override. Initial local report parsing used UTF-8 for PowerShell's UTF-16 output; reading with UTF-16 confirmed these counts |
| `python scripts/check_agentic_policy.py` and `python -B -m unittest discover -s scripts/tests -v` | PASS: policy/skill parity and all 11 regression tests |
| Actionlint 1.7.7; `bash -n dev.sh stop-dev.sh scripts/dev-lib.sh`; `git diff --check` | PASS |
| Gitleaks 8.24.3 `dir <nonignored-source-snapshot> --redact --no-banner --ignore-gitleaks-allow` | PASS: 90 source files, no leaks found |
| `PITCHPULSE_JAVA_HOME=<JDK-21> bash ./dev.sh`, then `bash ./stop-dev.sh` | PASS: all services ready, API and frontend proxy UP; stopped recorded processes and Compose without removing data volumes |
| Git ignore assertions and SHA-256 baseline comparisons | PASS: local credentials, review reports, dependency/build output, logs and state ignored; `.env.example` trackable; applied V1 and all three Claude scripts unchanged |

Local validation used Windows, Java 21.0.13 and Node 20.19.0. Hosted Ubuntu/Node 24 CI remains unverified; workflows trigger on PRs, pushes to develop/main, or manual dispatch, so this feature-branch push alone does not execute them. Manual assistive-technology testing and production hosting remain outside this task. No football features were added.

The first staged `git diff --cached --check` caught a trailing space in the upstream Maven wrapper NOTICE, which was removed without changing its wording. The rerun passed. Exact-index validation then confirmed all 90 project files use LF, contain no sensitive/local/generated paths, and leave no omitted nonignored changes; policy and Gitleaks passed against the staged content. The final commit and remote hash are reported by the publication task rather than embedded recursively here.

### 2026-11-08 — setup remediation
Environment: Windows PowerShell, Python 3.13.0, Unicode repository path. Local HEAD/base `18c010ae87dd4d2581971f5a5b225435b8314a8f`, branch `develop`. Only README.md was tracked at intake; setup changes remain untracked. `git diff` does not include those files.

| Command/check | Actual result |
|---|---|
| `python scripts/check_agentic_policy.py` | PASS: required docs, import, all seven skill pairs, reviewer allowlists, disabled hooks, tracked-path policy |
| `python -m unittest discover -s scripts/tests -v` | PASS: 7 tests, including missing/drifting skills, shell-enabled reviewer, import/hooks failures, sensitive tracked paths and ignore rules preserving wrappers/lockfiles/examples |
| `& "$env:TEMP/pitchpulse-remediation-tools/actionlint/actionlint.exe" .github/workflows/agentic-policy.yml` | PASS, exit 0, Actionlint 1.7.7; official Windows archive SHA-256 verified before extraction |
| `& "$env:TEMP/pitchpulse-remediation-tools/gitleaks.exe" dir . --redact --no-banner --ignore-gitleaks-allow` | PASS, exit 0, no leaks found; includes untracked setup files |
| `& "$env:TEMP/pitchpulse-remediation-tools/gitleaks.exe" git . --log-opts=--all --redact --no-banner --ignore-gitleaks-allow` | PASS, exit 0, no leaks found in 1 available commit; process-scoped Git config supplied explicit checkout trust and disabled inaccessible personal excludes |
| Gitleaks `stdin --redact --no-banner`, Python-generated synthetic GitHub-format token | Expected exit 1, one finding; fixture was generated in memory and not stored in repository |
| `python C:/Users/karka/.codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-path>` | PASS for `.agents/skills/visual-testing`, `.claude/skills/visual-testing`, `.agents/skills/feature-implementation`, `.claude/skills/feature-implementation` |
| Python sRGB contrast calculation for proposed control/focus tokens against bg/surface/raised | PASS: control 6.17/5.40/4.42; focus 11.02/9.64/7.89. Token calculation only; no rendered WCAG claim |
| `git -c safe.directory=<checkout> -c core.excludesFile= diff --check` | PASS for tracked diff; separate whitespace inspection also covers untracked source/config/docs |

Gitleaks 8.24.3 was downloaded only to the task temporary directory; Windows archive SHA-256 `3f1a35578631dbfe633cc5b49e6c906e55ff14a4bfd7336a10fb27fe33b6dcd2` matched official release checksums. CI uses the separately pinned Linux archive checksum. No global tool was installed.

Initial `git status` failed on ownership mismatch; later commands used a command-scoped `safe.directory`, without global configuration changes. A later `diff --check` rejected `core.excludesFile=NUL`; an explicitly empty `core.excludesFile=` succeeded and is used by the policy script. An initial PowerShell web download failed; checksum-verified downloads succeeded via approved curl execution. Skill validation initially failed because PyYAML was missing, then because sandbox permissions prevented reading the temporary package. Re-running with temporary `PYTHONPATH` and approved access passed; PyYAML 6.0.2 was installed with `pip --target` in the task temporary directory only.

`docker info --format '{{.ServerVersion}}'` failed: no accessible Docker engine pipe (and personal config access warning). Docker is not required for these setup checks. Backend/frontend builds, DB tests, browser tests and screenshots are not applicable because no app exists. GitHub-hosted workflow execution, branch protection, installed Claude runtime import/tool enforcement and future non-ASCII Java/container/browser behavior remain unverified. H1's commit/publish recommendation remains pending explicit owner authorization.

### 2026-11-08 — complete audit cross-check follow-up
Re-read the complete supplied audit and cross-checked all 17 IDs against current policy, documentation, skills, reviewer definitions, ignore rules and workflow. Expanded `docs/setup-remediation.md` to one status/evidence row per finding. Removed the lingering word "independent" from the specialist code-reviewer description and clarified separate database names when future worktrees share a database server. No application implementation or Git publication actions performed.

Re-ran `python scripts/check_agentic_policy.py` (PASS), `python -m unittest discover -s scripts/tests -v` (7 PASS), temporary Actionlint 1.7.7 against `.github/workflows/agentic-policy.yml` (exit 0), and Gitleaks 8.24.3 directory/history scans (exit 0, no leaks; 1 available commit). Also verified all 17 IDs occur individually in the report, no `client/`, `server/` or `compose.yaml` exists, and tracked/untracked source/config/docs have clean whitespace (supplied audit preserved).

The first history-scan retry failed before scanning because assigning an empty PowerShell environment value removed `GIT_CONFIG_VALUE_1`. Re-run supplied an explicit empty temporary excludes file instead and completed successfully. This was process-scoped configuration; no global settings changed. The CLI policy check uses `git -c core.excludesFile=` directly and passes. H1 remains pending owner approval, M5's executable UI enforcement is deferred to scaffolding, and L7 remains unverified for future Java/container/browser tooling. Existing edited-skill validation and synthetic-token/contrast evidence above remains valid; those checks were not repeated for these description/documentation-only changes.

### 2026-11-08 — independent-review cleanup, N1–N6
Read the complete `docs/reviews/agentic-setup-rereview.md`. Claude independently approved the prior setup for commit with no new P0–P2 findings and six non-blocking P3 findings. This task addresses those six locally and expressly prohibits commit/push/merge; no additional Claude re-review is claimed.

- N1: `.claude/settings.json` is now trackable, with a restricted shared-settings schema (deny/ask lists, optional empty hooks; no grants, environment values or unsupported fields). Local settings/secrets remain excluded. `.mcp.json` remains deliberately prohibited, documented as a separate future policy decision. No active shared settings file was created.
- N2/N3: closed reviewer frontmatter schema rejects duplicate/unknown/security fields and YAML constructs, checks identity/model/tools, and applies only to the three expected reviewer files. Tests demonstrate that a separate implementation-helper fixture can use shell/edit tools without inheriting reviewer restrictions.
- N4: repaired original audit headings, wildcard paste corruption and JSON escaping with an explicit formatting note; all 17 finding headings preserved. The complete second review is retained unchanged.
- N5: focus `#E5F0FF` is distinct from warning; visible team names/legends and different fills/lines/markers are specified. Rendered behavior remains future UI work.
- N6: updated ADR-008/current progress/review status, added `.gitattributes` LF policy and binary exclusions, and protected standard SSH private-key names plus `.ppk` files outside `.ssh/`. Public `.pub` files outside `.ssh/` remain trackable.

| Command/check | Actual result |
|---|---|
| `python scripts/check_agentic_policy.py` | PASS: policy, seven skill pairs, reviewer frontmatter, shared settings, disabled hooks, tracked paths |
| `python -B -m unittest discover -s scripts/tests -v` | PASS: 11 tests; temporary Git ignore tests disable personal excludes, verify safe shared config/public keys stay trackable, and check LF attributes/binary preservation |
| Independent Python full-tree byte comparison of `.agents/skills` and `.claude/skills` | PASS: all 7 files identical; independent of policy implementation |
| `& "$env:TEMP/pitchpulse-remediation-tools/actionlint/actionlint.exe" .github/workflows/agentic-policy.yml` | PASS: Actionlint 1.7.7, exit 0 |
| `& "$env:TEMP/pitchpulse-remediation-tools/gitleaks.exe" dir . --redact --no-banner --ignore-gitleaks-allow` | PASS: Gitleaks 8.24.3, exit 0, no leaks; Windows archive SHA-256 rechecked against the previously verified pin |
| `& "$env:TEMP/pitchpulse-remediation-tools/gitleaks.exe" git . --log-opts=--all --redact --no-banner --ignore-gitleaks-allow` | PASS: exit 0, 1 available commit, no leaks; explicit checkout trust/empty excludes file supplied in process environment only |
| Python audit check | PASS: all 17 original finding headings retained, wildcard corruption absent, JSON example parses |
| Python token contrast calculation | PASS: focus vs bg/surface/raised 16.26/14.23/11.65; control border remains 6.17/5.40/4.42. No rendered accessibility claim |
| `git ... check-attr text eol -- .gitattributes .gitignore scripts/check_agentic_policy.py docs/reviews/agentic-setup-audit.md sample.png` | PASS: text uses LF; binary sample has text unset |
| `git ... diff --check` and all-source whitespace inspection | PASS; Git reports existing README CRLF will normalize to LF when next touched by Git, as expected under the new attributes. No global Git settings or index renormalization performed |

The first all-source whitespace inspection found a missing final newline in `.gitignore`; it was corrected before final checks.

Remaining limits: hosted CI has not run, fresh Claude session import/effective-tool verification remains required, future helper agents need their own review, and private keys under arbitrary filenames still depend on content scanning. App checks/visual verification remain unavailable because no app is implemented. HEAD remains `18c010ae87dd4d2581971f5a5b225435b8314a8f` on `develop`; setup remains uncommitted and includes untracked files.

### 2026-11-08 — Phase 1 foundation (Codex implementer)
Scope: strict/standalone Angular 21 with Tailwind 4, lazy home and typed readiness client; Java 21/Spring Boot 3.5.16 JDBC readiness endpoint; PostgreSQL 17.10 Compose and V1 schema migration; startup/env docs and CI. No match data, simulator, SSE, odds or broadcast. `docs/openapi.yaml` defines only the implemented health contract.

Git: switched to `develop`, ran `git merge --ff-only chore/agentic-setup`, verified both resolve to `fdef4538bba72b97fb18288c49a75454e928a61d` and that the tree was clean, then created `feature/phase1-foundation` from develop. No feature commit, push or merge. Existing local review reports remain ignored and retained.

Environment: Windows with Unicode checkout path; installed Node 20.19.0/npm 11.19.0, portable Temurin 21.0.13+9 (official SHA-256 checked) and official Maven wrapper 3.3.4 downloading checksum-pinned Maven 3.9.11. The machine initially exposed only Java 17 and no Maven; portable tools live under the task temp directory and process-level JAVA_HOME was used. npm needed approved access to its installed path. Docker Desktop was started hidden; Docker 28.3.2 then supported real integration tests. No global settings changed. The CLI-generated optional MCP example was removed without activation.

| Exact command (directory) | Actual outcome |
|---|---|
| `./mvnw.cmd --batch-mode verify` (`server/`, Java 21 selected) | PASS: executable Boot JAR built; 3 MVC tests plus 1 PostgreSQL Testcontainers integration test, 0 failures/skips. Integration checks HTTP health, application schema, V1 history, migration no-op on rerun and Flyway validation |
| `docker compose config --quiet` and `docker compose up --detach --wait` (root) | PASS: local PostgreSQL healthy with generated password in ignored `.env`, loopback binding and persistent volume |
| `java -jar server/target/pitchpulse-server-0.0.1-SNAPSHOT.jar` (portable Java 21) and `curl.exe --fail --silent http://127.0.0.1:8080/api/v1/health` | PASS: packaged API migrated Compose PostgreSQL and returned 200 with `{status: UP, service: pitchpulse, database: UP}` |
| `npm.cmd ci` (`client/`) | PASS: clean lockfile install. Reports 16 moderate development-tool advisories; no forced fixes/suppression |
| `npm.cmd run lint` (`client/`) | PASS: CSS color-token enforcement |
| `npm.cmd test` (`client/`) | PASS: 4 tests in 2 files, lazy route/API integration plus loading, database-down, failure and retry states |
| `npm.cmd run build` (`client/`) | PASS: production bundle, initial raw size 222.87 kB, estimated transfer 61.87 kB |
| `npx.cmd playwright install chromium` then `npm.cmd run e2e` (`client/`) | PASS: 6 browser tests across 390x844, 768x1024 and 1440x900. Real API/DB connectivity plus controlled loading/failure/retry, keyboard flow, overflow and axe (zero violations). Screenshots captured and visually inspected at all three sizes |
| `npm.cmd audit --omit=dev` (`client/`) | PASS: 0 runtime dependency vulnerabilities. Full audit: 16 moderate dev findings through CLI glob/minimatch; ADR-009 records the limitation |
| `actionlint.exe .github/workflows/agentic-policy.yml .github/workflows/foundation.yml` (temporary Actionlint 1.7.7) | PASS, exit 0; hosted Actions execution remains unverified |
| `python scripts/check_agentic_policy.py` and `python -B -m unittest discover -s scripts/tests -v` | PASS: policy/skill parity and 11 setup tests |
| Gitleaks 8.24.3 `dir <temporary-source-snapshot> --redact --no-banner --ignore-gitleaks-allow` | PASS: no leaks in 79 tracked/untracked nonignored source files. Snapshot enumerated by `git ls-files --cached --others --exclude-standard -z`; ignored credentials, dependency/build output and local reviews were excluded, and prohibited path checks passed |
| `git diff --check` plus Python whitespace inspection of all tracked/untracked source/config/docs | PASS; no staged feature files, HEAD still equals local develop at the approved setup commit |

Browser screenshots: ignored `client/test-results/foundation-real-frontend-p-7637b--Spring-Boot-and-PostgreSQL-{mobile,tablet,desktop}/foundation.png`. Captures are review evidence, not approved regression baselines. Initial captures included the keyboard focus ring; final captures are taken before keyboard checks. No visual issue was hidden by updating baselines.

Migration note: V1 creates only the `pitchpulse` schema, with Flyway history in `public`. Once applied, future changes must be additive migrations; no volume deletion or destructive rollback was used. Startup requires database availability; 503 health behavior after database failure is covered by MVC tests, while the integration/browser happy path uses real PostgreSQL.

Limitations: Ubuntu/Node 24 hosted CI was statically validated but not executed; local tests used Windows/Node 20.19. No claim that a fresh machine or production deployment was tested. The dev server/proxy is local tooling; production hosting needs a same-origin API reverse proxy. Full match-centre acceptance, SSE, historical data and provider licensing remain future tasks. Local database credentials, outputs and review evidence are ignored. Claude should review the frozen working tree including untracked app files; handoff is in ignored `docs/reviews/phase1-foundation-handoff.md`.

### 2026-11-08 — Greek-first runtime i18n (Codex implementer)
Implemented Transloco/Transloco Locale 8.4.0 on the existing uncommitted foundation. Greek is the default independently of browser language, English is supported, and all current UI copy/accessibility labels/metadata use structured JSON catalogs. A labelled native selector preserves focus, persists an allowlisted preference and handles storage/load failures. The completed health-check timestamp is displayed through locale formatting with Europe/Athens; number formatting is wired through the locale plugin and verified in a test-only host. No artificial numeric statistics or football features were added. Backend sources, API contract, status enums and identifiers were not changed by this task.

Documentation updated with the feature: ADR-010 rationale, actual architecture/file layout/fallback/persistence/formatting, switcher UX, implemented test coverage, this log, and the concise AGENTS.md requirement. README changes are limited to new language instructions and the verified startup workaround below. No new Markdown files were created for i18n; prior foundation/setup documentation and review evidence are retained.

| Command/check | Verified final result |
|---|---|
| `npm.cmd install --save-exact @jsverse/transloco@8.4.0 @jsverse/transloco-locale@8.4.0` (`client/`) | PASS: local dependencies/lockfile updated; existing 16 moderate development-only advisories remain |
| `npm.cmd run lint` (`client/`) | PASS: CSS token lint |
| `npm.cmd test` (`client/`) | PASS: 14 tests in 3 files, including 10 new localization/catalog tests and the 4 translated foundation tests |
| `npm.cmd run build` (`client/`) | PASS: production bundle 280.65 kB initial raw / 77.09 kB estimated transfer; both UTF-8 translation assets emitted |
| `npm.cmd run e2e` (`client/`) | PASS: 21 tests at 390x844, 768x1024 and 1440x900: 15 i18n cases plus 6 existing foundation cases. Runtime switches/reloads/fallback, metadata, focus, empty states, Athens dates despite a Los Angeles browser timezone, overflow and zero axe violations in both languages verified |
| `npm.cmd audit --omit=dev` (`client/`) | PASS: 0 runtime dependency findings; full development-tool advisory limitation from ADR-009 remains |
| Python comparison of `public/i18n/{el-GR,en-US}.json` with `dist/client/browser/i18n/` output | PASS: both emitted catalogs match source; actual Greek Unicode/endonym preserved |
| `python scripts/check_agentic_policy.py` | PASS: repository policy and mirrored skills; no agent skill/configuration changes made |
| Gitleaks 8.24.3 `dir <nonignored-source-snapshot> --redact --no-banner --ignore-gitleaks-allow` | PASS: no leaks detected in tracked/untracked source; generated local credentials, dependency output and local review reports excluded through Git ignore rules |
| `git diff --check` and source whitespace inspection | PASS; HEAD still equals local develop base, with no staged feature changes |

Corrections during validation: fixed initial TypeScript option/generic mismatches. A formatter test initially called the locale service without the pipe configuration; it now exercises actual date/number pipes in a host, using runtime Intl rules rather than assuming a fixed hour cycle. Visual inspection then caught Greek text replaced by question marks by a Windows shell-to-Python encoding boundary, despite earlier catalog-to-catalog assertions passing. Catalogs/README were rewritten as UTF-8 and explicit Greek-script/native-name plus replacement-character assertions added. The final 14-test run/build and full browser suite passed after that correction. Final screenshots are captured before axe DOM probes; computed panel/grid styles were also checked unchanged after switching.

Windows headless Chromium also produced incomplete/blank captures after switching despite correct computed styles/layout and passing DOM assertions. A focused single-worker reproduction with Windows-only `--disable-gpu` produced a complete English capture; concurrent captures remained inconsistent. Playwright now uses one worker plus that flag only on Windows and explicitly checks English heading/panel visibility. The complete browser suite was re-run with this configuration; product styles and other-platform workers/launch options are unchanged.

Screenshots for review (ignored, not approved baselines): `client/test-results/i18n-Greek-defaults-metada-85417-ccessible-at-every-viewport-{mobile,tablet,desktop}/i18n-greek.png` and `client/test-results/i18n-switches-at-runtime-p-743e4--reloads-in-both-directions-{mobile,tablet,desktop}/i18n-english.png`. Greek/English captures were inspected at all three viewports. Browser expected dates use the browser's own Intl to avoid Node/Chromium ICU differences. Dates in i18n screenshots are deliberately fixed test-clock values, not football data.

**Existing foundation issue / test API workaround:** restarting the retained Compose database exposed Flyway searching for history under schema `pitchpulse` after V1 creates that username-matching schema. Unchanged backend startup failed with SQLSTATE 42P06 (`schema pitchpulse already exists`). The i18n browser run used the existing packaged JAR with `--spring.flyway.default-schema=public --debug=false --logging.level.root=INFO`; this validated the original public history and returned health UP. No migration/history edits, database reset or backend source fix was made. README documents the equivalent process-level `SPRING_FLYWAY_DEFAULT_SCHEMA=public` startup workaround. Resolve this as a separate foundation follow-up; browser passing does not establish that unconfigured persistent-database restart works.

### Focused i18n handoff for independent Claude review
Base/current HEAD remains `fdef4538bba72b97fb18288c49a75454e928a61d`, branch `feature/phase1-foundation`. Foundation and i18n are both uncommitted; ordinary `git diff` omits new app files. No commit, push, branch merge or unrelated architecture change was performed in this task. Review read-only and return the Markdown report as required by AGENTS.md; this implementer has not supplied or claimed an independent approval.

Review scope: `client/public/i18n/`, `client/src/app/i18n/`, translated home/app configuration/tests, `client/e2e/{foundation,i18n}.spec.ts`, `client/playwright.config.ts`, `client/angular.json`, `client/tsconfig.json`, package/lockfile, plus the seven requested existing documentation/policy files (including README user/startup instructions). Focus on bundled Greek fallback, stored-language initialization/failures, latest-request ordering/focus, document metadata, locale/timezone separation, UTF-8 content, and unchanged API identifiers. Formatting service callers must pass shared date options explicitly; configured pipes inherit the default timezone.

Remaining work/limits: independent Claude review, hosted Ubuntu/Node 24 CI and manual assistive-technology testing are not completed. Persistence is session-only when browser storage is blocked. Keys missing from both catalogs cannot be translated; catalog tests and feature review must keep Greek complete. No domain plural-heavy copy or football feature was added. Address the existing foundation Flyway restart issue separately; retain the documented 16 moderate development-dependency findings for upstream review. Existing review reports stay local/ignored; no unnecessary Markdown artifacts were added.

An unrelated untracked `scripts/dev-lib.sh` appeared during final Git inspection and was left untouched; it is not an i18n deliverable. Final browser verification with one Windows worker passed all 21 tests in 19.5 seconds, with complete English review captures at all three sizes. The task-owned API and Compose database are stopped after testing, preserving the database volume and local credentials.

### 2026-11-08 — Durable Flyway restart fix (Codex implementer)
Scope: investigate the retained PostgreSQL state, fix Flyway configuration, add a restart regression, and verify fresh initialization plus existing-volume restarts. No agents were delegated or allowed to write in parallel. Claude's completed `dev.sh`, `stop-dev.sh` and `scripts/dev-lib.sh` were read and left byte-identical. No frontend, API-contract, Compose or V1 changes were made in this task. The earlier i18n-stage workaround above is historical and no longer required.

**Observed root cause:** Compose uses login/database `pitchpulse`. Existing SQL inspection returned `search_path = "$user", public` and `current_schema() = pitchpulse`; both schemas contained a `flyway_schema_history` table. The authoritative public table had exactly one successful V1 row (checksum `1351761741`), while the shadow `pitchpulse` history had zero rows. V1 creates the username-matching schema. Without an explicit Flyway default, fresh connections after V1 resolve a different default schema and Flyway misses the successful public history. An empty namespace leads to reapplying V1 and the reported duplicate-schema error; with application data present, Flyway instead refuses a nonempty schema without history. The original test used the default test username and called migrate again on one Flyway instance, so it did not exercise this transition.

**Fix:** `server/src/main/resources/application.yml` now sets `spring.flyway.default-schema: public`, with a comment explaining the search-path change. Flyway history remains in its original public location; the application namespace and PostgreSQL role/database search paths are untouched. V1 was not edited or made artificially idempotent. No baseline, repair, history relocation, dropped schemas, reset, deleted volume or destructive SQL was used. The empty shadow table is retained and ignored. ADR-011 and architecture describe the actual configuration; README removes the obsolete override instructions.

**Regression:** `FlywayRestartIT` creates an isolated PostgreSQL 17.10 Testcontainers database with the production username/database, verifies initial public resolution, boots and closes a complete application context, writes a probe only in that disposable database, verifies a new connection now resolves `pitchpulse`, and starts a second independent context. It checks HTTP health, identical public history rows, retained probe data, absence of a new shadow history, and Flyway validation. It does not override Flyway settings. Existing Compose data is not mounted into the test containers.

| Exact command/check | Actual result |
|---|---|
| SQL via `docker compose exec -T postgres psql -X ...` (stdin, read-only) | Confirmed role, search path, schemas, public V1/checksum and empty shadow history; no user-data rows printed |
| `./mvnw.cmd --batch-mode --no-transfer-progress '-Dit.test=FlywayRestartIT' verify` before the configuration fix | Expected FAIL on second application context: the populated username schema had no local Flyway history. This is the same misplaced-history cause, with Flyway's nonempty-schema protection triggered by test probe data |
| `./mvnw.cmd --batch-mode --no-transfer-progress verify` after the fix, Java 21, no Flyway environment override | PASS: 3 MVC unit tests + 2 PostgreSQL integration tests, zero failures/errors/skips; executable JAR built. Regression includes fresh initialization and a full application restart on the same isolated database |
| `PITCHPULSE_JAVA_HOME=<portable-JDK-21> bash ./dev.sh` then `bash ./stop-dev.sh`, twice, against the existing volume | PASS: both complete startup/shutdown cycles; original named volume reused. No Flyway command-line/environment override. Scripts package the checked-in config; the copied runtime JAR was inspected to contain `default-schema: public` |
| `curl.exe --fail --silent --max-time 10 http://127.0.0.1:8080/api/v1/health` and equivalent `:4200/api/v1/health` | PASS on first cycle; Python HTTP/JSON assertions also verified 200 and exact UP body on both ports on the second cycle |
| Read-only `pg_dump` logical fingerprints before and after each cycle | PASS: identical complete logical dumps, excluding only pg_dump's randomized psql guard lines; contents/credentials were not printed. Public V1 stayed one successful row with the same checksum; shadow history stayed empty |
| SHA-256 comparison against task-start file snapshots | PASS: V1 and all three Claude script files byte-identical |
| `docker volume inspect pitchpulse_postgres-data` after final shutdown | PASS: original named volume still exists, created `2026-11-08T19:51:31Z`. Scripts stopped services without removing volumes |
| `python scripts/check_agentic_policy.py`, `git diff --check`, source-snapshot Gitleaks scan and index inspection | PASS: policy/skill parity, clean scoped whitespace, no detected source secrets, no staged changes, HEAD still equals local develop base |

The first targeted Maven invocation omitted quotes around `-Dit.test=...`, which PowerShell split and Maven rejected before tests; the quoted rerun above produced the expected regression failure. Verification used the existing portable Temurin 21.0.13/Maven wrapper, with process-local environment only. Logs are in ignored `logs/dev/` and temporary Maven logs; no secrets or database contents were logged as evidence.

Handoff: review the single production configuration change, `FlywayRestartIT`, README, architecture, ADR-011 and this entry. Other uncommitted foundation/i18n/script files were preserved. No staging, commit, push or merge. Existing data/volume and V1 history are preserved; services are stopped at completion. Remaining limits: hosted CI and unrelated frontend tests were not rerun for this backend-only fix. Databases whose authoritative history was deliberately placed outside public require inspection rather than automatic repair or migration; the verified local public history is the intended configuration here.
