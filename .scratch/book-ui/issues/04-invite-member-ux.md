Type: grilling
Status: resolved

## Question

`Projects.invite_project_member/3` (`lib/ditto/projects.ex`) is owner-only and looks up the invitee by email via `Accounts.get_user_by_email/1` — it requires the invitee to already have a Ditto account. What should the UX be for: the invitee-not-found case (error message? offer some other path?), a pending/accepted invite state (is there one today, or is membership immediate on invite?), and resend/revoke actions. This decision feeds the Members section prototype (ticket 05, blocked by this one).

## Answer

Facts confirmed by reading `lib/ditto/projects.ex`: `invite_project_member/3` is owner-only, requires the invitee to already have a Ditto account (looked up by email), and creates membership **immediately** — there is no pending/accepted state, no status field on `ProjectMember`, and no resend/revoke concept beyond the generic `delete_project_member/1`.

Three decisions, reached via grilling:

1. **Call it "Add member," not "Invite."** The UI should describe the product as it actually behaves — one-step, immediate membership — rather than implying an accept/decline step that doesn't exist. A future real invite/pending flow would be a backend change deserving its own naming decision then, not something to pre-hedge for in this spec.
2. **Not-found case is an inline form error** next to the email field (e.g. "No Ditto account found for this email") — not a flash/toast, not a modal, and no "send anyway" branch, since that would imply a pending state that doesn't exist. It's a plain validation failure on the add-member form.
3. **Removing a member is owner-only** (mirrors the add restriction — only the owner manages membership) and uses a **lightweight inline confirm** (confirm-on-click / "Remove? Yes/No" swap, not a full modal) — destructive and immediate, but not catastrophic enough to warrant a heavy interruption.

Net spec for the Members section: an "Add member" form (email input, owner-only, inline validation error on not-found) plus a member list where each row shows an owner-only remove action with an inline confirm swap.
