# Daily Work Planner

Personal, local-first macOS tool for choosing what to do today and arranging it—layered over system Calendar and Reminders, not a replacement for them.

## Language

**Inbox Item**:
An uncommitted capture: something noticed or dumped that has not yet been promised to a specific day.
_Avoid_: Task, todo, note, work item

**Task**:
A work unit promised to a day; it can be completed (checked off) and may have a soft order or time window, but no hard calendar lock unless linked to an Event.
_Avoid_: Todo, work item, work content, 工作内容

**Event**:
A time-bound block with a hard start and end (e.g. a meeting), typically sourced from the system calendar.
_Avoid_: Appointment, meeting (as the domain term), schedule item

**Day Plan**:
The set of Tasks (and visible Events) the user has committed to for one calendar day. Editable all day; the planning ritual is a guided way to build it, not a lock.
_Avoid_: Schedule, agenda, daily list, today view (UI label only)

**Planning Ritual**:
A guided pass (typically morning) that pulls from Inbox Items and Overdue Tasks to build or revise today's Day Plan. Not a separate persisted entity with a locked state.
_Avoid_: Daily standup, planning session, morning review (unless used as UI copy)

**Soft Window**:
An optional rough time hint on a Task: a preset (morning / afternoon / evening) or a clock time. It does not reserve calendar time; overlap with an Event may show a weak hint only.
_Avoid_: Time block, time slot, appointment, schedule

**Overdue Task**:
A Task still incomplete after the calendar day it was promised to has ended. It stays on that day until the user explicitly moves it (e.g. into a new Day Plan or back to Inbox).
_Avoid_: Expired, leftover, carry-over (as automatic behavior)

**Reminder**:
A notification attached to a Task that fires at a chosen time; not a first-class work item. Event alerts stay in the system calendar.
_Avoid_: Alert, notification (system term), alarm

**Quick Capture**:
The fast path (menu bar and/or hotkey) that creates an Inbox Item without opening the full Day Plan UI.
_Avoid_: Quick add, inbox dump, note

**Reminders Import**:
An optional Planning Ritual step that copies unfinished system Reminders into local Inbox Items. Deduped by system reminder ID while the local copy still exists; no ongoing sync.
_Avoid_: Sync, mirror, two-way link

**Completed Task**:
A Task marked done. It remains on that day's Day Plan in a completed section so the day is a record of what was finished, not only what remains.
_Avoid_: Archived task, deleted task, checked item (UI only)
