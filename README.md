# Day Planner

Personal, local-first macOS daily work planner. Domain language: `GLOSSARY.md`. Spec: `docs/specs/daily-work-planner-mvp.md`.

## Run

```bash
swift build
swift test
./scripts/package-app.sh
open .build/App/DayPlanner.app
```

Or without packaging:

```bash
swift run DayPlanner          # AppKit app (menu bar DP + ⌃⌥Space Quick Capture)
swift run DayPlannerTests     # same suite as executable fallback
```

Data: `~/Library/Application Support/DayPlanner/planner.json`
