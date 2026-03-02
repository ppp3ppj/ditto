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

        <form id="run_form" phx-submit="create_run" class="space-y-6">
          <%!-- Run name --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Run name <span class="text-red-500">*</span></label>
            <input
              type="text"
              name="run[name]"
              value={@run_name}
              phx-change="update_name"
              placeholder="e.g. Sprint 12 regression"
              class="input input-bordered w-full"
              required
            />
          </div>

          <%!-- Suite/Scenario picker --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Select suites or scenarios to include
            </label>

            <div :if={@suite_tree == []} class="rounded-lg border border-dashed border-gray-300 p-6 text-center text-gray-500 text-sm">
              No test suites found. <.link navigate={~p"/projects/#{@project.id}/suites"} class="underline">Create some first</.link>.
            </div>

            <div :if={@suite_tree != []} class="rounded-lg border border-gray-200 divide-y divide-gray-100">
              <div :for={entry <- @suite_tree} class="p-3">
                <%!-- Suite checkbox --%>
                <label class="flex items-center gap-2 font-medium cursor-pointer">
                  <input
                    type="checkbox"
                    name={"suite_ids[]"}
                    value={entry.suite.id}
                    checked={entry.suite.id in @selected_suite_ids}
                    phx-change="toggle_suite"
                    phx-value-suite-id={entry.suite.id}
                    class="checkbox checkbox-sm"
                  />
                  <span><%= entry.suite.name %></span>
                  <span class="text-xs text-gray-400 font-normal">
                    (<%= length(entry.scenarios) %> scenario<%= if length(entry.scenarios) != 1, do: "s" %>)
                  </span>
                </label>

                <%!-- Scenario checkboxes (only shown when suite is not fully selected) --%>
                <div :if={entry.suite.id not in @selected_suite_ids && entry.scenarios != []} class="mt-2 ml-6 space-y-1">
                  <label :for={sc <- entry.scenarios} class="flex items-center gap-2 text-sm cursor-pointer">
                    <input
                      type="checkbox"
                      name={"scenario_ids[]"}
                      value={sc.id}
                      checked={sc.id in @selected_scenario_ids}
                      phx-change="toggle_scenario"
                      phx-value-scenario-id={sc.id}
                      class="checkbox checkbox-xs"
                    />
                    <span><%= sc.name %></span>
                  </label>
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
              type="submit"
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
        </form>
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
  def handle_event("update_name", %{"run" => %{"name" => name}}, socket) do
    {:noreply, assign(socket, run_name: name)}
  end

  def handle_event("toggle_suite", %{"suite-id" => suite_id} = params, socket) do
    checked = Map.get(params, "value") == suite_id

    selected_suite_ids =
      if checked do
        [suite_id | socket.assigns.selected_suite_ids] |> Enum.uniq()
      else
        Enum.reject(socket.assigns.selected_suite_ids, &(&1 == suite_id))
      end

    {:noreply,
     socket
     |> assign(selected_suite_ids: selected_suite_ids)
     |> assign_case_count()}
  end

  def handle_event("toggle_scenario", %{"scenario-id" => scenario_id} = params, socket) do
    checked = Map.get(params, "value") == scenario_id

    selected_scenario_ids =
      if checked do
        [scenario_id | socket.assigns.selected_scenario_ids] |> Enum.uniq()
      else
        Enum.reject(socket.assigns.selected_scenario_ids, &(&1 == scenario_id))
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

  defp count_selected_cases(%{suite_tree: suite_tree, selected_suite_ids: suite_ids, selected_scenario_ids: scenario_ids}) do
    suite_cases =
      suite_tree
      |> Enum.filter(fn entry -> entry.suite.id in suite_ids end)
      |> Enum.flat_map(fn entry -> entry.scenarios end)
      |> Enum.map(fn sc -> length(Testing.list_cases(sc)) end)
      |> Enum.sum()

    # Scenarios that are individually selected (not via suite)
    scenario_cases =
      suite_tree
      |> Enum.flat_map(fn entry -> entry.scenarios end)
      |> Enum.filter(fn sc ->
        sc.id in scenario_ids &&
          not Enum.any?(suite_tree, fn entry ->
            entry.suite.id in suite_ids && Enum.any?(entry.scenarios, &(&1.id == sc.id))
          end)
      end)
      |> Enum.map(fn sc -> length(Testing.list_cases(sc)) end)
      |> Enum.sum()

    suite_cases + scenario_cases
  end
end
