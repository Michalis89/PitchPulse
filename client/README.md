# PitchPulse client

Angular 21 standalone/strict, Tailwind 4, Vitest and Playwright. See the root README for complete database/API startup and environment instructions.

Run `npm ci` then `npm start`; the dev proxy forwards `/api/**` to `127.0.0.1:8080`.

Checks: `npm run lint`, `npm test`, `npm run build`. Browser checks: `npx playwright install chromium` then `npm run e2e` with the real backend and database running. Playwright starts its own frontend server; port 4200 must be free. Screenshots are stored under ignored `test-results/`.

All CSS color literals belong in `src/styles/tokens.css`; `src/styles.css` maps them into Tailwind. Build output is `dist/client/browser`. No match data is implemented yet.
