Type: prototype
Status: resolved

## Question

How does the existing time-entries table get re-hosted in the new layout? Per the locked scope decision, it stays a conventional table/form (no "book" document metaphor), but needs a concrete prototype (via /prototype) covering: how it sits within the new project page/contextual sidebar chrome, whether entries are filtered/grouped (by category? by date?), and where the add-entry form lives relative to the table.

## Answer

Three structurally different, fully interactive variants were prototyped as a throwaway LiveView (`DittoWeb.PrototypeTimeEntriesSectionLive`, route `/prototype/time-entries-section`, in-memory fake entries across multiple dates/categories) and reviewed live:

- **A** — flat reverse-chronological table (Date, Category, Duration, Note), add-entry form as a card above it.
- **B** — grouped by date, each day as its own subheading with a daily total, add-entry form pinned above all groups.
- **C** — category filter tabs above a flat table, add-entry form below the table.

**Winner: Variant A** — no grouping or filtering, just a flat table, form on top. Confirmed with two follow-ups:
1. **Flat/ungrouped is fine for now** — no pagination or date-range filtering needed as a near-term follow-up; matches the "conventional, not fancy" scope decision for this section. Revisit only if entry volume becomes a real problem later.
2. **Duration display shows the raw number in addition to the friendly format** — not just "1h 30m," but the exact raw value (minutes, matching the schema's stored unit) alongside it, e.g. as small subtext, for precision.

Spec for the Time Entries section: an "Log time" form card at the top (date, category select, duration-in-minutes input, note — same fields as the current form, re-scoped to skip the project selector since you're already inside one project), followed by a flat table sorted reverse-chronologically (newest first), columns Date / Category / Duration / Note, with the Duration cell showing both the friendly format ("1h 30m") and the raw minutes value.

The throwaway prototype code (`lib/ditto_web/live/prototype_time_entries_section_live.ex` and its route) has been deleted.
