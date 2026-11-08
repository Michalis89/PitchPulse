# PitchPulse
PitchPulse is a planned public football match center, initially for Greek Super League only. This checkout currently contains repository policy, agent skills, review configuration and setup CI. Angular, Spring Boot, PostgreSQL, live feeds and browser tests are not implemented yet.

Phase 1 will provide one fictional PostgreSQL-backed fixture labeled DEMO, REST/SSE updates and illustrative event animation. External football/odds feeds and YouTube integration are deferred.

Read [AGENTS.md](AGENTS.md) for scope and policy, [README-SETUP.md](README-SETUP.md) for agent setup, and [docs/setup-remediation.md](docs/setup-remediation.md) for verification and remaining risks.

Local setup validation (Python 3.10+ and Git):

```powershell
python scripts/check_agentic_policy.py
python -m unittest discover -s scripts/tests -v
```

Secret scanning uses the Gitleaks CLI in CI; local commands are documented in [docs/mcp-and-hooks.md](docs/mcp-and-hooks.md). Application startup commands will be added with the Phase 1 implementation.
