defmodule DittoWeb.SysadminLive.Organizations do
  use DittoWeb, :live_view

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          All Organizations
          <:subtitle>System-wide organization management</:subtitle>
          <:actions>
            <.button navigate={~p"/sysadmin"}>Back to Dashboard</.button>
          </:actions>
        </.header>

        <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for org <- @organizations do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium text-gray-900">{org.name}</p>
                    <p class="text-sm text-gray-500">/{org.slug}</p>
                    <p class="text-sm text-gray-400">
                      Status: {if org.active, do: "Active", else: "Inactive"}
                    </p>
                  </div>
                  <div class="flex items-center space-x-2">
                    <.button navigate={~p"/orgs/#{org.slug}/dashboard"}>
                      View Org
                    </.button>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>

          <%= if @organizations == [] do %>
            <div class="px-4 py-8 text-center text-gray-500">
              No organizations yet.
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    organizations =
      case Accounts.list_organizations(scope) do
        list when is_list(list) -> list
        _ -> []
      end

    {:ok, assign(socket, organizations: organizations)}
  end
end
