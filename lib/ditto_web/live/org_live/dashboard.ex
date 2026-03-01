defmodule DittoWeb.OrgLive.Dashboard do
  use DittoWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          {@org.name}
          <:subtitle>Organization dashboard</:subtitle>
          <:actions>
            <%= if @current_scope.user.role == "admin" do %>
              <.button navigate={~p"/orgs/#{@org.slug}/settings"}>
                Settings
              </.button>
            <% end %>
          </:actions>
        </.header>

        <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div class="bg-white overflow-hidden shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900">Organization</h3>
            <dl class="mt-4 space-y-2">
              <div>
                <dt class="text-sm text-gray-500">Name</dt>
                <dd class="text-sm font-medium text-gray-900">{@org.name}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Slug</dt>
                <dd class="text-sm font-medium text-gray-900">{@org.slug}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Status</dt>
                <dd class="text-sm font-medium text-gray-900">
                  {if @org.active, do: "Active", else: "Inactive"}
                </dd>
              </div>
            </dl>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900">Your Account</h3>
            <dl class="mt-4 space-y-2">
              <div>
                <dt class="text-sm text-gray-500">Email</dt>
                <dd class="text-sm font-medium text-gray-900">{@current_scope.user.email}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Username</dt>
                <dd class="text-sm font-medium text-gray-900">@{@current_scope.user.username}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Role</dt>
                <dd class="text-sm font-medium text-gray-900 capitalize">{@current_scope.user.role}</dd>
              </div>
            </dl>
          </div>
        </div>

        <div class="mt-6">
          <.button navigate={~p"/orgs/#{@org.slug}/members"}>
            View Team Members
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_scope.organization
    {:ok, assign(socket, org: org)}
  end
end
