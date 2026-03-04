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
      <%!-- Empty run --%>
      <div :if={@results == []} class="mx-auto max-w-2xl py-16 text-center text-gray-500">
        <p class="text-lg">This run has no test cases.</p>
        <.link navigate={~p"/projects/#{@project.id}/runs"} class="mt-4 btn btn-sm btn-outline">
          ← Back to Runs
        </.link>
      </div>

      <%!-- Active runner --%>
      <div :if={@results != [] && @current_index < length(@results)} class="mx-auto max-w-3xl space-y-4">
        <%!-- Top bar: back link + run name + dot navigation --%>
        <div class="flex items-center gap-3 flex-wrap">
          <.link navigate={~p"/projects/#{@project.id}/runs"} class="text-sm text-gray-500 hover:underline shrink-0">
            ← Runs
          </.link>
          <span class="text-sm font-medium text-gray-700 shrink-0"><%= @run.name %></span>
          <div class="ml-auto flex items-center gap-1 flex-wrap">
            <%!-- Dot nav (show if ≤ 20 cases, else show counter only) --%>
            <div :if={length(@results) <= 20} class="flex items-center gap-1">
              <button
                :for={{result, idx} <- Enum.with_index(@results)}
                phx-click="jump_to"
                phx-value-index={idx}
                title={result.case_name}
                class={[
                  "w-3 h-3 rounded-full transition-all",
                  idx == @current_index && "ring-2 ring-offset-1 ring-gray-400 scale-125",
                  result.status == "pass" && "bg-green-500",
                  result.status == "fail" && "bg-red-500",
                  result.status == "skip" && "bg-gray-400",
                  result.status == "pending" && "bg-gray-200"
                ]}
              />
            </div>
            <span class="text-sm text-gray-500 font-medium">
              <%= @current_index + 1 %> / <%= length(@results) %>
            </span>
          </div>
        </div>

        <%!-- Progress bar --%>
        <div class="space-y-1">
          <div class="flex gap-4 text-xs text-gray-500">
            <span class="text-green-600 font-medium"><%= @progress.pass %> pass</span>
            <span class="text-red-500 font-medium"><%= @progress.fail %> fail</span>
            <span class="text-gray-400"><%= @progress.skip %> skip</span>
            <span class="text-gray-400"><%= @progress.pending %> pending</span>
          </div>
          <div class="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden flex">
            <div
              class="bg-green-500 h-full transition-all"
              style={"width: #{if @progress.total > 0, do: @progress.pass * 100 / @progress.total, else: 0}%"}
            />
            <div
              class="bg-red-500 h-full transition-all"
              style={"width: #{if @progress.total > 0, do: @progress.fail * 100 / @progress.total, else: 0}%"}
            />
            <div
              class="bg-gray-300 h-full transition-all"
              style={"width: #{if @progress.total > 0, do: @progress.skip * 100 / @progress.total, else: 0}%"}
            />
          </div>
        </div>

        <%!-- Pause / Finish controls (only while cases remain) --%>
        <div :if={@progress.pending > 0} class="flex justify-end gap-2">
          <.button
            phx-click="pause_run"
            class="btn btn-sm btn-outline"
          >
            Pause
          </.button>
          <.button
            phx-click="finish_run"
            data-confirm="Finish run now? Remaining pending cases will be left as not run."
            class="btn btn-sm btn-warning"
          >
            Finish Run
          </.button>
        </div>

        <%!-- Case card --%>
        <div class={[
          "rounded-xl border-l-4 border border-gray-200 bg-white shadow",
          current_result(@results, @current_index).status == "pass" && "border-l-green-500",
          current_result(@results, @current_index).status == "fail" && "border-l-red-500",
          current_result(@results, @current_index).status == "skip" && "border-l-gray-400",
          current_result(@results, @current_index).status == "pending" && "border-l-gray-200"
        ]}>
          <%!-- Scenario + case name --%>
          <div class="px-6 pt-6 pb-4 border-b border-gray-100">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">
              <%= current_result(@results, @current_index).scenario_name %>
            </p>
            <h1 class="text-2xl font-bold text-gray-900">
              <%= current_result(@results, @current_index).case_name %>
            </h1>
            <span :if={current_result(@results, @current_index).status != "pending"} class={[
              "mt-2 inline-block rounded-full px-2 py-0.5 text-xs font-medium",
              current_result(@results, @current_index).status == "pass" && "bg-green-100 text-green-700",
              current_result(@results, @current_index).status == "fail" && "bg-red-100 text-red-700",
              current_result(@results, @current_index).status == "skip" && "bg-gray-100 text-gray-600"
            ]}>
              <%= current_result(@results, @current_index).status %>
            </span>
          </div>

          <%!-- Steps --%>
          <div class="px-6 py-5">
            <div :if={Map.get(@steps_by_case, current_result(@results, @current_index).case_id, []) == []} class="text-sm text-gray-400 italic">
              No steps defined for this case.
            </div>
            <div :if={Map.get(@steps_by_case, current_result(@results, @current_index).case_id, []) != []}>
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Steps to follow</p>
              <ol class="space-y-4">
                <li
                  :for={{step, idx} <- Enum.with_index(Map.get(@steps_by_case, current_result(@results, @current_index).case_id, []))}
                  class="flex gap-4"
                >
                  <span class="shrink-0 mt-0.5 w-7 h-7 rounded-full bg-gray-100 text-gray-600 text-sm font-bold flex items-center justify-center">
                    <%= idx + 1 %>
                  </span>
                  <div class="min-w-0 pt-0.5">
                    <p class="text-base text-gray-800"><%= step.description %></p>
                    <p :if={step.expected_result} class="mt-1 text-sm text-blue-700 bg-blue-50 border border-blue-100 rounded px-3 py-1">
                      Expected: <%= step.expected_result %>
                    </p>
                  </div>
                </li>
              </ol>
            </div>
          </div>

          <%!-- Notes section --%>
          <div class="px-6 pb-5 border-t border-gray-100 pt-4">
            <%!-- Show existing notes (read-only "edit" link only when run is not completed) --%>
            <div :if={current_result(@results, @current_index).notes && !@show_notes} class="mb-3 flex items-start gap-2">
              <p class="text-sm text-gray-600 italic flex-1 border-l-2 border-red-200 pl-2">
                <%= current_result(@results, @current_index).notes %>
              </p>
              <button :if={@run.status != "completed"} phx-click="show_notes" class="text-xs text-gray-400 hover:text-gray-700 underline shrink-0">edit</button>
            </div>

            <%!-- Notes form (only when run is not completed) --%>
            <div :if={@show_notes && @run.status != "completed"}>
              <form phx-submit="save_notes" id="notes_form" class="space-y-2">
                <input type="hidden" name="result_id" value={current_result(@results, @current_index).id} />
                <textarea
                  name="notes"
                  placeholder="Describe what went wrong, observations, error messages..."
                  rows="3"
                  class="textarea textarea-bordered w-full text-sm"
                  autofocus
                ><%= current_result(@results, @current_index).notes %></textarea>
                <div class="flex gap-2">
                  <.button type="submit" phx-disable-with="Saving..." class="btn btn-sm btn-primary">
                    Save notes
                  </.button>
                  <.button type="button" phx-click="dismiss_notes" class="btn btn-sm btn-ghost">
                    Cancel
                  </.button>
                </div>
              </form>
            </div>

            <%!-- "Add notes" link only when run is not completed --%>
            <div :if={!current_result(@results, @current_index).notes && !@show_notes && @run.status != "completed"}>
              <button phx-click="show_notes" class="text-xs text-gray-400 hover:text-gray-600 underline">
                + add notes
              </button>
            </div>
          </div>
        </div>

        <%!-- Action bar --%>
        <div class="flex items-center gap-2">
          <.button
            phx-click="navigate"
            phx-value-direction="prev"
            disabled={@current_index == 0}
            class="btn btn-outline btn-sm"
          >
            ← Prev
          </.button>

          <div class="flex-1" />

          <%!-- Locked notice when run is completed --%>
          <span :if={@run.status == "completed"} class="text-xs text-gray-400 italic">
            Run completed — results are locked
          </span>

          <%!-- Mark buttons only when run is not completed --%>
          <.button
            :if={@run.status != "completed"}
            phx-click="mark_fail"
            phx-value-id={current_result(@results, @current_index).id}
            class={["btn btn-sm font-bold", current_result(@results, @current_index).status == "fail" && "btn-error", current_result(@results, @current_index).status != "fail" && "btn-outline btn-error"]}
          >
            ✗ Fail
          </.button>
          <.button
            :if={@run.status != "completed"}
            phx-click="mark_skip"
            phx-value-id={current_result(@results, @current_index).id}
            class={["btn btn-sm", current_result(@results, @current_index).status == "skip" && "btn-neutral", current_result(@results, @current_index).status != "skip" && "btn-outline"]}
          >
            ⊘ Skip
          </.button>
          <.button
            :if={@run.status != "completed"}
            phx-click="mark_pass"
            phx-value-id={current_result(@results, @current_index).id}
            class={["btn btn-sm font-bold", current_result(@results, @current_index).status == "pass" && "btn-success", current_result(@results, @current_index).status != "pass" && "btn-success btn-outline"]}
          >
            ✓ Pass →
          </.button>

          <.button
            phx-click="navigate"
            phx-value-direction="next"
            disabled={@current_index + 1 >= length(@results)}
            class="btn btn-outline btn-sm"
          >
            Next →
          </.button>
        </div>

        <%!-- Keyboard hint --%>
        <p :if={@run.status != "completed"} class="text-center text-xs text-gray-400">
          Pass advances automatically · use ← Prev to go back
        </p>
      </div>

      <%!-- Summary screen --%>
      <div :if={@results != [] && @current_index >= length(@results)} class="mx-auto max-w-2xl py-12 space-y-8">
        <div class="text-center space-y-2">
          <div class="text-5xl">✅</div>
          <h1 class="text-3xl font-bold text-gray-900">Run Complete!</h1>
          <p class="text-gray-500"><%= @run.name %></p>
        </div>

        <%!-- Summary counts --%>
        <div class={["grid gap-4 text-center", if(@progress.pending > 0, do: "grid-cols-4", else: "grid-cols-3")]}>
          <div class="rounded-lg bg-green-50 border border-green-200 p-4">
            <p class="text-3xl font-bold text-green-600"><%= @progress.pass %></p>
            <p class="text-sm text-green-700 mt-1">Passed</p>
          </div>
          <div class="rounded-lg bg-red-50 border border-red-200 p-4">
            <p class="text-3xl font-bold text-red-600"><%= @progress.fail %></p>
            <p class="text-sm text-red-700 mt-1">Failed</p>
          </div>
          <div class="rounded-lg bg-gray-50 border border-gray-200 p-4">
            <p class="text-3xl font-bold text-gray-600"><%= @progress.skip %></p>
            <p class="text-sm text-gray-600 mt-1">Skipped</p>
          </div>
          <div :if={@progress.pending > 0} class="rounded-lg bg-yellow-50 border border-yellow-200 p-4">
            <p class="text-3xl font-bold text-yellow-600"><%= @progress.pending %></p>
            <p class="text-sm text-yellow-700 mt-1">Not Run</p>
          </div>
        </div>

        <%!-- Failed cases --%>
        <div :if={@progress.fail > 0} class="space-y-3">
          <h2 class="text-base font-semibold text-red-700">Failed Cases</h2>
          <div class="divide-y divide-gray-100 rounded-lg border border-red-200">
            <div :for={result <- Enum.filter(@results, &(&1.status == "fail"))} class="px-4 py-3">
              <p class="font-medium text-gray-900"><%= result.case_name %></p>
              <p class="text-xs text-gray-500 mt-0.5"><%= result.scenario_name %></p>
              <p :if={result.notes} class="mt-1 text-sm text-red-700 italic border-l-2 border-red-300 pl-2">
                <%= result.notes %>
              </p>
              <p :if={!result.notes} class="mt-1 text-xs text-gray-400 italic">No notes recorded</p>
            </div>
          </div>
        </div>

        <%!-- Actions --%>
        <div class="flex gap-3 justify-center flex-wrap">
          <.link navigate={~p"/projects/#{@project.id}/runs"} class="btn btn-outline">
            ← Back to Runs
          </.link>
          <.button phx-click="jump_to" phx-value-index="0" class="btn btn-ghost btn-sm">
            Review from start
          </.button>
          <.button phx-click="show_rerun_modal" class="btn btn-primary btn-sm">
            Rerun
          </.button>
        </div>
      </div>

      <%!-- Rerun modal --%>
      <div :if={@show_rerun_modal} class="fixed inset-0 z-50 bg-black/40" phx-click="hide_rerun_modal" />
      <div :if={@show_rerun_modal} class="fixed inset-0 z-[51] flex items-center justify-center pointer-events-none">
        <div
          class="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6 space-y-5 pointer-events-auto"
        >
          <h2 class="text-xl font-bold text-gray-900">Rerun: <%= @run.name %></h2>

          <div class="space-y-1">
            <label class="block text-sm font-medium text-gray-700">Run name</label>
            <input
              type="text"
              value={@rerun_name}
              phx-keyup="update_rerun_name"
              phx-value-value={@rerun_name}
              placeholder="Run name"
              class="input input-bordered w-full"
            />
          </div>

          <div class="space-y-2">
            <p class="text-sm font-medium text-gray-700">Cases to include</p>

            <%= for {label, value, count} <- [
              {"Failed + Skipped", "failed_and_skipped", @rerun_preview_counts.failed_and_skipped},
              {"Failed only", "failed", @rerun_preview_counts.failed},
              {"Skipped only", "skipped", @rerun_preview_counts.skipped},
              {"All cases", "all", @rerun_preview_counts.all},
              {"Passed only", "passed", @rerun_preview_counts.passed}
            ] do %>
              <label class="flex items-center justify-between gap-2 rounded-lg border border-gray-200 px-3 py-2 cursor-pointer hover:bg-gray-50">
                <div class="flex items-center gap-2">
                  <input
                    type="radio"
                    name="rerun_filter"
                    value={value}
                    checked={@rerun_filter == String.to_atom(value)}
                    phx-click="update_rerun_filter"
                    phx-value-filter={value}
                    class="radio radio-sm"
                  />
                  <span class="text-sm"><%= label %></span>
                </div>
                <span class="badge badge-ghost text-xs"><%= count %></span>
              </label>
            <% end %>
          </div>

          <p
            :if={Map.get(@rerun_preview_counts, @rerun_filter, 0) == 0}
            class="text-sm text-amber-600"
          >
            No cases match this filter. Select a different option.
          </p>

          <div class="flex gap-3">
            <.button
              phx-click="create_rerun"
              phx-disable-with="Creating..."
              disabled={@rerun_name == "" || Map.get(@rerun_preview_counts, @rerun_filter, 0) == 0}
              class="btn btn-primary flex-1"
            >
              Create Rerun
            </.button>
            <.button phx-click="hide_rerun_modal" class="btn btn-ghost">
              Cancel
            </.button>
          </div>
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

    # Start at first pending case, or 0 if none pending
    socket =
      socket
      |> assign(
        project: project,
        run: run,
        show_notes: false,
        show_rerun_modal: false,
        rerun_name: "",
        rerun_filter: :failed_and_skipped,
        rerun_preview_counts: %{all: 0, failed: 0, skipped: 0, failed_and_skipped: 0, passed: 0}
      )
      |> reload()

    first_pending =
      Enum.find_index(socket.assigns.results, &(&1.status == "pending")) || 0

    {:ok, assign(socket, current_index: first_pending)}
  end

  @impl true
  def handle_event("mark_pass", _params, socket) when socket.assigns.run.status == "completed",
    do: {:noreply, socket}

  def handle_event("mark_pass", %{"id" => id}, socket) do
    update_status(socket, id, "pass")
    socket = reload(socket)
    {:noreply, socket |> assign(show_notes: false) |> advance()}
  end

  def handle_event("mark_fail", _params, socket) when socket.assigns.run.status == "completed",
    do: {:noreply, socket}

  def handle_event("mark_fail", %{"id" => id}, socket) do
    update_status(socket, id, "fail")
    {:noreply, socket |> reload() |> assign(show_notes: true)}
  end

  def handle_event("mark_skip", _params, socket) when socket.assigns.run.status == "completed",
    do: {:noreply, socket}

  def handle_event("mark_skip", %{"id" => id}, socket) do
    update_status(socket, id, "skip")
    socket = reload(socket)
    {:noreply, socket |> assign(show_notes: false) |> advance()}
  end

  def handle_event("save_notes", _params, socket) when socket.assigns.run.status == "completed",
    do: {:noreply, socket}

  def handle_event("save_notes", %{"result_id" => id, "notes" => notes}, socket) do
    result = Repo.get!(Result, id)
    user = socket.assigns.current_scope.user
    {:ok, _} = Testing.update_result(result, user, %{"status" => result.status, "notes" => notes})
    {:noreply, socket |> reload() |> assign(show_notes: false)}
  end

  def handle_event("show_notes", _params, socket) do
    {:noreply, assign(socket, show_notes: true)}
  end

  def handle_event("dismiss_notes", _params, socket) do
    {:noreply, assign(socket, show_notes: false)}
  end

  def handle_event("navigate", %{"direction" => "next"}, socket) do
    total = length(socket.assigns.results)
    new_index = min(socket.assigns.current_index + 1, total)
    {:noreply, assign(socket, current_index: new_index, show_notes: false)}
  end

  def handle_event("navigate", %{"direction" => "prev"}, socket) do
    new_index = max(socket.assigns.current_index - 1, 0)
    {:noreply, assign(socket, current_index: new_index, show_notes: false)}
  end

  def handle_event("jump_to", %{"index" => index}, socket) do
    idx = String.to_integer(index)
    total = length(socket.assigns.results)
    safe_idx = max(0, min(idx, total))
    {:noreply, assign(socket, current_index: safe_idx, show_notes: false)}
  end

  def handle_event("pause_run", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/projects/#{socket.assigns.project.id}/runs")}
  end

  def handle_event("finish_run", _params, socket) do
    :ok = Testing.finish_run(socket.assigns.run)
    socket = reload(socket)
    total = length(socket.assigns.results)
    {:noreply, assign(socket, current_index: total)}
  end

  def handle_event("show_rerun_modal", _params, socket) do
    if socket.assigns.run.status != "completed" do
      {:noreply, socket}
    else
      existing_names = Testing.list_run_names(socket.assigns.project)
      suggested_name = Testing.next_rerun_name(socket.assigns.run.name, existing_names)
      preview_counts = Testing.rerun_preview_counts(socket.assigns.run)

      {:noreply,
       assign(socket,
         show_rerun_modal: true,
         rerun_name: suggested_name,
         rerun_filter: :failed_and_skipped,
         rerun_preview_counts: preview_counts
       )}
    end
  end

  def handle_event("hide_rerun_modal", _params, socket) do
    {:noreply, assign(socket, show_rerun_modal: false)}
  end

  def handle_event("update_rerun_name", %{"value" => value}, socket) do
    {:noreply, assign(socket, rerun_name: value)}
  end

  def handle_event("update_rerun_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, rerun_filter: parse_filter(filter))}
  end

  def handle_event("create_rerun", _params, socket) do
    user = socket.assigns.current_scope.user
    name = String.trim(socket.assigns.rerun_name)
    filter = socket.assigns.rerun_filter
    count = Map.get(socket.assigns.rerun_preview_counts, filter, 0)

    cond do
      name == "" ->
        {:noreply, put_flash(socket, :error, "Run name cannot be empty.")}

      count == 0 ->
        {:noreply, put_flash(socket, :error, "No cases match the selected filter.")}

      true ->
        case Testing.rerun_run(socket.assigns.run, user, name, filter) do
          {:ok, new_run} ->
            {:noreply,
             socket
             |> assign(show_rerun_modal: false)
             |> push_navigate(to: ~p"/projects/#{socket.assigns.project.id}/runs/#{new_run.id}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not create rerun.")}
        end
    end
  end

  # Private helpers

  defp update_status(socket, id, status) do
    result = Repo.get!(Result, id)
    user = socket.assigns.current_scope.user
    {:ok, _} = Testing.update_result(result, user, %{"status" => status})
  end

  defp advance(socket) do
    total = length(socket.assigns.results)
    new_index = min(socket.assigns.current_index + 1, total)
    assign(socket, current_index: new_index)
  end

  defp reload(socket) do
    run = Testing.get_run!(socket.assigns.run.id)
    results = Testing.list_results(run)
    case_ids = Enum.map(results, & &1.case_id)
    steps_by_case = Testing.list_steps_by_case(case_ids)
    progress = Testing.run_progress(run)

    assign(socket,
      run: run,
      results: results,
      steps_by_case: steps_by_case,
      progress: progress
    )
  end

  defp current_result(results, index), do: Enum.at(results, index)

  defp parse_filter("failed"), do: :failed
  defp parse_filter("skipped"), do: :skipped
  defp parse_filter("failed_and_skipped"), do: :failed_and_skipped
  defp parse_filter("passed"), do: :passed
  defp parse_filter(_), do: :all
end
