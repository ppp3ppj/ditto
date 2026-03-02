defmodule DittoWeb.ProjectLive.Index do
  use DittoWeb, :live_view

  alias Ditto.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          My Projects
          <:actions>
            <.link navigate={~p"/projects/new"}>
              <.button class="btn btn-primary">New Project</.button>
            </.link>
          </:actions>
        </.header>

        <div :if={@projects == []} class="mt-8 text-center text-gray-500">
          <p>You don't have any projects yet.</p>
          <.link navigate={~p"/projects/new"} class="mt-2 inline-block font-semibold text-brand hover:underline">
            Create your first project →
          </.link>
        </div>

        <div :if={@projects != []} class="mt-6 grid gap-4">
          <div
            :for={entry <- @projects}
            class="rounded-lg border border-gray-200 p-4 hover:border-gray-300 transition-colors"
          >
            <div class="flex items-start justify-between">
              <div>
                <.link navigate={~p"/projects/#{entry.project.id}"} class="text-lg font-semibold hover:underline">
                  <%= entry.project.name %>
                </.link>
                <p :if={entry.project.description} class="mt-1 text-sm text-gray-500">
                  <%= entry.project.description %>
                </p>
              </div>
              <span class={[
                "ml-4 rounded-full px-2 py-0.5 text-xs font-medium",
                entry.role == "owner" && "bg-amber-100 text-amber-800",
                entry.role == "member" && "bg-blue-100 text-blue-800"
              ]}>
                <%= entry.role %>
              </span>
            </div>
            <p class="mt-2 text-xs text-gray-400">
              Joined <%= format_datetime(entry.joined_at) %>
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    projects = Projects.list_user_projects(user)
    {:ok, assign(socket, projects: projects)}
  end

  defp format_datetime(dt) do
    Calendar.strftime(dt, "%b %d, %Y")
  end
end
