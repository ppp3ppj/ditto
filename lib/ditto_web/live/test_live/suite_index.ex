defmodule DittoWeb.TestLive.SuiteIndex do
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
          <span class="text-gray-800 font-medium">Test Suites</span>
        </nav>

        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">Test Suites</h1>
          <.link navigate={~p"/projects/#{@project.id}/runs"} class="btn btn-sm btn-outline">
            Test Runs →
          </.link>
        </div>

        <%!-- Suite list --%>
        <div :if={@suites == []} class="rounded-lg border border-dashed border-gray-300 p-8 text-center text-gray-500">
          No test suites yet. Create one below.
        </div>

        <div :if={@suites != []} class="divide-y divide-gray-100 rounded-lg border border-gray-200">
          <div :for={entry <- @suites} class="flex items-center justify-between px-4 py-3">
            <div>
              <.link navigate={~p"/projects/#{@project.id}/suites/#{entry.suite.id}"} class="font-medium hover:underline">
                <%= entry.suite.name %>
              </.link>
              <p :if={entry.suite.description} class="text-sm text-gray-500"><%= entry.suite.description %></p>
              <p class="text-xs text-gray-400 mt-0.5">
                <%= entry.scenario_count %> scenario<%= if entry.scenario_count != 1, do: "s" %> ·
                <%= entry.case_count %> case<%= if entry.case_count != 1, do: "s" %>
              </p>
            </div>
            <.button
              phx-click="delete_suite"
              phx-value-id={entry.suite.id}
              data-confirm={"Delete \"#{entry.suite.name}\"? All scenarios and cases will be removed."}
              class="btn btn-xs btn-error btn-outline"
            >
              Delete
            </.button>
          </div>
        </div>

        <%!-- Add Suite form --%>
        <section class="rounded-lg border border-gray-200 p-4">
          <h2 class="text-sm font-semibold text-gray-700 mb-3">Add Suite</h2>
          <.form for={@form} id="suite_form" phx-submit="create_suite" phx-change="validate" class="space-y-3">
            <.input field={@form[:name]} type="text" label="Suite name" placeholder="e.g. Authentication" required />
            <.input field={@form[:description]} type="textarea" label="Description (optional)" rows="2" />
            <.button phx-disable-with="Creating..." class="btn btn-primary btn-sm">
              Create Suite
            </.button>
          </.form>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    suites = load_suites(project)

    {:ok,
     socket
     |> assign(project: project, suites: suites)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"suite" => params}, socket) do
    changeset = Testing.change_suite(%Ditto.Testing.Suite{}, params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "suite"))}
  end

  def handle_event("create_suite", %{"suite" => params}, socket) do
    case Testing.create_suite(socket.assigns.project, params) do
      {:ok, _suite} ->
        suites = load_suites(socket.assigns.project)

        {:noreply,
         socket
         |> put_flash(:info, "Suite created.")
         |> assign(suites: suites)
         |> assign_form()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "suite"))}
    end
  end

  def handle_event("delete_suite", %{"id" => id}, socket) do
    suite = Testing.get_suite!(id)
    {:ok, _} = Testing.delete_suite(suite)
    suites = load_suites(socket.assigns.project)

    {:noreply,
     socket
     |> put_flash(:info, "Suite deleted.")
     |> assign(suites: suites)}
  end

  defp assign_form(socket) do
    assign(socket, form: to_form(Testing.change_suite(), as: "suite"))
  end

  defp load_suites(project) do
    suites = Testing.list_suites(project)

    Enum.map(suites, fn suite ->
      scenarios = Testing.list_scenarios(suite)
      scenario_count = length(scenarios)
      case_count = Enum.sum(Enum.map(scenarios, fn sc -> length(Testing.list_cases(sc)) end))
      %{suite: suite, scenario_count: scenario_count, case_count: case_count}
    end)
  end
end
