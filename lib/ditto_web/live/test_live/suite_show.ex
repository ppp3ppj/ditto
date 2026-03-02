defmodule DittoWeb.TestLive.SuiteShow do
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
          <.link navigate={~p"/projects/#{@project.id}/suites"} class="hover:underline">Test Suites</.link>
          <span>/</span>
          <span class="text-gray-800 font-medium"><%= @suite.name %></span>
        </nav>

        <%!-- Suite header with inline edit --%>
        <div>
          <div :if={!@editing} class="flex items-start justify-between">
            <div>
              <h1 class="text-2xl font-bold"><%= @suite.name %></h1>
              <p :if={@suite.description} class="mt-1 text-gray-500"><%= @suite.description %></p>
            </div>
            <.button phx-click="edit" class="btn btn-sm">Edit</.button>
          </div>

          <div :if={@editing}>
            <.form for={@edit_form} id="suite_edit_form" phx-submit="update" phx-change="validate_update" class="space-y-3">
              <.input field={@edit_form[:name]} type="text" label="Suite name" required />
              <.input field={@edit_form[:description]} type="textarea" label="Description" rows="2" />
              <div class="flex gap-2">
                <.button phx-disable-with="Saving..." class="btn btn-primary btn-sm">Save</.button>
                <.button type="button" phx-click="cancel_edit" class="btn btn-sm">Cancel</.button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Scenarios --%>
        <section>
          <h2 class="text-lg font-semibold">Scenarios (<%= length(@scenarios) %>)</h2>

          <div :if={@scenarios == []} class="mt-3 rounded-lg border border-dashed border-gray-300 p-6 text-center text-gray-500 text-sm">
            No scenarios yet. Add one below.
          </div>

          <div :if={@scenarios != []} class="mt-3 divide-y divide-gray-100 rounded-lg border border-gray-200">
            <div :for={sc <- @scenarios} class="flex items-center justify-between px-4 py-3">
              <div>
                <.link
                  navigate={~p"/projects/#{@project.id}/suites/#{@suite.id}/scenarios/#{sc.id}"}
                  class="font-medium hover:underline"
                >
                  <%= sc.name %>
                </.link>
                <p :if={sc.description} class="text-sm text-gray-500"><%= sc.description %></p>
              </div>
              <.button
                phx-click="delete_scenario"
                phx-value-id={sc.id}
                data-confirm={"Delete \"#{sc.name}\"? All cases and steps will be removed."}
                class="btn btn-xs btn-error btn-outline"
              >
                Delete
              </.button>
            </div>
          </div>
        </section>

        <%!-- Add Scenario form --%>
        <section class="rounded-lg border border-gray-200 p-4">
          <h2 class="text-sm font-semibold text-gray-700 mb-3">Add Scenario</h2>
          <.form for={@form} id="scenario_form" phx-submit="create_scenario" phx-change="validate_scenario" class="space-y-3">
            <.input field={@form[:name]} type="text" label="Scenario name" placeholder="e.g. User login flow" required />
            <.input field={@form[:description]} type="textarea" label="Description (optional)" rows="2" />
            <.button phx-disable-with="Creating..." class="btn btn-primary btn-sm">
              Add Scenario
            </.button>
          </.form>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid, "id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    suite = Testing.get_suite_for_project!(project, id)
    scenarios = Testing.list_scenarios(suite)

    {:ok,
     socket
     |> assign(project: project, suite: suite, scenarios: scenarios, editing: false)
     |> assign_edit_form(suite)
     |> assign_scenario_form()}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false) |> assign_edit_form(socket.assigns.suite)}
  end

  def handle_event("validate_update", %{"suite" => params}, socket) do
    changeset = Testing.change_suite(socket.assigns.suite, params)
    {:noreply, assign(socket, edit_form: to_form(Map.put(changeset, :action, :validate), as: "suite"))}
  end

  def handle_event("update", %{"suite" => params}, socket) do
    case Testing.update_suite(socket.assigns.suite, params) do
      {:ok, suite} ->
        {:noreply,
         socket
         |> put_flash(:info, "Suite updated.")
         |> assign(suite: suite, editing: false)
         |> assign_edit_form(suite)}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset, as: "suite"))}
    end
  end

  def handle_event("validate_scenario", %{"scenario" => params}, socket) do
    changeset = Testing.change_scenario(%Ditto.Testing.Scenario{}, params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "scenario"))}
  end

  def handle_event("create_scenario", %{"scenario" => params}, socket) do
    case Testing.create_scenario(socket.assigns.suite, params) do
      {:ok, _scenario} ->
        scenarios = Testing.list_scenarios(socket.assigns.suite)

        {:noreply,
         socket
         |> put_flash(:info, "Scenario added.")
         |> assign(scenarios: scenarios)
         |> assign_scenario_form()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "scenario"))}
    end
  end

  def handle_event("delete_scenario", %{"id" => id}, socket) do
    scenario = Testing.get_scenario!(id)
    {:ok, _} = Testing.delete_scenario(scenario)
    scenarios = Testing.list_scenarios(socket.assigns.suite)

    {:noreply,
     socket
     |> put_flash(:info, "Scenario deleted.")
     |> assign(scenarios: scenarios)}
  end

  defp assign_edit_form(socket, suite) do
    assign(socket, edit_form: to_form(Testing.change_suite(suite), as: "suite"))
  end

  defp assign_scenario_form(socket) do
    assign(socket, form: to_form(Testing.change_scenario(), as: "scenario"))
  end
end
