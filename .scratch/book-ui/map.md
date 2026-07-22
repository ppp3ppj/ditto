Labels: wayfinder:map

## Destination

A UX/interaction spec — written and raised in fidelity via prototypes — for redesigning Ditto's project workspace in a Livebook-inspired style: an outer Home (persistent nav, projects list) leading into a per-project contextual "chapter" sidebar + main content, covering both project setup (invite members, create categories) and steady-state daily use (browsing members/categories, logging time entries). The deliverable is a spec ready to hand off for implementation, not the implementation itself.

## Notes

- Domain: `Ditto.Projects` (Project, ProjectMember, Category) in `lib/ditto/projects.ex` + `lib/ditto/projects/*.ex`; `Ditto.Tracking.TimeEntry` in `lib/ditto/tracking/time_entry.ex`. All scoped via `Ditto.Accounts.Scope`.
- Current UI: one combined LiveView `DittoWeb.WorkspaceLive.Index` (`lib/ditto_web/live/workspace_live/index.ex`), routed at `/workspace/*`, with a persistent sidebar + section-swapping content — this is what's being replaced.
- Reference: `.reference/livebook` has two sidebar patterns — persistent global nav (`lib/livebook_web/components/layouts.ex` `layout/1` + `sidebar/1`) and contextual per-session sidebar (`lib/livebook_web/live/session_live.ex` + `session_live/render.ex`). This effort chases the persistent pattern for the outer Home and the contextual pattern for the per-project view.
- Existing invite backend: `Projects.invite_project_member/3` is owner-only and looks up the invitee by email via `Accounts.get_user_by_email/1` — it requires the invitee to already be a Ditto user. UX for the not-found/pending/resend/revoke cases is undecided (see ticket 04).
- Ditto's UI conventions to fit within: `lib/ditto_web/components/layouts.ex` (`Layouts.app/1`), `lib/ditto_web/components/core_components.ex`, Tailwind + daisyUI (`card`, `menu`, `btn`, `table table-zebra`), Remix Icon classes. Stay within this system — no new visual language (locked decision).
- Skills to use while resolving tickets: `/prototype` for HITL fidelity-raising tickets, `/grilling` for interaction-detail decisions, `/domain-modeling` if terminology needs pinning.
- Settings, reached via the rail's Settings icon, is just the existing `/users/settings` route (`UserLive.Settings`) — no new settings page is in scope; this was fog, now resolved as a fact rather than a ticket.
- Error-state treatment (failed saves, etc.) reuses Ditto's existing flash-message convention (`Layouts.flash_group`, `put_flash` already used throughout `WorkspaceLive.Index`) — no new ticket needed; this was fog, now resolved as a fact rather than a ticket.

## Decisions so far

- [Home page prototype](issues/01-home-page-prototype.md) — icon-only left rail (Home/Settings, no labels) + main pane: "Recent" strip, always-inline "Start a new project" form (no button/modal), then full projects list as cards.
- [Navigation/switching model](issues/02-navigation-switching-model.md) — pinned icon-only rail stays constant everywhere; no project-switcher, switching projects goes through Home; contextual panel shows the project name at top.
- [Contextual sidebar prototype](issues/03-contextual-sidebar-prototype.md) — collapsible-cards layout: compact project-name header + collapse toggle, one card per chapter (Members/Categories/Time Entries) with icon + label + lightweight count badge.
- [Invite-member UX](issues/04-invite-member-ux.md) — call it "Add member" (immediate membership, no invite/accept step); not-found is an inline form error; remove is owner-only with a lightweight inline confirm.
- [Members section prototype](issues/05-members-section-prototype.md) — card-list layout: tinted add-member card at top, one card per member with an initials avatar, owner-only remove icon that swaps in-place to "Remove? Yes/No".
- [Categories section prototype](issues/06-categories-section-prototype.md) — card-list layout mirroring Members: tinted add-category card, pencil-to-edit (Save/Cancel form) and trash-to-"Remove? Yes/No" per card, dashed empty-state card.
- [Time-entries table restyle](issues/07-time-entries-table-restyle.md) — flat reverse-chronological table, no grouping/filtering, add-entry form card above; Duration column shows both friendly format and raw minutes.
- [Routing/LiveView architecture](issues/08-routing-architecture.md) — separate `HomeLive`; single `ProjectLive.Show` with `live_action` per chapter; shared `Layouts.app_with_rail/1` component for the pinned rail.
- [Empty-state treatments](issues/09-empty-state-treatments.md) — dashed-placeholder-card idiom applied to zero-projects Home and zero-entries Time Entries; Members-owner-only shows a nudge card to add someone.

## Not yet specified

(none remaining — the last two patches graduated into tickets 08 and 09 below; settings and error-state fog resolved as facts, see Notes)

## Out of scope

- A strict linear step-by-step project-creation wizard — ruled out; setup is non-linear, revisitable "chapters" on the project's own page instead.
- A distinct visual identity (new typography/color system) for the "book" feel — ruled out; must stay within the existing daisyUI/Tailwind system.
- Redesigning the time-entry table into a document/stacked-page ("book") metaphor — ruled out; it stays a conventional table/form, just re-hosted in the new layout.
