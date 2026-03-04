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
            <div class="flex items-center gap-2 shrink-0">
              <.link
                :if={entry.run.status == "in_progress"}
                navigate={~p"/projects/#{@project.id}/runs/#{entry.run.id}"}
                class="btn btn-xs btn-primary"
              >
                Resume
              </.link>
              <.button
                :if={entry.run.status == "completed"}
                phx-click="show_rerun_modal"
                phx-value-id={entry.run.id}
                class="btn btn-xs btn-outline btn-primary"
              >
                Rerun
              </.button>
              <.button
                phx-click="delete_run"
                phx-value-id={entry.run.id}
                data-confirm={"Delete run \"#{entry.run.name}\"? All results will be lost."}
                class="btn btn-xs btn-error btn-outline"
              >
                Delete
              </.button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Rerun modal --%>
      <div :if={@rerun_run != nil} class="fixed inset-0 z-50 bg-black/40" phx-click="hide_rerun_modal" />
      <div :if={@rerun_run != nil} class="fixed inset-0 z-[51] flex items-center justify-center pointer-events-none">
        <div
          class="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6 space-y-5 pointer-events-auto"
        >
          <h2 class="text-xl font-bold text-gray-900">Rerun: <%= @rerun_run.name %></h2>

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
  def mount(%{"pid" => pid}, _session, socket) do
    user = socket.assigns.current_scope.user
    project = Projects.get_project_for_member!(user, pid)
    runs = load_runs(project)

    {:ok,
     assign(socket,
       project: project,
       runs: runs,
       rerun_run: nil,
       rerun_name: "",
       rerun_filter: :failed_and_skipped,
       rerun_preview_counts: %{all: 0, failed: 0, skipped: 0, failed_and_skipped: 0, passed: 0}
     )}
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

  def handle_event("show_rerun_modal", %{"id" => id}, socket) do
    run = Testing.get_run!(id)

    if run.status != "completed" || run.project_id != socket.assigns.project.id do
      {:noreply, socket}
    else
      existing_names = Testing.list_run_names(socket.assigns.project)
      suggested_name = Testing.next_rerun_name(run.name, existing_names)
      preview_counts = Testing.rerun_preview_counts(run)

      {:noreply,
       assign(socket,
         rerun_run: run,
         rerun_name: suggested_name,
         rerun_filter: :failed_and_skipped,
         rerun_preview_counts: preview_counts
       )}
    end
  end

  def handle_event("hide_rerun_modal", _params, socket) do
    {:noreply, assign(socket, rerun_run: nil)}
  end

  def handle_event("update_rerun_name", %{"value" => value}, socket) do
    {:noreply, assign(socket, rerun_name: value)}
  end

  def handle_event("update_rerun_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, rerun_filter: parse_filter(filter))}
  end

  def handle_event("create_rerun", _params, socket) do
    user = socket.assigns.current_scope.user
    run = socket.assigns.rerun_run
    name = String.trim(socket.assigns.rerun_name)
    filter = socket.assigns.rerun_filter
    count = Map.get(socket.assigns.rerun_preview_counts, filter, 0)

    cond do
      run == nil ->
        {:noreply, socket}

      name == "" ->
        {:noreply, put_flash(socket, :error, "Run name cannot be empty.")}

      count == 0 ->
        {:noreply, put_flash(socket, :error, "No cases match the selected filter.")}

      true ->
        case Testing.rerun_run(run, user, name, filter) do
          {:ok, new_run} ->
            {:noreply,
             socket
             |> assign(rerun_run: nil)
             |> push_navigate(to: ~p"/projects/#{socket.assigns.project.id}/runs/#{new_run.id}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not create rerun.")}
        end
    end
  end

  defp load_runs(project) do
    runs = Testing.list_runs(project)

    Enum.map(runs, fn run ->
      progress = Testing.run_progress(run)
      %{run: run, progress: progress}
    end)
  end

  defp parse_filter("failed"), do: :failed
  defp parse_filter("skipped"), do: :skipped
  defp parse_filter("failed_and_skipped"), do: :failed_and_skipped
  defp parse_filter("passed"), do: :passed
  defp parse_filter(_), do: :all
end
