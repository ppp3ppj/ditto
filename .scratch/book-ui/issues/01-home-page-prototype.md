Type: prototype
Status: resolved

## Question

What does the outer Home page look like and contain? This is the persistent-nav-style landing page a user sees before entering any specific project — analogous to Livebook's Home. Needs a concrete prototype (via /prototype) to react to, covering: what the persistent nav shows (just "Home"? account/settings links?), how the projects list itself is presented (cards? table? something book-shelf-like?), and where/how "create a new project" is triggered from here.

## Answer

Three structurally different variants were prototyped as a throwaway LiveView (`DittoWeb.PrototypeHomeLive`, route `/prototype/home`) and reviewed live:

- **A** — no persistent sidebar; Home is a slim top bar (brand + settings + user badge) over a bookshelf-style grid of project tiles, "New project" as one more tile.
- **B** — closest to Livebook's literal shape: full persistent left sidebar (logo, Home, Settings) + main pane with a "New project" button above a conventional table.
- **C** — icon-only slim sidebar rail (no text labels) + main pane split into a "Recent" horizontal card strip, an always-visible inline "Start a new project" form (no button/modal gate), and the full projects list below as cards.

**Winner: Variant C**, confirmed as-is (icon-only sidebar, always-inline create form — no changes requested). Rationale: the icon-only rail keeps navigation minimal/out of the way; the inline create-form gives zero-click entry into starting a project, matching the "just start writing" immediacy Livebook has for new notebooks, rather than gating creation behind a button/modal; the "Recent" strip gives quick re-entry without an extra click.

Spec for Home: icon-only left rail (Home + Settings icons, tooltips for discoverability — no text labels); main pane, top to bottom: "Recent" horizontal strip of up to 3 recently-touched projects as compact cards, an always-visible inline project-name input + Create button (no modal), then the full projects list as cards (name, member count, category count), each navigating into that project's contextual view.

The throwaway prototype code (`lib/ditto_web/live/prototype_home_live.ex` and its route) has been deleted — this answer is the durable artifact; building the real Home LiveView is implementation work for later, outside this map's destination.
