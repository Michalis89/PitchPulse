---
name: football-data-integrity
description: Use when changing event ingestion, live state, football statistics, corrections or historical storage.
---

# Football Data Integrity

Model status progression, idempotent event keys, out-of-order deliveries, stoppage time, goal corrections/VAR, timestamps in UTC, source provenance and licensed retention. Provider adapters normalize into internal DTOs. SSE reconnect uses event IDs and client dedupe. No invented live statistics, unknown locations or false xG. Build deterministic scenarios and regression tests.
