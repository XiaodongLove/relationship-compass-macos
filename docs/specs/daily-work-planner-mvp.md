# Daily Work Planner (MVP)

Spec for the personal, local-first macOS daily work planning app. Domain language follows root `GLOSSARY.md`. Data authority follows `docs/adr/0001-local-tasks-not-reminders-mirror.md`.

## Problem Statement

I plan my day across Calendar, Reminders, and ad-hoc notes. Nothing helps me run a short planning pass, commit a small set of work to today, arrange it roughly in time, and get Task-level nudges—without becoming another full task manager or a second calendar.

## Solution

A single-user macOS app whose main window is today's Day Plan. I Quick Capture into an Inbox, optionally run a Planning Ritual (including one-shot Reminders Import), commit work as Tasks for a day with order and Soft Windows, see read-only Events alongside, complete Tasks in place, and explicitly move Overdue Tasks. System Calendar Events are read-only; Inbox/Task data is local and authoritative.

## User Stories

1. As a solo knowledge worker, I want a macOS app that is only for me and stores data locally, so that I do not need accounts or team features.
2. As a user starting my morning, I want a guided Planning Ritual, so that I can turn Inbox Items and Overdue Tasks into today's Day Plan without a locked ceremony.
3. As a user, I want the main window to open on today's Day Plan, so that "what am I doing today?" is the default question.
4. As a user, I want Inbox, overdue handling, and Reminders Import available from the ritual or a light drawer—not as equal home tabs—so that the UI stays day-centric.
5. As a user away from the full window, I want Quick Capture from the menu bar, so that I can dump an Inbox Item in seconds.
6. As a user, I want a global hotkey that focuses Quick Capture, so that I can capture without hunting the menu bar.
7. As a user, I want Quick Capture to create an Inbox Item (not a Task), so that capture stays uncommitted.
8. As a user mid-day, I want to create a Task directly on today's Day Plan, so that Inbox is not a mandatory gate.
9. As a user in the Planning Ritual, I want to pick Inbox Items into today's Day Plan (becoming Tasks), so that I explicitly promise work to the day.
10. As a user in the Planning Ritual, I want to see Overdue Tasks and choose where each goes (today, another day, or back to Inbox), so that nothing auto-carries silently.
11. As a user, I want unfinished Tasks to stay on their promised day after local midnight and become Overdue Tasks, so that history stays honest.
12. As a user, I want overdue to be based on calendar-day end (24:00 in the system time zone), so that day boundaries stay simple.
13. As a user, I want to reorder Tasks on a Day Plan by dragging, so that sequence matches how I intend to work.
14. As a user, I want to set an optional Soft Window on a Task (morning / afternoon / evening, or a clock time), so that I can rough-schedule without blocking the calendar.
15. As a user, I want Soft Windows never to reserve calendar time, so that Events remain the only hard schedule.
16. As a user, when a Soft Window overlaps an Event, I want a weak visual hint only, so that I am informed but not blocked.
17. As a user, I want to mark a Task complete and see it remain on that day's Day Plan in a completed section, so that the day is a record of what I finished.
18. As a user, I want to uncomplete a Completed Task on that day, so that I can correct mistakes.
19. As a user, I want to move a Task from a Day Plan back to Inbox, so that I can un-commit work.
20. As a user, I want to change a Task's promised day explicitly, so that rescheduling is intentional.
21. As a user, I want to attach a Reminder to a Task (at a clock time or offset), so that I get nudged about committed work.
22. As a user, I want Event alerts to stay in the system calendar, so that this app does not duplicate calendar notifications.
23. As a user, I do not want scheduled "daily Day Plan digest" pushes in MVP, so that notifications stay sparse.
24. As a user, I want today's Day Plan to show read-only Events from enabled system calendars, so that meetings appear next to Tasks.
25. As a user, I want MVP to show all visible system calendars' Events (subset filtering can come later in settings), so that setup stays minimal.
26. As a user in the Planning Ritual, I want an optional Reminders Import that copies unfinished system Reminders into Inbox Items, so that I can drain Apple Reminders without mirroring.
27. As a user, I want Reminders Import to skip system reminder IDs that already have a living local Inbox Item or Task copy, so that re-import does not duplicate.
28. As a user, after I delete the local copy, I want a later import to be allowed again for that system ID, so that "delete and re-pull" works.
29. As a user, after import, I want the local Inbox Item to be authoritative with no sync back to Reminders, so that edit/complete semantics stay clear.
30. As a user, I want to open a past day's Day Plan (including its completed section), so that I can review what I did.
31. As a user on a past day view, I want to still complete Tasks or move Overdue Tasks, so that catch-up does not require a special read-only mode.
32. As a user, I want Planning Ritual to be skippable and Day Plan editable all day, so that the ritual never locks the plan.
33. As a user granting permissions, I want clear prompts for Calendar (read) and Reminders (read for import) and notification permission for Task Reminders, so that system integrations work.
34. As a user, I want the app to degrade gracefully if Calendar or Reminders access is denied (Tasks/Inbox still work; Events/import unavailable), so that core planning is not blocked.
35. As a future reader of the codebase, I want behavior expressed through one `DayPlanner` facade, so that UI and EventKit adapters are replaceable.

## Implementation Decisions

- **Greenfield macOS app** (SwiftUI + AppKit menu bar extras as needed). No existing application modules; this spec defines the first product surface.
- **Single testable seam: `DayPlanner`** — application facade / domain service. All user-visible behaviors above are operations or queries on this seam. SwiftUI views, menu bar, and EventKit code call it; they are not a second seam.
- **Ports behind `DayPlanner`** (real adapters in app; fakes in tests):
  - `PlannerStore` — persistence for Inbox Items, Tasks, Soft Windows, order, Reminder metadata, import source IDs
  - `CalendarReading` — Events for a date range from system calendars
  - `RemindersReading` — unfinished reminders for optional import
  - `TaskNotifying` — schedule / cancel local notifications for Task Reminders
  - `Clock` — "now" for day-boundary / overdue classification
- **Local authority** (ADR 0001): Inbox Items and Tasks live only in `PlannerStore`. Reminders Import copies into local records and stores the system reminder ID for dedupe. No ongoing sync. No write-back to Reminders or Calendar in MVP.
- **Entity rules**:
  - Inbox Item → Task when promised to a calendar day (ritual pick or equivalent commit)
  - Task may be created already promised to a day (direct Day Plan create)
  - Task → Inbox Item (or equivalent uncommitted record) when returned to Inbox
  - Overdue: incomplete Task whose promised calendar day is before `Clock`'s current local calendar day
  - Soft Window: enum preset (morning / afternoon / evening) or optional clock time; never a hard block
  - Day Plan for date D = Tasks promised to D (open + completed) plus Events read for D
- **Ordering**: integer or relative rank per day; drag-and-drop updates rank via `DayPlanner`
- **UI shell**: main window = Day Plan for selected date (default today); menu bar + hotkey → Quick Capture; ritual/drawer for Inbox, overdue triage, import
- **Permissions**: EventKit calendar read; EventKit reminders read (import); UserNotifications for Task Reminders

## Testing Decisions

- **Good tests** assert externally observable behavior through `DayPlanner` only: given store/clock/calendar/reminders/notifier fakes, after a command, queries and port call expectations match the glossary rules. Do not test SwiftUI layout, EventKit wiring, or private helpers.
- **Primary module under test**: `DayPlanner` (with in-memory `PlannerStore` and fake ports).
- **Cover at minimum**: capture; direct Task create; commit from Inbox; return to Inbox; change day; reorder; Soft Window; complete/uncomplete; overdue at day boundary (inject `Clock`); Reminder schedule/cancel on set/complete/move; Reminders Import dedupe by source ID; re-import after local delete; Day Plan query merges Tasks + Events; Soft Window / Event overlap yields hint flag without blocking; denied calendar/reminders ports leave core flows working.
- **Prior art**: none in-repo yet; establish this facade-style suite as the template for later features.
- **Adapters**: thin smoke or manual checks for EventKit/notification wiring; not the regression suite.

## Out of Scope

- Projects, tags, priority matrices
- Multi-day kanban / week-view planning
- Stats, pomodoro, habits
- iCloud or multi-device sync
- Writing Events to the system calendar
- Mirroring or two-way sync with Apple Reminders
- Daily digest / summary push notifications
- Share extensions / Services (post-MVP)
- Multi-user, accounts, collaboration
- Custom "personal day boundary" other than local midnight
- Calendar subset picker in settings (MVP shows all visible calendars; filter later)

## Further Notes

- Glossary: `/GLOSSARY.md`
- ADR: `/docs/adr/0001-local-tasks-not-reminders-mirror.md`
- Confirmed test seam: one `DayPlanner` facade with the ports listed above
- Soft Window presets and clock-time form are product defaults from the locked design discussion; free-form long text is out
