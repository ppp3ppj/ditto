defmodule DittoWeb.TestLive.RunShow do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Testing
  alias Ditto.Repo
  alias Ditto.Testing.Result

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
          <.link navigate={~p"/projects/#{@project.id}/runs"} class="hover:underline">Test Runs</.link>
          <span>/</span>
          <span class="text-gray-800 font-medium"><%= @run.name %></span>
        </nav>

        <%!-- Run header --%>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold"><%= @run.name %></h1>
            <span class={[
              "mt-1 inline-block rounded-full px-2 py-0.5 text-xs font-medium",
              @run.status == "pending" && "bg-gray-100 text-gray-600",
              @run.status == "in_progress" && "bg-blue-100 text-blue-700",
              @run.status == "completed" && "bg-green-100 text-green-700"
            ]}>
              <%= @run.status %>
            </span>
          </div>
          <.button
            :if={@progress.pending > 0}
            phx-click="skip_remaining"
            data-confirm="Mark all pending results as Skip?"
            class="btn btn-sm btn-outline"
          >
            Skip remaining (<%= @progress.pending %>)
          </.button>
        </div>

        <%!-- Progress bar --%>
        <div class="rounded-lg border border-gray-200 p-4">
          <div class="flex gap-6 text-sm mb-3">
            <span class="text-green-600 font-medium"><%= @progress.pass %> pass</span>
            <span class="text-red-600 font-medium"><%= @progress.fail %> fail</span>
            <span class="text-gray-500 font-medium"><%= @progress.skip %> skip</span>
            <span class="text-gray-400"><%= @progress.pending %> pending</span>
            <span class="ml-auto text-gray-500"><%= @progress.total %> total</span>
          </div>
          <div class="w-full h-2 bg-gray-100 rounded-full overflow-hidden flex">
            <div
              :if={@progress.total > 0}
              class="bg-green-500 h-full transition-all"
              style={"width: #{@progress.pass * 100 / @progress.total}%"}
            />
            <div
              :if={@progress.total > 0}
              class="bg-red-500 h-full transition-all"
              style={"width: #{@progress.fail * 100 / @progress.total}%"}
            />
            <div
              :if={@progress.total > 0}
              class="bg-gray-300 h-full transition-all"
              style={"width: #{@progress.skip * 100 / @progress.total}%"}
            />
          </div>
        </div>

        <%!-- Results grouped by scenario --%>
        <div :if={@results == []} class="text-center text-gray-500 py-8">
          This run has no test cases.
        </div>

        <div :if={@results != []} class="space-y-6">
          <section :for={{scenario_name, group} <- @grouped_results}>
            <h2 class="text-base font-semibold text-gray-700 border-b border-gray-200 pb-1 mb-2">
              <%= scenario_name %>
            </h2>
            <div class="divide-y divide-gray-100 rounded-lg border border-gray-200">
              <div :for={result <- group} class="px-4 py-3">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1 min-w-0">
                    <p class="font-medium"><%= result.case_name %></p>
                    <%!-- Notes edit form --%>
                    <div :if={@editing_result_id == result.id} class="mt-2">
                      <form phx-submit="save_notes" id={"notes_form_#{result.id}"} class="space-y-2">
                        <input type="hidden" name="result_id" value={result.id} />
                        <textarea
                          name="notes"
                          placeholder="Add notes (optional)"
                          rows="2"
                          class="textarea textarea-bordered w-full text-sm"
                        ><%= result.notes %></textarea>
                        <div class="flex gap-2">
                          <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary btn-xs">Save notes</.button>
                          <.button type="button" phx-click="cancel_notes" class="btn btn-xs">Cancel</.button>
                        </div>
                      </form>
                    </div>
                    <%!-- Notes display --%>
                    <div :if={@editing_result_id != result.id} class="mt-1 flex items-center gap-2">
                      <p :if={result.notes} class="text-sm text-gray-500 italic flex-1"><%= result.notes %></p>
                      <button
                        phx-click="edit_notes"
                        phx-value-id={result.id}
                        class="text-xs text-gray-400 hover:text-gray-600 underline"
                      >
                        <%= if result.notes, do: "edit notes", else: "add notes" %>
                      </button>
                    </div>
                  </div>
                  <%!-- Status buttons --%>
                  <div class="flex items-center gap-1 shrink-0">
                    <.button
                      phx-click="set_status"
                      phx-value-id={result.id}
                      phx-value-status="pass"
                      class={["btn btn-xs", result.status == "pass" && "btn-success", result.status != "pass" && "btn-outline"]}
                      title="Pass"
                    >
                      ✓
                    </.button>
                    <.button
                      phx-click="set_status"
                      phx-value-id={result.id}
                      phx-value-status="fail"
                      class={["btn btn-xs", result.status == "fail" && "btn-error", result.status != "fail" && "btn-outline"]}
                      title="Fail"
                    >
                      ✗
                    </.button>
                    <.button
                      phx-click="set_status"
                      phx-value-id={result.id}
                      phx-value-status="skip"
                      class={["btn btn-xs", result.status == "skip" && "btn-neutral", result.status != "skip" && "btn-outline"]}
                      title="Skip"
                    >
                      ⊘
                    </.button>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"pid" => pid, "id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    run = Testing.get_run!(id)
    results = Testing.list_results(run)
    progress = Testing.run_progress(run)

    {:ok,
     socket
     |> assign(
       project: project,
       run: run,
       results: results,
       grouped_results: group_results(results),
       progress: progress,
       editing_result_id: nil
     )}
  end

  @impl true
  def handle_event("set_status", %{"id" => id, "status" => status}, socket) do
    result = Repo.get!(Result, id)
    user = socket.assigns.current_scope.user

    {:ok, _} = Testing.update_result(result, user, %{"status" => status})

    run = Testing.get_run!(socket.assigns.run.id)
    results = Testing.list_results(run)
    progress = Testing.run_progress(run)

    {:noreply,
     socket
     |> assign(run: run, results: results, grouped_results: group_results(results), progress: progress)}
  end

  def handle_event("edit_notes", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_result_id: id)}
  end

  def handle_event("cancel_notes", _params, socket) do
    {:noreply, assign(socket, editing_result_id: nil)}
  end

  def handle_event("save_notes", %{"result_id" => id, "notes" => notes}, socket) do
    result = Repo.get!(Result, id)
    user = socket.assigns.current_scope.user

    {:ok, _} = Testing.update_result(result, user, %{"status" => result.status, "notes" => notes})

    run = Testing.get_run!(socket.assigns.run.id)
    results = Testing.list_results(run)
    progress = Testing.run_progress(run)

    {:noreply,
     socket
     |> assign(
       run: run,
       results: results,
       grouped_results: group_results(results),
       progress: progress,
       editing_result_id: nil
     )}
  end

  def handle_event("skip_remaining", _params, socket) do
    user = socket.assigns.current_scope.user

    pending_results =
      socket.assigns.results
      |> Enum.filter(&(&1.status == "pending"))

    for result_map <- pending_results do
      result = Repo.get!(Result, result_map.id)
      Testing.update_result(result, user, %{"status" => "skip"})
    end

    run = Testing.get_run!(socket.assigns.run.id)
    results = Testing.list_results(run)
    progress = Testing.run_progress(run)

    {:noreply,
     socket
     |> assign(run: run, results: results, grouped_results: group_results(results), progress: progress)}
  end

  defp group_results(results) do
    results
    |> Enum.group_by(& &1.scenario_name)
    |> Enum.to_list()
  end
end
