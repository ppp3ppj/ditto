defmodule DittoWeb.ProjectLive.Show do
  use DittoWeb, :live_view

  alias Ditto.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl space-y-8">
        <%!-- Header --%>
        <div class="flex items-start justify-between">
          <div>
            <.link navigate={~p"/projects"} class="text-sm text-gray-500 hover:underline">
              ← All projects
            </.link>
            <div :if={!@editing} class="mt-1">
              <h1 class="text-2xl font-bold"><%= @project.name %></h1>
              <p :if={@project.description} class="mt-1 text-gray-500"><%= @project.description %></p>
            </div>
            <div :if={@editing} class="mt-2">
              <.form for={@form} id="project_edit_form" phx-submit="update" phx-change="validate_update" class="space-y-3">
                <.input field={@form[:name]} type="text" label="Project name" required />
                <.input field={@form[:description]} type="textarea" label="Description" rows="2" />
                <div class="flex gap-2">
                  <.button phx-disable-with="Saving..." class="btn btn-primary btn-sm">Save</.button>
                  <.button type="button" phx-click="cancel_edit" class="btn btn-sm">Cancel</.button>
                </div>
              </.form>
            </div>
          </div>
          <div :if={@is_owner && !@editing} class="flex gap-2">
            <.button phx-click="edit" class="btn btn-sm">Edit</.button>
            <.button
              phx-click="delete_project"
              data-confirm={"Delete \"#{@project.name}\"? This cannot be undone."}
              class="btn btn-sm btn-error"
            >
              Delete
            </.button>
          </div>
        </div>

        <%!-- Members --%>
        <section>
          <h2 class="text-lg font-semibold">Members (<%= length(@members) %>)</h2>
          <div class="mt-3 divide-y divide-gray-100 rounded-lg border border-gray-200">
            <div :for={entry <- @members} class="flex items-center justify-between px-4 py-3">
              <div>
                <span class="font-medium"><%= entry.user.username %></span>
                <span :if={entry.user.name} class="ml-1 text-sm text-gray-500">(<%= entry.user.name %>)</span>
              </div>
              <div class="flex items-center gap-3">
                <span class={[
                  "rounded-full px-2 py-0.5 text-xs font-medium",
                  entry.role == "owner" && "bg-amber-100 text-amber-800",
                  entry.role == "member" && "bg-blue-100 text-blue-800"
                ]}>
                  <%= entry.role %>
                </span>
                <.button
                  :if={@is_owner && entry.user.id != @current_scope.user.id}
                  phx-click="remove_member"
                  phx-value-user-id={entry.user.id}
                  data-confirm={"Remove #{entry.user.username} from this project?"}
                  class="btn btn-xs btn-error btn-outline"
                >
                  Remove
                </.button>
              </div>
            </div>
          </div>
        </section>

        <%!-- Invite Links --%>
        <section>
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Invite Links</h2>
            <.button phx-click="toggle_invite_form" class="btn btn-sm btn-primary">
              <%= if @show_invite_form, do: "Cancel", else: "Create invite link" %>
            </.button>
          </div>

          <div :if={@show_invite_form} class="mt-3 rounded-lg border border-gray-200 p-4">
            <.form for={@invite_form} id="invite_form" phx-submit="create_invite" class="space-y-3">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Expires after</label>
                  <select name="invite[expires_in_hours]" class="select select-bordered w-full mt-1">
                    <option value="">Never</option>
                    <option value="1">1 hour</option>
                    <option value="24">24 hours</option>
                    <option value="168">7 days</option>
                    <option value="720">30 days</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Max uses</label>
                  <select name="invite[max_uses]" class="select select-bordered w-full mt-1">
                    <option value="0">Unlimited</option>
                    <option value="1">1 use</option>
                    <option value="5">5 uses</option>
                    <option value="10">10 uses</option>
                    <option value="25">25 uses</option>
                    <option value="100">100 uses</option>
                  </select>
                </div>
              </div>
              <.button phx-disable-with="Creating..." class="btn btn-primary btn-sm w-full">
                Generate Link
              </.button>
            </.form>
          </div>

          <div :if={@invitations == []} class="mt-3 text-sm text-gray-500">
            No invite links yet.
          </div>

          <div :if={@invitations != []} class="mt-3 divide-y divide-gray-100 rounded-lg border border-gray-200">
            <div :for={inv <- @invitations} class="px-4 py-3">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-2">
                    <code class="rounded bg-gray-100 px-2 py-0.5 text-xs font-mono truncate max-w-xs">
                      <%= invite_url(inv.token) %>
                    </code>
                    <.button
                      phx-click={JS.dispatch("phx:copy", detail: %{text: invite_url(inv.token)})}
                      class="btn btn-xs"
                      title="Copy link"
                    >
                      Copy
                    </.button>
                  </div>
                  <div class="mt-1 flex gap-4 text-xs text-gray-500">
                    <span>
                      <%= if inv.expires_at do %>
                        Expires <%= format_datetime(inv.expires_at) %>
                      <% else %>
                        Never expires
                      <% end %>
                    </span>
                    <span>
                      <%= if inv.max_uses do %>
                        <%= inv.uses_count %>/<%= inv.max_uses %> uses
                      <% else %>
                        <%= inv.uses_count %> uses (unlimited)
                      <% end %>
                    </span>
                  </div>
                </div>
                <.button
                  :if={@is_owner}
                  phx-click="delete_invite"
                  phx-value-id={inv.id}
                  data-confirm="Delete this invite link?"
                  class="btn btn-xs btn-error btn-outline shrink-0"
                >
                  Delete
                </.button>
              </div>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user

    project = Projects.get_project_for_member!(user, id)
    members = Projects.list_members(project)
    invitations = Projects.list_invitations(project)
    membership = Projects.get_member(project, user)
    is_owner = membership && membership.role == "owner"

    {:ok,
     socket
     |> assign(
       project: project,
       members: members,
       invitations: invitations,
       is_owner: is_owner,
       editing: false,
       show_invite_form: false
     )
     |> assign_edit_form(project)
     |> assign(invite_form: to_form(%{}, as: "invite"))}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false) |> assign_edit_form(socket.assigns.project)}
  end

  def handle_event("validate_update", %{"project" => params}, socket) do
    changeset = Projects.change_project(socket.assigns.project, params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "project"))}
  end

  def handle_event("update", %{"project" => params}, socket) do
    case Projects.update_project(socket.assigns.project, params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated.")
         |> assign(project: project, editing: false)
         |> assign_edit_form(project)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "project"))}
    end
  end

  def handle_event("delete_project", _params, socket) do
    {:ok, _} = Projects.delete_project(socket.assigns.project)

    {:noreply,
     socket
     |> put_flash(:info, "Project deleted.")
     |> push_navigate(to: ~p"/projects")}
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    case Projects.remove_member(socket.assigns.project, user_id) do
      {:ok, _} ->
        members = Projects.list_members(socket.assigns.project)
        {:noreply, assign(socket, members: members)}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot remove the project owner.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Member not found.")}
    end
  end

  def handle_event("toggle_invite_form", _params, socket) do
    {:noreply, assign(socket, show_invite_form: !socket.assigns.show_invite_form)}
  end

  def handle_event("create_invite", %{"invite" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Projects.create_invitation(socket.assigns.project, user, params) do
      {:ok, _inv} ->
        invitations = Projects.list_invitations(socket.assigns.project)

        {:noreply,
         socket
         |> put_flash(:info, "Invite link created!")
         |> assign(invitations: invitations, show_invite_form: false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create invite link.")}
    end
  end

  def handle_event("delete_invite", %{"id" => id}, socket) do
    if Enum.any?(socket.assigns.invitations, &(&1.id == id)) do
      Projects.delete_invitation_by_id(id)
      invitations = Projects.list_invitations(socket.assigns.project)
      {:noreply, assign(socket, invitations: invitations)}
    else
      {:noreply, socket}
    end
  end

  defp assign_edit_form(socket, project) do
    changeset = Projects.change_project(project)
    assign(socket, form: to_form(changeset, as: "project"))
  end

  defp invite_url(token) do
    DittoWeb.Endpoint.url() <> ~p"/projects/join/#{token}"
  end

  defp format_datetime(dt) do
    Calendar.strftime(dt, "%b %d, %Y %H:%M")
  end
end
