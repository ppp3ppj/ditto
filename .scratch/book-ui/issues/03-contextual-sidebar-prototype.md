Type: prototype
Status: resolved

## Question

What does the per-project contextual "chapter" panel look like once you're inside a project — sitting alongside the pinned icon-only rail (Home/Settings) decided in ticket "Navigation/switching model"? Per that decision: the rail never disappears, there's no project-switcher (switching goes through Home), and the panel must show the current project's name prominently at the top. Needs a concrete prototype (via /prototype) covering: the project-name header treatment, what chapters/sections it lists below it (Members, Categories, Time Entries — order and icons), and any collapse/responsive behavior.

## Answer

Three structurally different variants were prototyped as a throwaway LiveView (`DittoWeb.PrototypeProjectSidebarLive`, route `/prototype/project-sidebar`, rendered next to a static placeholder rail for context) and reviewed live:

- **A** — plain menu: project name as a simple heading, chapters as a standard daisyUI `menu` list (icon + label + count badge). Closest to Ditto's current sidebar, just re-scoped to one project.
- **B** — book-cover / table-of-contents: project name gets a cover-page treatment (tinted header block, "Project" eyebrow label), chapters listed as a numbered TOC with dotted leader lines, no icons.
- **C** — collapsible cards: compact header (project name + collapse-toggle button), each chapter rendered as its own small card (icon + label + count badge) rather than a menu row, collapsible to icon-only alongside the rail on narrow screens.

**Winner: Variant C**, confirmed with two follow-ups both defaulted to the lightweight option:
1. Chapter cards keep lightweight count badges (e.g. "Members — 3") rather than richer previews (avatar stacks, last-edited snippets) — richer previews can be layered in later without changing the card shape.
2. The collapse toggle is kept — the panel can fold to icon-only, nested next to the rail, for narrow screens or when more room is wanted for main content.

Spec for the contextual panel: compact header row (project name, truncated if long, + collapse-toggle button on the right) at the top; below it, one card per chapter (Members, Categories, Time Entries, in that order) — each card is icon + label + lightweight count badge, no menu-row styling; collapses to icon-only width matching the rail's icon column when toggled.

The throwaway prototype code (`lib/ditto_web/live/prototype_project_sidebar_live.ex` and its route) has been deleted.
