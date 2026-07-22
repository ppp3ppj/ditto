defmodule DittoWeb.HomeLive do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:project_form, to_form(Projects.change_project(%Project{})))
     |> load_projects()}
  end

  @impl true
  def handle_event("validate_project", %{"project" => attrs}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :project_form, to_form(changeset))}
  end

  def handle_event("save_project", %{"project" => attrs}, socket) do
    case Projects.create_project(socket.assigns.current_scope, attrs) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created.")
         |> assign(:project_form, to_form(Projects.change_project(%Project{})))
         |> load_projects()}

      {:error, changeset} ->
        {:noreply, assign(socket, :project_form, to_form(changeset))}
    end
  end

  defp load_projects(socket) do
    scope = socket.assigns.current_scope
    projects = Projects.list_projects(scope)

    project_cards =
      Enum.map(projects, fn project ->
        %{
          project: project,
          members_count: 1 + length(Projects.list_project_members(scope, project.id)),
          categories_count: length(Projects.list_categories(scope, project.id))
        }
      end)

    recent = project_cards |> Enum.sort_by(& &1.project.inserted_at, {:desc, DateTime}) |> Enum.take(3)

    socket
    |> assign(:project_cards, project_cards)
    |> assign(:recent_cards, recent)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_with_rail flash={@flash} current_scope={@current_scope} active={:home}>
      <h1 class="text-2xl font-semibold">Your projects</h1>

      <section :if={@recent_cards != []}>
        <h2 class="text-xs font-semibold uppercase tracking-wide text-base-content/50 mb-3">
          Recent
        </h2>
        <div class="flex gap-3 overflow-x-auto pb-2">
          <.link
            :for={card <- @recent_cards}
            navigate={~p"/projects/#{card.project.id}"}
            class="card bg-base-200 border border-base-300 w-40 shrink-0 hover:border-primary"
          >
            <div class="card-body p-3">
              <p class="text-sm font-medium truncate">{card.project.name}</p>
            </div>
          </.link>
        </div>
      </section>

      <div class="card bg-base-100 border border-base-300 shadow-sm">
        <div class="card-body gap-3">
          <h2 class="card-title text-sm"><.icon name="ri-add-line" /> Start a new project</h2>
          <.form for={@project_form} phx-submit="save_project" phx-change="validate_project">
            <div class="flex gap-3 items-start">
              <div class="grow">
                <.input field={@project_form[:name]} type="text" placeholder="Project name" />
              </div>
              <button class="btn btn-primary">Create</button>
            </div>
          </.form>
        </div>
      </div>

      <div :if={@project_cards == []} class="card border-2 border-dashed border-base-300">
        <div class="card-body items-center text-center text-base-content/50 py-10">
          <.icon name="ri-book-2-line" class="size-6" />
          <p class="text-sm">No projects yet — create your first one above.</p>
        </div>
      </div>

      <div :if={@project_cards != []} class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <.link
          :for={card <- @project_cards}
          navigate={~p"/projects/#{card.project.id}"}
          class="card bg-base-200 border border-base-300 hover:border-primary hover:shadow-md transition-all"
        >
          <div class="card-body">
            <h3 class="card-title text-base">{card.project.name}</h3>
            <p class="text-xs text-base-content/60">
              {card.members_count} members · {card.categories_count} categories
            </p>
          </div>
        </.link>
      </div>
    </Layouts.app_with_rail>
    """
  end
end
