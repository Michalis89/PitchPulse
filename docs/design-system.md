# PitchPulse design system — v0.1

Status: proposed visual direction. Treat tokens as the single source of truth for application styling; product owner can revise them.

## Experience goals
An efficient live sports dashboard: fast to scan, usable on small screens, clear between LIVE/FINAL/DEMO, never confused with copyrighted TV footage. Dark-first with accessible light support later. Restrained color, high information density without visual noise.

## Semantic tokens (initial proposal)
| Token | Value | Meaning |
|---|---|---|
| `--pp-bg` | `#0B1220` | App background |
| `--pp-surface` | `#132033` | Panels |
| `--pp-surface-raised` | `#1D3047` | Raised panel |
| `--pp-text` | `#F3F7FC` | Primary text |
| `--pp-muted` | `#A8B8CA` | Secondary text |
| `--pp-border` | `#34465C` | Surface boundary |
| `--pp-control-border` | `#8196B0` | Required control boundary |
| `--pp-focus` | `#E5F0FF` | Visible focus indicator, distinct from warning |
| `--pp-accent` | `#55E6AE` | Primary interactive accent |
| `--pp-live` | `#FF636E` | Live only |
| `--pp-warning` | `#F4BE5A` | Warning |
| `--pp-home` | `#C7A6FF` | Home team charts |
| `--pp-away` | `#65A4FF` | Away team charts |

Colors remain proposed. Use `--pp-border` only for decorative separators, never as the sole control boundary or focus indicator. Control/focus tokens must have at least 3:1 contrast against adjacent surfaces; verify the actual rendered state in browser. Home-team and interactive accents are distinct, but labels and shapes must also convey their meaning. Do not encode meaning with color alone. No overall WCAG conformance is claimed from token ratios.

Team comparisons require visible team names and a legend wherever color is used. Use a solid fill/line with triangle markers for home and a hatched fill/dashed line with circle markers for away where the renderer supports them; provide equivalent text values for charts. Do not rely on the home/away colors alone, including in grayscale or with color-vision deficiencies. Verify this behavior when the UI is implemented; the proposed color pair is not a validated accessibility solution.

## Foundations
- Typography: system UI font stack initially, tabular numerals for scores, odds, timestamps and xG; headings 600–700 weight. No external fonts without approval.
- Spacing base: 4px; allowed spacing steps 4/8/12/16/24/32/48. Radius: 8px controls, 12px cards, 16px large panels.
- During Phase 1 scaffolding, define color, space, type and radii in `client/src/styles/tokens.css` plus Tailwind theme mapping. Add Stylelint to reject color literals outside the token file and automated axe checks to the browser smoke test. These enforcement tools do not exist yet; no UI scaffold is part of setup remediation. No random per-component hex colors or magic spacing values.
- Main container up to 1440px with responsive gutters; use the canonical viewport matrix below for design and testing. Support narrow content without horizontal page overflow.
- Components: `Scoreboard`, `MatchCard`, `StatusPill`, `StatBar`, `EventTimeline`, `PitchView`, `CompetitionSelect`, `EmptyState`, `ErrorState`, `Skeleton`.
- Shared components define visual variants; do not duplicate visual markup per page. One place defines team colors, typography and surface styles.

## Motion and event map
- Timeline and score remain readable with `prefers-reduced-motion: reduce`.
- Animate known coordinates/events only, with `Illustrative animation` and `DEMO` labels when applicable.
- Rendering must not infer missing player positions or pass trajectories as facts.
- Default pitch layout can use SVG until PixiJS needs its rendering benefits; preserve renderer boundary.

## UX states and accessibility
- Support loading, error, offline/reconnecting, postponed, half-time, final, and missing-data states.
- Buttons and tabs keyboard accessible; focus visible; targets comfortably tappable; responsive content order.
- Always display odds/data timestamps and provider/DEMO provenance where needed.
- Show timezone in match times; never present placeholder league options as supported.

## Visual review contract
This is the canonical viewport matrix for all design, testing and review instructions (CSS pixels):

| View | Width x height | Scope |
|---|---|---|
| Mobile | 390x844 | Phase 1 |
| Tablet | 768x1024 | Phase 1 |
| Desktop | 1440x900 | Phase 1 |
| Broadcast | 1920x1080 | Phase 3, only after that route is implemented |

- Capture screenshots at each applicable viewport above; additional widths are supplementary checks.
- Compare scoreboard, statistics, typography scale, pitch proportions and alignment across breakpoints.
- Capture stable fixtures with deterministic clocks, animations disabled and seeded data.
- Reviewer must inspect actual screenshots where available, not assert UI quality from code alone.
