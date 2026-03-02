defmodule DittoWeb.TestLive.RunIndex do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Testing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl space-y-6">
        <%!-- Breadcrumb --%>
        <nav class="text-sm text-gray-500 flex gap-1 items-center">
          <.link navigate={~p"/projects"} class="hover:underline">Projects</.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}"} class="hover:underline"><%= @project.name %></.link>
          <span>/</span>
          <span class="text-gray-800 font-medium">Test Runs</span>
        </nav>

        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">Test Runs</h1>
          <div class="flex gap-2">
            <.link navigate={~p"/projects/#{@project.id}/suites"} class="btn btn-sm btn-outline">
              ← Test Suites
            </.link>
            <.link navigate={~p"/projects/#{@project.id}/runs/new"} class="btn btn-sm btn-primary">
              New Run
            </.link>
          </div>
        </div>

        <div :if={@runs == []} class="rounded-lg border border-dashed border-gray-300 p-8 text-center text-gray-500">
          No test runs yet.
          <.link navigate={~p"/projects/#{@project.id}/runs/new"} class="underline ml-1">Create one</.link>.
        </div>

        <div :if={@runs != []} class="divide-y divide-gray-100 rounded-lg border border-gray-200">
          <div :for={entry <- @runs} class="flex items-center justify-between px-4 py-3">
            <div class="flex-1 min-w-0">
              <.link navigate={~p"/projects/#{@project.id}/runs/#{entry.run.id}"} class="font-medium hover:underline">
                <%= entry.run.name %>
              </.link>
              <div class="flex items-center gap-3 mt-1 text-xs text-gray-500">
                <span class={[
                  "rounded-full px-2 py-0.5 font-medium",
                  entry.run.status == "pending" && "bg-gray-100 text-gray-600",
                  entry.run.status == "in_progress" && "bg-blue-100 text-blue-700",
                  entry.run.status == "completed" && "bg-green-100 text-green-700"
                ]}>
                  <%= entry.run.status %>
                </span>
                <span>
                  <%= entry.progress.pass %>✓
                  <%= entry.progress.fail %>✗
                  <%= entry.progress.skip %>⊘
                  <%= entry.progress.pending %> pending
                  / <%= entry.progress.total %> total
                </span>
              </div>
            </div>
            <.button
              phx-click="delete_run"
              phx-value-id={entry.run.id}
              data-confirm={"Delete run \"#{entry.run.name}\"? All results will be lost."}
              class="btn btn-xs btn-error btn-outline shrink-0"
            >
              Delete
            </.button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    runs = load_runs(project)

    {:ok, assign(socket, project: project, runs: runs)}
  end

  @impl true
  def handle_event("delete_run", %{"id" => id}, socket) do
    run = Testing.get_run!(id)
    {:ok, _} = Testing.delete_run(run)
    runs = load_runs(socket.assigns.project)

    {:noreply,
     socket
     |> put_flash(:info, "Run deleted.")
     |> assign(runs: runs)}
  end

  defp load_runs(project) do
    runs = Testing.list_runs(project)

    Enum.map(runs, fn run ->
      progress = Testing.run_progress(run)
      %{run: run, progress: progress}
    end)
  end
end
