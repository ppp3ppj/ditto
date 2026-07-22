Type: grilling
Status: resolved

## Question

Now that Home, the pinned rail, the contextual chapter panel, and all three chapters (Members/Categories/Time Entries) have decided shapes, how should routes and LiveViews be structured to implement them? Ditto currently has one combined LiveView (`DittoWeb.WorkspaceLive.Index`) handling all sections via `live_action` + a `section` assign, routed under `/workspace/*`.

Options to weigh:
- Keep a single combined LiveView per project (like today), with the three chapters as `live_action`-based sub-routes or an internal `@chapter` assign, plus a separate Home LiveView.
- Split each chapter into its own LiveView (`ProjectLive.Members`, `ProjectLive.Categories`, `ProjectLive.TimeEntries`), sharing a layout/function-component for the pinned rail + contextual panel chrome.
- Some hybrid (e.g. one LiveView per project handling routing/data-loading, delegating chapter rendering to function components or LiveComponents).

This decision doesn't need to happen via a prototype — it's a backend/architecture call, not a visual one — but it does determine how cleanly the six already-decided chapter designs (Home, sidebar, Members, Categories, Time Entries) can be implemented. Note: implementing the routes/LiveViews themselves is beyond this map's destination (a spec, not the code) — the answer here is the *recommended structure*, to be handed off alongside the visual spec.

## Answer

Three decisions, reached via grilling:

1. **A separate `HomeLive`** (distinct from the project view). Home and the project view have fundamentally different data shapes (all-projects list vs. one project's members/categories/time-entries) and different URLs. Splitting them avoids recreating `WorkspaceLive.Index`'s current problem — one 450+-line module handling four unrelated concerns via a `section` assign.
2. **A single project LiveView** (e.g. `DittoWeb.ProjectLive.Show`) handling all three chapters via `live_action` + a `@chapter` assign — mirroring today's `WorkspaceLive.Index` pattern, but scoped to one project's three *related* chapters (shared root data: the current project, loaded once) rather than four unrelated domains. Simpler than three separate chapter modules each duplicating project-loading and chrome-wiring.
3. **A shared function component for the pinned rail** (e.g. `DittoWeb.Layouts.app_with_rail/1`, alongside the existing `Layouts.app/1`), used by both `HomeLive` and the project LiveView — the rail is pixel-identical across both (same two icons, same active-state logic), so it should live in one place. The contextual chapter panel itself stays specific to the project LiveView; only the rail is shared.

Net recommended structure to hand off: `DittoWeb.HomeLive` (route `/` or `/home`) + `DittoWeb.ProjectLive.Show` (routes `/projects/:id`, `/projects/:id/members`, `/projects/:id/categories`, `/projects/:id/time-entries`, one module, `live_action`-per-chapter) + a new shared `Layouts.app_with_rail/1` component wrapping both. Building this is implementation work outside this map's destination — this ticket's output is the structural recommendation, not the code.
