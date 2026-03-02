defmodule DittoWeb.OrgLive.Members do
  use DittoWeb, :live_view

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          Team Members
          <:subtitle>{@org.name}</:subtitle>
        </.header>

        <%!-- Add Member (admin / sysadmin only) --%>
        <%= if @current_scope.user.role == "admin" || @current_scope.user.is_sysadmin do %>
          <div class="mt-6 card bg-base-200 shadow-sm">
            <div class="card-body">
              <h2 class="card-title text-base">Add Member</h2>
              <p class="text-sm text-base-content/60 mb-3">
                Search by username or email. Only users not yet in any organization will appear.
              </p>
              <input
                type="text"
                class="input input-bordered w-full"
                placeholder="username or email..."
                phx-keyup="search_users"
                phx-debounce="300"
                value={@search_query}
              />

              <%= if @search_results != [] do %>
                <ul class="mt-2 border border-base-300 rounded-lg divide-y divide-base-300 bg-base-100">
                  <%= for user <- @search_results do %>
                    <li class="flex items-center justify-between px-4 py-3">
                      <div>
                        <p class="font-medium">
                          @{user.username}{if user.name, do: " · #{user.name}"}
                        </p>
                        <p class="text-sm text-base-content/60">{user.email}</p>
                      </div>
                      <.button
                        phx-click="add_member"
                        phx-value-id={user.id}
                        phx-disable-with="Adding..."
                        variant="primary"
                      >
                        Add to org
                      </.button>
                    </li>
                  <% end %>
                </ul>
              <% end %>

              <%= if @search_query != "" && @search_results == [] do %>
                <p class="mt-2 text-sm text-base-content/50">
                  No users found without an organization.
                </p>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="mt-6 bg-base-100 shadow overflow-hidden rounded-lg">
          <ul role="list" class="divide-y divide-base-300">
            <%= for member <- @members do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium">
                      {if member.name, do: member.name, else: member.username}
                    </p>
                    <p class="text-sm text-base-content/60">
                      @{member.username} · {member.email}
                    </p>
                    <span class="badge badge-neutral badge-sm capitalize mt-1">{member.role}</span>
                  </div>

                  <%= if (@current_scope.user.role == "admin" || @current_scope.user.is_sysadmin) && @current_scope.user.id != member.id do %>
                    <div class="flex items-center space-x-2">
                      <.button
                        phx-click="change_role"
                        phx-value-id={member.id}
                        phx-value-role={next_role(member.role)}
                      >
                        Make {next_role_label(member.role)}
                      </.button>
                    </div>
                  <% end %>
                </div>
              </li>
            <% end %>
          </ul>
        </div>

        <div class="mt-4">
          <.link navigate={~p"/orgs/#{@org.slug}/dashboard"} class="btn">
            Back to Dashboard
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    org = scope.organization

    case Accounts.list_org_users(scope) do
      {:ok, members} ->
        {:ok, assign(socket, org: org, members: members, search_query: "", search_results: [])}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to view members.")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/dashboard")}
    end
  end

  @impl true
  def handle_event("search_users", %{"value" => query}, socket) do
    results = Accounts.search_users_without_org(query)
    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  def handle_event("add_member", %{"id" => user_id}, socket) do
    scope = socket.assigns.current_scope
    user_to_add = Accounts.get_user!(user_id)

    case Accounts.add_member_to_org(scope, user_to_add.username) do
      {:ok, _user} ->
        {:ok, members} = Accounts.list_org_users(scope)

        {:noreply,
         socket
         |> put_flash(:info, "@#{user_to_add.username} has been added to the organization.")
         |> assign(members: members, search_query: "", search_results: [])}

      {:error, :user_not_found} ->
        {:noreply, put_flash(socket, :error, "User not found.")}

      {:error, :already_in_org} ->
        {:noreply, put_flash(socket, :error, "This user already belongs to an organization.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to add members.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add member.")}
    end
  end

  def handle_event("change_role", %{"id" => user_id, "role" => new_role}, socket) do
    scope = socket.assigns.current_scope
    target_user = Accounts.get_user!(user_id)

    case Accounts.update_user_role(scope, target_user, new_role) do
      {:ok, _updated_user} ->
        {:ok, members} = Accounts.list_org_users(scope)

        {:noreply,
         socket
         |> put_flash(:info, "Role updated successfully.")
         |> assign(members: members)}

      {:error, :last_admin} ->
        {:noreply, put_flash(socket, :error, "Cannot remove the last admin from the organization.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update role.")}
    end
  end

  defp next_role("admin"), do: "manager"
  defp next_role("manager"), do: "member"
  defp next_role("member"), do: "admin"

  defp next_role_label("admin"), do: "Manager"
  defp next_role_label("manager"), do: "Member"
  defp next_role_label("member"), do: "Admin"
end
