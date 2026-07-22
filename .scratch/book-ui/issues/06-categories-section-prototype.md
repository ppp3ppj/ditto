Type: prototype
Status: resolved

## Question

What does the project page's Categories section look like — used both at project-creation time and later for ongoing management? Needs a concrete prototype (via /prototype) covering add/edit/delete interactions (inline vs. modal), ordering, and empty-state treatment when a project has no categories yet. Unlike Members, Categories has no upstream backend wrinkle (plain CRUD via `Ditto.Projects`), so this isn't blocked on a separate grilling ticket.

## Answer

Three structurally different, fully interactive variants were prototyped as a throwaway LiveView (`DittoWeb.PrototypeCategoriesSectionLive`, route `/prototype/categories-section`, in-memory fake category list) and reviewed live:

- **A** — chips/tags: categories as removable pills in a wrap flow, slim add-input below, minimal empty state (just the input with placeholder copy).
- **B** — card list (mirrors the winning Members section): tinted "Add category" card at top, each category its own card with a pencil-to-edit action (swaps the row to an inline rename form with Save/Cancel) and a trash icon that swaps to a "Remove? Yes/No" confirm footer; a dashed placeholder card shows when the list is empty.
- **C** — inline-editable list: category names are directly-editable inputs that save on blur (no separate edit-mode toggle), hover-reveal delete, and an always-present "add" row at the bottom doubling as the empty state.

**Winner: Variant B**, confirmed with two follow-ups both defaulted:
1. Edit mode keeps the **explicit Save/Cancel button pair**, not a lighter blur/Enter-to-save interaction — matches the deliberate, button-driven pattern already used for remove-confirm here and in Members.
2. Empty state keeps the **dashed-border placeholder card** ("No categories yet — add one above") below the always-visible add-category card.

Spec for the Categories section: a tinted "Add category" card at the top (name input + Add button, inline error below on validation failure — empty / duplicate name); below it, one card per category with a pencil icon (swaps the row to an inline rename form with Save/Cancel) and a trash icon (swaps to "Remove? Yes/No"); a dashed empty-state card in place of the list when there are zero categories. This mirrors the Members section's card-list shape closely — the two chapters should read as the same design language.

The throwaway prototype code (`lib/ditto_web/live/prototype_categories_section_live.ex` and its route) has been deleted.
