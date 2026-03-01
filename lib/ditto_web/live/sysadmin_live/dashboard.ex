defmodule DittoWeb.SysadminLive.Dashboard do
  use DittoWeb, :live_view

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          System Administration
          <:subtitle>Cross-organization management</:subtitle>
          <:actions>
            <.button navigate={~p"/sysadmin/organizations"}>
              All Organizations
            </.button>
          </:actions>
        </.header>

        <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div class="bg-white overflow-hidden shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900">Organizations</h3>
            <p class="mt-2 text-3xl font-bold text-gray-900">{@org_count}</p>
            <p class="text-sm text-gray-500">Total organizations</p>
            <div class="mt-4">
              <.button navigate={~p"/sysadmin/organizations"}>
                Manage Organizations
              </.button>
            </div>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900">Logged In As</h3>
            <dl class="mt-2 space-y-1">
              <div>
                <dt class="text-sm text-gray-500">Email</dt>
                <dd class="text-sm font-medium">{@current_scope.user.email}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Username</dt>
                <dd class="text-sm font-medium">@{@current_scope.user.username}</dd>
              </div>
            </dl>
            <p class="mt-3 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
              System Administrator
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    orgs = Accounts.list_organizations(scope)

    org_count =
      case orgs do
        list when is_list(list) -> length(list)
        _ -> 0
      end

    {:ok, assign(socket, org_count: org_count)}
  end
end
