defmodule DittoWeb.TestLive.RunNew do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Testing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl space-y-6">
        <%!-- Breadcrumb --%>
        <nav class="text-sm text-gray-500 flex gap-1 items-center">
          <.link navigate={~p"/projects"} class="hover:underline">Projects</.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}"} class="hover:underline"><%= @project.name %></.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}/runs"} class="hover:underline">Test Runs</.link>
          <span>/</span>
          <span class="text-gray-800 font-medium">New Run</span>
        </nav>

        <h1 class="text-2xl font-bold">New Test Run</h1>

        <div class="space-y-6">
          <%!-- Run name (standalone input, not inside the form to avoid mixing phx-change events) --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Run name <span class="text-red-500">*</span>
            </label>
            <input
              type="text"
              id="run_name_input"
              value={@run_name}
              phx-keyup="update_name"
              placeholder="e.g. Sprint 12 regression"
              class="input input-bordered w-full"
            />
          </div>

          <%!-- Suite/Scenario picker --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Select suites or scenarios to include
            </label>

            <div :if={@suite_tree == []} class="rounded-lg border border-dashed border-gray-300 p-6 text-center text-gray-500 text-sm">
              No test suites found.
              <.link navigate={~p"/projects/#{@project.id}/suites"} class="underline">Create some first</.link>.
            </div>

            <div :if={@suite_tree != []} class="rounded-lg border border-gray-200 divide-y divide-gray-100">
              <div :for={entry <- @suite_tree} class="p-3">
                <%!-- Suite row: click anywhere on it to toggle --%>
                <button
                  type="button"
                  phx-click="toggle_suite"
                  phx-value-suite-id={entry.suite.id}
                  class="flex items-center gap-2 font-medium w-full text-left"
                >
                  <input
                    type="checkbox"
                    checked={entry.suite.id in @selected_suite_ids}
                    class="checkbox checkbox-sm pointer-events-none"
                    readonly
                  />
                  <span><%= entry.suite.name %></span>
                  <span class="text-xs text-gray-400 font-normal">
                    (<%= length(entry.scenarios) %> scenario<%= if length(entry.scenarios) != 1, do: "s" %>)
                  </span>
                </button>

                <%!-- Scenario checkboxes (shown when suite is not fully selected) --%>
                <div :if={entry.suite.id not in @selected_suite_ids && entry.scenarios != []} class="mt-2 ml-6 space-y-1">
                  <button
                    :for={sc <- entry.scenarios}
                    type="button"
                    phx-click="toggle_scenario"
                    phx-value-scenario-id={sc.id}
                    class="flex items-center gap-2 text-sm w-full text-left"
                  >
                    <input
                      type="checkbox"
                      checked={sc.id in @selected_scenario_ids}
                      class="checkbox checkbox-xs pointer-events-none"
                      readonly
                    />
                    <span><%= sc.name %></span>
                  </button>
                </div>
              </div>
            </div>

            <p :if={@selected_case_count == 0 && @suite_tree != []} class="mt-2 text-sm text-amber-600">
              Select at least one suite or scenario to proceed.
            </p>
            <p :if={@selected_case_count > 0} class="mt-2 text-sm text-gray-500">
              <%= @selected_case_count %> test case<%= if @selected_case_count != 1, do: "s" %> will be included in this run.
            </p>
          </div>

          <div class="flex gap-3">
            <.button
              phx-click="create_run"
              phx-disable-with="Creating..."
              class="btn btn-primary"
              disabled={@selected_case_count == 0 || @run_name == ""}
            >
              Create Run
            </.button>
            <.link navigate={~p"/projects/#{@project.id}/runs"} class="btn btn-ghost">
              Cancel
            </.link>
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
    suite_tree = Testing.list_suites_with_scenarios(project)

    {:ok,
     socket
     |> assign(
       project: project,
       suite_tree: suite_tree,
       run_name: "",
       selected_suite_ids: [],
       selected_scenario_ids: []
     )
     |> assign_case_count()}
  end

  @impl true
  def handle_event("update_name", %{"value" => name}, socket) do
    {:noreply, assign(socket, run_name: name)}
  end

  def handle_event("toggle_suite", %{"suite-id" => suite_id}, socket) do
    selected_suite_ids =
      if suite_id in socket.assigns.selected_suite_ids do
        Enum.reject(socket.assigns.selected_suite_ids, &(&1 == suite_id))
      else
        [suite_id | socket.assigns.selected_suite_ids]
      end

    {:noreply,
     socket
     |> assign(selected_suite_ids: selected_suite_ids)
     |> assign_case_count()}
  end

  def handle_event("toggle_scenario", %{"scenario-id" => scenario_id}, socket) do
    selected_scenario_ids =
      if scenario_id in socket.assigns.selected_scenario_ids do
        Enum.reject(socket.assigns.selected_scenario_ids, &(&1 == scenario_id))
      else
        [scenario_id | socket.assigns.selected_scenario_ids]
      end

    {:noreply,
     socket
     |> assign(selected_scenario_ids: selected_scenario_ids)
     |> assign_case_count()}
  end

  def handle_event("create_run", _params, socket) do
    user = socket.assigns.current_scope.user

    selections = %{
      suite_ids: socket.assigns.selected_suite_ids,
      scenario_ids: socket.assigns.selected_scenario_ids
    }

    case Testing.create_run(socket.assigns.project, user, socket.assigns.run_name, selections) do
      {:ok, run} ->
        {:noreply,
         socket
         |> put_flash(:info, "Run \"#{run.name}\" created with #{socket.assigns.selected_case_count} cases.")
         |> push_navigate(to: ~p"/projects/#{socket.assigns.project.id}/runs/#{run.id}")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not create run.")}
    end
  end

  defp assign_case_count(socket) do
    count = count_selected_cases(socket.assigns)
    assign(socket, selected_case_count: count)
  end

  defp count_selected_cases(%{
         suite_tree: suite_tree,
         selected_suite_ids: suite_ids,
         selected_scenario_ids: scenario_ids
       }) do
    suite_cases =
      suite_tree
      |> Enum.filter(fn entry -> entry.suite.id in suite_ids end)
      |> Enum.flat_map(fn entry -> entry.scenarios end)
      |> Enum.map(fn sc -> length(Testing.list_cases(sc)) end)
      |> Enum.sum()

    # Scenarios individually selected (not already covered by a selected suite)
    suite_scenario_ids =
      suite_tree
      |> Enum.filter(fn entry -> entry.suite.id in suite_ids end)
      |> Enum.flat_map(fn entry -> Enum.map(entry.scenarios, & &1.id) end)

    scenario_cases =
      suite_tree
      |> Enum.flat_map(fn entry -> entry.scenarios end)
      |> Enum.filter(fn sc ->
        sc.id in scenario_ids && sc.id not in suite_scenario_ids
      end)
      |> Enum.map(fn sc -> length(Testing.list_cases(sc)) end)
      |> Enum.sum()

    suite_cases + scenario_cases
  end
end
