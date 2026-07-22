Type: prototype
Status: resolved

## Question

What does the project page's Members section look like — the same section used both right after creating a project (first thing you'd fill in) and later in steady-state (adding/removing members over time)? Per ticket "Invite-member UX": call it "Add member" (not "Invite"), not-found is an inline form error next to the email field, and each member row needs an owner-only remove action with a lightweight inline confirm. Needs a concrete prototype (via /prototype) laying out the add-member form, its error state, and the member list with the remove interaction.

## Answer

Three structurally different, fully interactive variants were prototyped as a throwaway LiveView (`DittoWeb.PrototypeMembersSectionLive`, route `/prototype/members-section`, in-memory fake member list) and reviewed live:

- **A** — conventional table: add-member form as a card above the table, inline error under the email field, remove is a text link per row that swaps to inline "Remove? Yes/No".
- **B** — card list: each member is its own card with an avatar-initial circle (colored circle, first-letter initial) + name/email, remove is an icon button that swaps to a "Remove? Yes/No" footer within the same card, add-member form is a prominent tinted card at the top.
- **C** — compact roster bar: slim pinned add-input (icon + email input + submit arrow), members as tight single-line rows with small initial pills, remove is an "×" that swaps to check/cancel icons inline.

**Winner: Variant B**, confirmed with two follow-ups both defaulted:
1. Avatars stay **initials-only** (colored circle, first letter) — no plan needed for profile photos, matching Ditto's current lack of any avatar/photo field.
2. The remove interaction keeps the **exact "Remove? Yes/No" swap** within the card — explicit and unambiguous, matching the lightweight-inline-confirm decision from the "Invite-member UX" ticket.

Spec for the Members section: a tinted "Add member" card at the top (email input + Add button, inline error text below on validation failure — not-found / already-a-member / empty); below it, one card per member — avatar-initial circle, full name (+ "Owner" badge for the project owner), email — with an owner-only remove icon button that swaps in-place to a "Remove? Yes / No" footer when clicked.

The throwaway prototype code (`lib/ditto_web/live/prototype_members_section_live.ex` and its route) has been deleted.
