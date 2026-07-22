Type: grilling
Status: resolved

## Question

Once inside a project's contextual view, how does the user get back to Home or switch to a different project? Options include: a persistent "back to Home" link plus a project-switcher dropdown embedded in the contextual sidebar itself, vs. requiring a full trip back through Home to change projects, vs. some breadcrumb-style affordance. This decision shapes the contextual sidebar's structure (see ticket 03, which is blocked by this one).

## Answer

Three-part decision, reached via grilling:

1. **The icon-only rail from Home (Home + Settings icons) stays pinned at all times** — entering a project does not hide or replace it. It sits at the far left, constant across Home and every project view, mirroring Livebook's persistent-rail-plus-session-sidebar structure.
2. **No project-switcher dropdown.** Switching projects always means: click the pinned Home icon → land on Home (projects list + Recent strip) → pick the other project. A separate in-context switcher was ruled out as a redundant affordance for a workflow that's already only two clicks away.
3. **The contextual panel shows the current project's name prominently at the top** — for orientation on reload/bookmark/share, since there's no switcher implying "where am I" otherwise.

Net layout: pinned icon-only rail (unchanged from Home) + a second, adjacent contextual panel that swaps per-project, showing the project name at its top followed by its chapters (Members/Categories/Time Entries). "Back to Home" is simply clicking the rail's Home icon, same action from anywhere.
