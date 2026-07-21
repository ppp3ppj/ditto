defmodule DittoWeb.WorkspaceLive.Index do
  use DittoWeb, :live_view

  alias Ditto.Projects
  alias Ditto.Tracking

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_forms()
      |> load_workspace_data()

    {:ok, socket}
  end

  @impl true
  def handle_event("save_project", %{"project" => attrs}, socket) do
    case Projects.create_project(socket.assigns.current_scope, attrs) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created.")
         |> assign(:project_form, to_form(%{"name" => ""}, as: "project"))
         |> load_workspace_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :project_form, to_form(changeset, as: "project"))}
    end
  end

  def handle_event("save_category", %{"category" => attrs}, socket) do
    case Projects.create_category(socket.assigns.current_scope, attrs) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created.")
         |> assign(
           :category_form,
           to_form(%{"name" => "", "project_id" => attrs["project_id"]}, as: "category")
         )
         |> load_workspace_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :category_form, to_form(changeset, as: "category"))}
    end
  end

  def handle_event("change_member_project", %{"member" => %{"project_id" => project_id}}, socket) do
    {:noreply, assign(socket, :selected_member_project_id, project_id) |> load_workspace_data()}
  end

  def handle_event("invite_member", %{"member" => attrs}, socket) do
    case Projects.invite_project_member(
           socket.assigns.current_scope,
           attrs["project_id"],
           attrs["email"]
         ) do
      {:ok, _member} ->
        {:noreply,
         socket
         |> put_flash(:info, "Member invited.")
         |> assign(
           :member_form,
           to_form(%{"email" => "", "project_id" => attrs["project_id"]}, as: "member")
         )
         |> assign(:selected_member_project_id, attrs["project_id"])
         |> load_workspace_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :member_form, to_form(changeset, as: "member"))}
    end
  end

  def handle_event(
        "change_time_project",
        %{"time_entry" => %{"project_id" => project_id}},
        socket
      ) do
    {:noreply, assign(socket, :selected_time_project_id, project_id) |> load_workspace_data()}
  end

  def handle_event("save_time_entry", %{"time_entry" => attrs}, socket) do
    case Tracking.create_time_entry(socket.assigns.current_scope, attrs) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Time entry saved.")
         |> assign(
           :time_entry_form,
           to_form(default_time_entry_attrs(socket.assigns.selected_time_project_id),
             as: "time_entry"
           )
         )
         |> load_workspace_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :time_entry_form, to_form(changeset, as: "time_entry"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      container_class="mx-auto max-w-7xl space-y-4"
    >
      <div class="grid gap-6 lg:grid-cols-[250px_1fr]">
        <aside class="card bg-base-200 shadow-sm h-fit">
          <div class="card-body p-4">
            <p class="text-xs uppercase tracking-wide text-base-content/60">Workspace</p>
            <ul class="menu w-full">
              <li><a href="#projects"><.icon name="ri-folder-line" /> Projects</a></li>
              <li><a href="#categories"><.icon name="ri-price-tag-3-line" /> Categories</a></li>
              <li><a href="#members"><.icon name="ri-team-line" /> Members</a></li>
              <li><a href="#time-entries"><.icon name="ri-time-line" /> Time Entries</a></li>
              <li class="mt-3">
                <a href={~p"/users/settings"}><.icon name="ri-settings-3-line" /> Settings</a>
              </li>
            </ul>
          </div>
        </aside>

        <section class="space-y-6">
          <div class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body">
              <h1 class="text-2xl font-semibold">Project Workspace</h1>
              <p class="text-sm text-base-content/70">
                Manage projects, collaboration, and tracked time in one place.
              </p>
            </div>
          </div>

          <div id="projects" class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body gap-4">
              <h2 class="card-title"><.icon name="ri-folder-add-line" /> Add Project</h2>
              <.form for={@project_form} phx-submit="save_project">
                <div class="flex flex-col gap-3 sm:flex-row">
                  <.input field={@project_form[:name]} type="text" label="Project name" required />
                  <button class="btn btn-primary self-end sm:self-auto">Create</button>
                </div>
              </.form>

              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Name</th><th>Role</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={project <- @projects}>
                      <td>{project.name}</td>
                      <td>
                        {if project.user_id == @current_scope.user.id, do: "Owner", else: "Member"}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div id="categories" class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body gap-4">
              <h2 class="card-title"><.icon name="ri-price-tag-3-line" /> Add Category</h2>
              <.form for={@category_form} phx-submit="save_category">
                <div class="grid gap-3 md:grid-cols-3">
                  <.input field={@category_form[:name]} type="text" label="Category name" required />
                  <.input
                    field={@category_form[:project_id]}
                    type="select"
                    label="Project"
                    options={@project_options}
                    prompt="Choose a project"
                    required
                  />
                  <button class="btn btn-primary self-end">Create</button>
                </div>
              </.form>

              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Category</th><th>Project</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={category <- @categories}>
                      <td>{category.name}</td>
                      <td>{@project_names[category.project_id]}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div id="members" class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body gap-4">
              <h2 class="card-title"><.icon name="ri-user-add-line" /> Invite Member</h2>
              <.form for={@member_form} phx-submit="invite_member" phx-change="change_member_project">
                <div class="grid gap-3 md:grid-cols-3">
                  <.input field={@member_form[:email]} type="email" label="User email" required />
                  <.input
                    field={@member_form[:project_id]}
                    type="select"
                    label="Project (owner only)"
                    options={@owned_project_options}
                    prompt="Choose a project"
                    required
                  />
                  <button class="btn btn-primary self-end">Invite</button>
                </div>
              </.form>

              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Member</th><th>Email</th><th>Project</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={member <- @members}>
                      <td>{member.user && Ditto.Accounts.User.full_name(member.user)}</td>
                      <td>{member.user && member.user.email}</td>
                      <td>{member.project && member.project.name}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div id="time-entries" class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body gap-4">
              <h2 class="card-title"><.icon name="ri-time-line" /> Track Time</h2>
              <.form
                for={@time_entry_form}
                phx-submit="save_time_entry"
                phx-change="change_time_project"
              >
                <div class="grid gap-3 md:grid-cols-2">
                  <.input field={@time_entry_form[:date]} type="date" label="Date" required />
                  <.input
                    field={@time_entry_form[:duration]}
                    type="number"
                    label="Duration (minutes)"
                    required
                  />
                  <.input
                    field={@time_entry_form[:project_id]}
                    type="select"
                    label="Project"
                    options={@project_options}
                    prompt="Choose a project"
                    required
                  />
                  <.input
                    field={@time_entry_form[:category_id]}
                    type="select"
                    label="Category"
                    options={@time_category_options}
                    prompt="Choose a category"
                    required
                  />
                  <div class="md:col-span-2">
                    <.input field={@time_entry_form[:note]} type="textarea" label="Note" required />
                  </div>
                  <button class="btn btn-primary md:col-span-2">Save Entry</button>
                </div>
              </.form>

              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Date</th><th>Duration</th><th>Project</th><th>Category</th><th>Note</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={entry <- @time_entries}>
                      <td>{entry.date}</td>
                      <td>{entry.duration} min</td>
                      <td>{entry.project && entry.project.name}</td>
                      <td>{entry.category && entry.category.name}</td>
                      <td>{entry.note}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp assign_forms(socket) do
    socket
    |> assign(:project_form, to_form(%{"name" => ""}, as: "project"))
    |> assign(:category_form, to_form(%{"name" => "", "project_id" => ""}, as: "category"))
    |> assign(:member_form, to_form(%{"email" => "", "project_id" => ""}, as: "member"))
    |> assign(:time_entry_form, to_form(default_time_entry_attrs(""), as: "time_entry"))
    |> assign(:selected_member_project_id, nil)
    |> assign(:selected_time_project_id, nil)
  end

  defp load_workspace_data(socket) do
    scope = socket.assigns.current_scope
    projects = Projects.list_projects(scope)
    owned_projects = Projects.list_owned_projects(scope)
    project_options = Enum.map(projects, &{&1.name, &1.id})
    owned_project_options = Enum.map(owned_projects, &{&1.name, &1.id})
    project_names = Map.new(projects, &{&1.id, &1.name})
    categories = Projects.list_categories(scope)

    selected_member_project_id =
      normalize_selected_id(socket.assigns.selected_member_project_id, owned_projects)

    selected_time_project_id =
      normalize_selected_id(socket.assigns.selected_time_project_id, projects)

    time_categories =
      if selected_time_project_id do
        Projects.list_categories(scope, selected_time_project_id)
      else
        []
      end

    time_category_options = Enum.map(time_categories, &{&1.name, &1.id})

    members =
      if selected_member_project_id do
        Projects.list_project_members(scope, selected_member_project_id)
      else
        []
      end

    time_entries = Tracking.list_time_entries(scope)

    socket
    |> assign(:projects, projects)
    |> assign(:owned_projects, owned_projects)
    |> assign(:project_options, project_options)
    |> assign(:owned_project_options, owned_project_options)
    |> assign(:project_names, project_names)
    |> assign(:categories, categories)
    |> assign(:members, members)
    |> assign(:time_entries, time_entries)
    |> assign(:time_category_options, time_category_options)
    |> assign(:selected_member_project_id, selected_member_project_id)
    |> assign(:selected_time_project_id, selected_time_project_id)
    |> sync_form_project_defaults(selected_member_project_id, selected_time_project_id)
  end

  defp sync_form_project_defaults(socket, selected_member_project_id, selected_time_project_id) do
    member_form_params =
      (socket.assigns.member_form.params || %{})
      |> Map.put_new("email", "")
      |> Map.put("project_id", selected_member_project_id || "")

    category_form_params =
      (socket.assigns.category_form.params || %{})
      |> Map.put_new("name", "")
      |> Map.put_new("project_id", selected_time_project_id || "")

    current_time_entry_params = socket.assigns.time_entry_form.params || %{}
    default_time_entry_params = default_time_entry_attrs(selected_time_project_id || "")

    time_entry_form_params =
      default_time_entry_params
      |> Map.merge(current_time_entry_params)

    socket
    |> assign(:member_form, to_form(member_form_params, as: "member"))
    |> assign(:category_form, to_form(category_form_params, as: "category"))
    |> assign(:time_entry_form, to_form(time_entry_form_params, as: "time_entry"))
  end

  defp normalize_selected_id(nil, [first | _]), do: first.id
  defp normalize_selected_id("", [first | _]), do: first.id

  defp normalize_selected_id(selected_id, list) when is_binary(selected_id) do
    if Enum.any?(list, &(&1.id == selected_id)),
      do: selected_id,
      else: List.first(list) && List.first(list).id
  end

  defp normalize_selected_id(_selected_id, []), do: nil

  defp default_time_entry_attrs(project_id) do
    %{
      "date" => Date.utc_today() |> Date.to_iso8601(),
      "duration" => "",
      "note" => "",
      "project_id" => project_id || "",
      "category_id" => ""
    }
  end
end
