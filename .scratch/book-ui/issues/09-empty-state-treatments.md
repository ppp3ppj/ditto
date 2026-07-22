Type: prototype
Status: resolved

## Question

Categories already has a decided empty-state (a dashed placeholder card below the always-visible add-category card, from ticket "Categories section prototype"). Three other zero-data cases still need a treatment decided:

- **Home with zero projects** — a brand-new user who hasn't created any project yet. What does the projects list area show instead of cards?
- **Members chapter with only the owner** — every project always has at least one member (the owner), so this is "list has exactly one row, no one else invited yet" rather than a truly empty list. Does that still warrant a nudge/hint, or does the normal member-card list (with just one card) suffice?
- **Time Entries chapter with zero entries** — a freshly created project/category with nothing logged yet, shown below the always-visible "Log time" form.

Needs a concrete prototype (via /prototype) for each of these three, consistent with the already-decided happy-path layouts for Home, Members, and Time Entries.

## Answer

All three cases were prototyped together as a throwaway LiveView (`DittoWeb.PrototypeEmptyStatesLive`, route `/prototype/empty-states`, with a toggle for the Members nudge question) and reviewed live. Rather than exploring radically different visual directions, this applied the dashed-placeholder-card idiom already established by the Categories section prototype (ticket 06) consistently to the other two spots, plus resolved the one genuine open question (the Members nudge).

- **Home, zero projects**: the always-inline "Start a new project" form card stays exactly as designed; the "Recent" strip is simply absent (nothing to be recent yet); the projects-list area becomes a dashed placeholder card ("No projects yet — create your first one above.").
- **Members, owner-only**: the normal card-list renders with just the owner's card (badge "Owner") — not treated as a truly empty list. **Decision: show a nudge** — a dashed hint card below the owner's card ("It's just you so far — add a member above to start collaborating."), confirmed on.
- **Time Entries, zero entries**: the always-visible "Log time" form card stays; the table area becomes a dashed placeholder card ("No time logged yet — add your first entry above."), directly below the form.

All three reuse the same dashed-border placeholder-card idiom for visual consistency across the redesign.

The throwaway prototype code (`lib/ditto_web/live/prototype_empty_states_live.ex` and its route) has been deleted.
