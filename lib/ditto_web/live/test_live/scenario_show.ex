defmodule DittoWeb.TestLive.ScenarioShow do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Testing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl space-y-6">
        <%!-- Breadcrumb --%>
        <nav class="text-sm text-gray-500 flex gap-1 items-center flex-wrap">
          <.link navigate={~p"/projects"} class="hover:underline">Projects</.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}"} class="hover:underline"><%= @project.name %></.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}/suites"} class="hover:underline">Suites</.link>
          <span>/</span>
          <.link navigate={~p"/projects/#{@project.id}/suites/#{@suite.id}"} class="hover:underline"><%= @suite.name %></.link>
          <span>/</span>
          <span class="text-gray-800 font-medium"><%= @scenario.name %></span>
        </nav>

        <%!-- Scenario header with inline edit --%>
        <div>
          <div :if={!@editing} class="flex items-start justify-between">
            <div>
              <h1 class="text-2xl font-bold"><%= @scenario.name %></h1>
              <p :if={@scenario.description} class="mt-1 text-gray-500"><%= @scenario.description %></p>
            </div>
            <.button phx-click="edit" class="btn btn-sm">Edit</.button>
          </div>

          <div :if={@editing}>
            <.form for={@edit_form} id="scenario_edit_form" phx-submit="update" phx-change="validate_update" class="space-y-3">
              <.input field={@edit_form[:name]} type="text" label="Scenario name" required />
              <.input field={@edit_form[:description]} type="textarea" label="Description" rows="2" />
              <div class="flex gap-2">
                <.button phx-disable-with="Saving..." class="btn btn-primary btn-sm">Save</.button>
                <.button type="button" phx-click="cancel_edit" class="btn btn-sm">Cancel</.button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Cases --%>
        <section>
          <h2 class="text-lg font-semibold">Test Cases (<%= length(@cases) %>)</h2>

          <div :if={@cases == []} class="mt-3 rounded-lg border border-dashed border-gray-300 p-6 text-center text-gray-500 text-sm">
            No test cases yet. Add one below.
          </div>

          <div :if={@cases != []} class="mt-3 divide-y divide-gray-100 rounded-lg border border-gray-200">
            <div :for={{tc, idx} <- Enum.with_index(@cases)} class="flex items-center justify-between px-4 py-3">
              <div>
                <.link
                  navigate={~p"/projects/#{@project.id}/suites/#{@suite.id}/scenarios/#{@scenario.id}/cases/#{tc.id}"}
                  class="font-medium hover:underline"
                >
                  <%= tc.name %>
                </.link>
                <p :if={tc.description} class="text-sm text-gray-500"><%= tc.description %></p>
              </div>
              <div class="flex items-center gap-1">
                <.button
                  :if={idx > 0}
                  phx-click="move_case_up"
                  phx-value-id={tc.id}
                  class="btn btn-xs btn-ghost"
                  title="Move up"
                >
                  ↑
                </.button>
                <.button
                  :if={idx < length(@cases) - 1}
                  phx-click="move_case_down"
                  phx-value-id={tc.id}
                  class="btn btn-xs btn-ghost"
                  title="Move down"
                >
                  ↓
                </.button>
                <.button
                  phx-click="delete_case"
                  phx-value-id={tc.id}
                  data-confirm={"Delete \"#{tc.name}\"? All steps will be removed."}
                  class="btn btn-xs btn-error btn-outline"
                >
                  Delete
                </.button>
              </div>
            </div>
          </div>
        </section>

        <%!-- Add Case form --%>
        <section class="rounded-lg border border-gray-200 p-4">
          <h2 class="text-sm font-semibold text-gray-700 mb-3">Add Test Case</h2>
          <.form for={@form} id="case_form" phx-submit="create_case" phx-change="validate_case" class="space-y-3">
            <.input field={@form[:name]} type="text" label="Case name" placeholder="e.g. Login with valid credentials" required />
            <.input field={@form[:description]} type="textarea" label="Description (optional)" rows="2" />
            <.button phx-disable-with="Creating..." class="btn btn-primary btn-sm">
              Add Case
            </.button>
          </.form>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid, "sid" => sid, "id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    suite = Testing.get_suite_for_project!(project, sid)
    scenario = Testing.get_scenario!(id)
    cases = Testing.list_cases(scenario)

    {:ok,
     socket
     |> assign(project: project, suite: suite, scenario: scenario, cases: cases, editing: false)
     |> assign_edit_form(scenario)
     |> assign_case_form()}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false) |> assign_edit_form(socket.assigns.scenario)}
  end

  def handle_event("validate_update", %{"scenario" => params}, socket) do
    changeset = Testing.change_scenario(socket.assigns.scenario, params)
    {:noreply, assign(socket, edit_form: to_form(Map.put(changeset, :action, :validate), as: "scenario"))}
  end

  def handle_event("update", %{"scenario" => params}, socket) do
    case Testing.update_scenario(socket.assigns.scenario, params) do
      {:ok, scenario} ->
        {:noreply,
         socket
         |> put_flash(:info, "Scenario updated.")
         |> assign(scenario: scenario, editing: false)
         |> assign_edit_form(scenario)}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset, as: "scenario"))}
    end
  end

  def handle_event("validate_case", %{"case" => params}, socket) do
    changeset = Testing.change_case(%Ditto.Testing.Case{}, params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "case"))}
  end

  def handle_event("create_case", %{"case" => params}, socket) do
    case Testing.create_case(socket.assigns.scenario, params) do
      {:ok, _tc} ->
        cases = Testing.list_cases(socket.assigns.scenario)

        {:noreply,
         socket
         |> put_flash(:info, "Case added.")
         |> assign(cases: cases)
         |> assign_case_form()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "case"))}
    end
  end

  def handle_event("delete_case", %{"id" => id}, socket) do
    tc = Testing.get_case!(id)
    {:ok, _} = Testing.delete_case(tc)
    cases = Testing.list_cases(socket.assigns.scenario)

    {:noreply,
     socket
     |> put_flash(:info, "Case deleted.")
     |> assign(cases: cases)}
  end

  def handle_event("move_case_up", %{"id" => id}, socket) do
    tc = Testing.get_case!(id)
    Testing.move_case_up(tc)
    cases = Testing.list_cases(socket.assigns.scenario)
    {:noreply, assign(socket, cases: cases)}
  end

  def handle_event("move_case_down", %{"id" => id}, socket) do
    tc = Testing.get_case!(id)
    Testing.move_case_down(tc)
    cases = Testing.list_cases(socket.assigns.scenario)
    {:noreply, assign(socket, cases: cases)}
  end

  defp assign_edit_form(socket, scenario) do
    assign(socket, edit_form: to_form(Testing.change_scenario(scenario), as: "scenario"))
  end

  defp assign_case_form(socket) do
    assign(socket, form: to_form(Testing.change_case(), as: "case"))
  end
end
