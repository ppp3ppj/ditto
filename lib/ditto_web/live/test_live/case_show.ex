defmodule DittoWeb.TestLive.CaseShow do
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
          <.link navigate={~p"/projects/#{@project.id}/suites/#{@suite.id}/scenarios/#{@scenario.id}"} class="hover:underline"><%= @scenario.name %></.link>
          <span>/</span>
          <span class="text-gray-800 font-medium"><%= @test_case.name %></span>
        </nav>

        <%!-- Case header with inline edit --%>
        <div>
          <div :if={!@editing} class="flex items-start justify-between">
            <div>
              <h1 class="text-2xl font-bold"><%= @test_case.name %></h1>
              <p :if={@test_case.description} class="mt-1 text-gray-500"><%= @test_case.description %></p>
            </div>
            <.button phx-click="edit" class="btn btn-sm">Edit</.button>
          </div>

          <div :if={@editing}>
            <.form for={@edit_form} id="case_edit_form" phx-submit="update" phx-change="validate_update" class="space-y-3">
              <.input field={@edit_form[:name]} type="text" label="Case name" required />
              <.input field={@edit_form[:description]} type="textarea" label="Description" rows="2" />
              <div class="flex gap-2">
                <.button phx-disable-with="Saving..." class="btn btn-primary btn-sm">Save</.button>
                <.button type="button" phx-click="cancel_edit" class="btn btn-sm">Cancel</.button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Steps --%>
        <section>
          <h2 class="text-lg font-semibold">Steps (<%= length(@steps) %>)</h2>

          <div :if={@steps == []} class="mt-3 rounded-lg border border-dashed border-gray-300 p-6 text-center text-gray-500 text-sm">
            No steps yet. Add one below.
          </div>

          <div :if={@steps != []} class="mt-3 rounded-lg border border-gray-200 overflow-hidden">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 w-8">#</th>
                  <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">Description</th>
                  <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">Expected Result</th>
                  <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 w-32">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr :for={{step, idx} <- Enum.with_index(@steps)}>
                  <td :if={@editing_step_id != step.id} class="px-4 py-3 text-gray-400 align-top"><%= idx + 1 %></td>
                  <td :if={@editing_step_id != step.id} class="px-4 py-3 align-top whitespace-pre-wrap"><%= step.description %></td>
                  <td :if={@editing_step_id != step.id} class="px-4 py-3 text-gray-500 align-top whitespace-pre-wrap">
                    <%= step.expected_result || "—" %>
                  </td>
                  <td :if={@editing_step_id != step.id} class="px-4 py-3 text-right align-top">
                    <div class="flex justify-end items-center gap-1">
                      <.button
                        :if={idx > 0}
                        phx-click="move_step_up"
                        phx-value-id={step.id}
                        class="btn btn-xs btn-ghost"
                        title="Move up"
                      >↑</.button>
                      <.button
                        :if={idx < length(@steps) - 1}
                        phx-click="move_step_down"
                        phx-value-id={step.id}
                        class="btn btn-xs btn-ghost"
                        title="Move down"
                      >↓</.button>
                      <.button
                        phx-click="edit_step"
                        phx-value-id={step.id}
                        class="btn btn-xs btn-ghost"
                      >Edit</.button>
                      <.button
                        phx-click="delete_step"
                        phx-value-id={step.id}
                        data-confirm="Delete this step?"
                        class="btn btn-xs btn-error btn-outline"
                      >×</.button>
                    </div>
                  </td>
                  <%!-- Inline edit row --%>
                  <td :if={@editing_step_id == step.id} colspan="4" class="px-4 py-3">
                    <.form for={@step_edit_form} id={"step_edit_form_#{step.id}"} phx-submit="update_step" class="space-y-2">
                      <input type="hidden" name="step_id" value={step.id} />
                      <.input field={@step_edit_form[:description]} type="textarea" label="Description" rows="2" required />
                      <.input field={@step_edit_form[:expected_result]} type="textarea" label="Expected Result" rows="2" />
                      <div class="flex gap-2">
                        <.button phx-disable-with="Saving..." class="btn btn-primary btn-xs">Save</.button>
                        <.button type="button" phx-click="cancel_step_edit" class="btn btn-xs">Cancel</.button>
                      </div>
                    </.form>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- Add Step form --%>
        <section :if={is_nil(@editing_step_id)} class="rounded-lg border border-gray-200 p-4">
          <h2 class="text-sm font-semibold text-gray-700 mb-3">Add Step</h2>
          <.form for={@form} id="step_form" phx-submit="create_step" phx-change="validate_step" class="space-y-3">
            <.input field={@form[:description]} type="textarea" label="Description" placeholder="What to do" rows="2" required />
            <.input field={@form[:expected_result]} type="textarea" label="Expected Result (optional)" placeholder="What should happen" rows="2" />
            <.button phx-disable-with="Adding..." class="btn btn-primary btn-sm">
              Add Step
            </.button>
          </.form>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid, "sid" => sid, "id" => id} = params, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    suite = Testing.get_suite_for_project!(project, sid)
    scenario = Testing.get_scenario!(params["scid"])
    test_case = Testing.get_case!(id)
    steps = Testing.list_steps(test_case)

    {:ok,
     socket
     |> assign(
       project: project,
       suite: suite,
       scenario: scenario,
       test_case: test_case,
       steps: steps,
       editing: false,
       editing_step_id: nil
     )
     |> assign_edit_form(test_case)
     |> assign_step_form()
     |> assign(step_edit_form: to_form(Testing.change_step(), as: "step"))}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false) |> assign_edit_form(socket.assigns.test_case)}
  end

  def handle_event("validate_update", %{"case" => params}, socket) do
    changeset = Testing.change_case(socket.assigns.test_case, params)
    {:noreply, assign(socket, edit_form: to_form(Map.put(changeset, :action, :validate), as: "case"))}
  end

  def handle_event("update", %{"case" => params}, socket) do
    case Testing.update_case(socket.assigns.test_case, params) do
      {:ok, test_case} ->
        {:noreply,
         socket
         |> put_flash(:info, "Case updated.")
         |> assign(test_case: test_case, editing: false)
         |> assign_edit_form(test_case)}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset, as: "case"))}
    end
  end

  def handle_event("validate_step", %{"step" => params}, socket) do
    changeset = Testing.change_step(%Ditto.Testing.Step{}, params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "step"))}
  end

  def handle_event("create_step", %{"step" => params}, socket) do
    case Testing.create_step(socket.assigns.test_case, params) do
      {:ok, _step} ->
        steps = Testing.list_steps(socket.assigns.test_case)

        {:noreply,
         socket
         |> put_flash(:info, "Step added.")
         |> assign(steps: steps)
         |> assign_step_form()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "step"))}
    end
  end

  def handle_event("edit_step", %{"id" => id}, socket) do
    step = Testing.get_step!(id)
    form = to_form(Testing.change_step(step), as: "step")
    {:noreply, assign(socket, editing_step_id: id, step_edit_form: form)}
  end

  def handle_event("cancel_step_edit", _params, socket) do
    {:noreply, assign(socket, editing_step_id: nil)}
  end

  def handle_event("update_step", %{"step" => params, "step_id" => id}, socket) do
    step = Testing.get_step!(id)

    case Testing.update_step(step, params) do
      {:ok, _step} ->
        steps = Testing.list_steps(socket.assigns.test_case)

        {:noreply,
         socket
         |> put_flash(:info, "Step updated.")
         |> assign(steps: steps, editing_step_id: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, step_edit_form: to_form(changeset, as: "step"))}
    end
  end

  def handle_event("delete_step", %{"id" => id}, socket) do
    step = Testing.get_step!(id)
    {:ok, _} = Testing.delete_step(step)
    steps = Testing.list_steps(socket.assigns.test_case)

    {:noreply,
     socket
     |> put_flash(:info, "Step deleted.")
     |> assign(steps: steps)}
  end

  def handle_event("move_step_up", %{"id" => id}, socket) do
    step = Testing.get_step!(id)
    Testing.move_step_up(step)
    steps = Testing.list_steps(socket.assigns.test_case)
    {:noreply, assign(socket, steps: steps)}
  end

  def handle_event("move_step_down", %{"id" => id}, socket) do
    step = Testing.get_step!(id)
    Testing.move_step_down(step)
    steps = Testing.list_steps(socket.assigns.test_case)
    {:noreply, assign(socket, steps: steps)}
  end

  defp assign_edit_form(socket, test_case) do
    assign(socket, edit_form: to_form(Testing.change_case(test_case), as: "case"))
  end

  defp assign_step_form(socket) do
    assign(socket, form: to_form(Testing.change_step(), as: "step"))
  end
end
