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

        <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for member <- @members do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium text-gray-900">
                      {if member.name, do: member.name, else: member.username}
                    </p>
                    <p class="text-sm text-gray-500">{member.email}</p>
                    <p class="text-sm text-gray-400 capitalize">Role: {member.role}</p>
                  </div>

                  <%= if @current_scope.user.role == "admin" && @current_scope.user.id != member.id do %>
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
          <.button navigate={~p"/orgs/#{@org.slug}/dashboard"}>
            Back to Dashboard
          </.button>
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
        {:ok, assign(socket, org: org, members: members)}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to view members.")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/dashboard")}
    end
  end

  @impl true
  def handle_event("change_role", %{"id" => user_id, "role" => new_role}, socket) do
    scope = socket.assigns.current_scope
    org = scope.organization

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
