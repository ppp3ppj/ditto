defmodule DittoWeb.ProjectLive.Show do
  use DittoWeb, :live_view

  alias Ditto.Accounts.User
  alias Ditto.Projects
  alias Ditto.Projects.Category
  alias Ditto.Tracking
  alias Ditto.Tracking.TimeEntry

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:collapsed?, false)
     |> assign(:member_email, "")
     |> assign(:member_error, nil)
     |> assign(:confirming_member_id, nil)
     |> assign(:editing_category_id, nil)
     |> assign(:confirming_category_id, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    scope = socket.assigns.current_scope
    project = Projects.get_accessible_project!(scope, id)

    {:noreply,
     socket
     |> assign(:project, project)
     |> assign(:owner?, project.user_id == scope.user.id)
     |> assign(:chapter, socket.assigns.live_action)
     |> assign(:category_form, to_form(Projects.change_category(%Category{})))
     |> assign(:time_entry_form, to_form(change_new_time_entry(project.id)))
     |> reload_members()
     |> reload_categories()
     |> reload_time_entries()}
  end

  @impl true
  def handle_event("toggle_collapse", _params, socket) do
    {:noreply, update(socket, :collapsed?, &(!&1))}
  end

  def handle_event("update_member_email", %{"email" => email}, socket) do
    {:noreply, assign(socket, :member_email, email)}
  end

  def handle_event("add_member", %{"email" => email}, socket) do
    cond do
      not socket.assigns.owner? ->
        {:noreply, socket}

      String.trim(email) == "" ->
        {:noreply, assign(socket, :member_error, "Enter an email address")}

      true ->
        case Projects.invite_project_member(socket.assigns.current_scope, socket.assigns.project.id, email) do
          {:ok, _member} ->
            {:noreply,
             socket
             |> assign(:member_email, "")
             |> assign(:member_error, nil)
             |> reload_members()}

          {:error, changeset} ->
            {:noreply, assign(socket, :member_error, member_error_message(changeset))}
        end
    end
  end

  def handle_event("ask_remove_member", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirming_member_id, id)}
  end

  def handle_event("cancel_remove_member", _params, socket) do
    {:noreply, assign(socket, :confirming_member_id, nil)}
  end

  def handle_event("confirm_remove_member", %{"id" => id}, socket) do
    if socket.assigns.owner? do
      member = Projects.get_project_member!(id)
      if member.project_id == socket.assigns.project.id, do: Projects.delete_project_member(member)
    end

    {:noreply, socket |> assign(:confirming_member_id, nil) |> reload_members()}
  end

  def handle_event("validate_category", %{"category" => attrs}, socket) do
    changeset =
      %Category{}
      |> Projects.change_category(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :category_form, to_form(changeset))}
  end

  def handle_event("add_category", %{"category" => attrs}, socket) do
    attrs = Map.put(attrs, "project_id", socket.assigns.project.id)

    case Projects.create_category(socket.assigns.current_scope, attrs) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> assign(:category_form, to_form(Projects.change_category(%Category{})))
         |> reload_categories()}

      {:error, changeset} ->
        {:noreply, assign(socket, :category_form, to_form(changeset))}
    end
  end

  def handle_event("start_edit_category", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_category_id, id)}
  end

  def handle_event("cancel_edit_category", _params, socket) do
    {:noreply, assign(socket, :editing_category_id, nil)}
  end

  def handle_event("save_category_edit", %{"id" => id, "category" => attrs}, socket) do
    category = Projects.get_category!(id)

    socket =
      if category.project_id == socket.assigns.project.id do
        case Projects.update_category(category, attrs) do
          {:ok, _category} -> socket |> assign(:editing_category_id, nil) |> reload_categories()
          {:error, _changeset} -> put_flash(socket, :error, "Couldn't rename that category.")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("ask_remove_category", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirming_category_id, id)}
  end

  def handle_event("cancel_remove_category", _params, socket) do
    {:noreply, assign(socket, :confirming_category_id, nil)}
  end

  def handle_event("confirm_remove_category", %{"id" => id}, socket) do
    category = Projects.get_category!(id)
    if category.project_id == socket.assigns.project.id, do: Projects.delete_category(category)
    {:noreply, socket |> assign(:confirming_category_id, nil) |> reload_categories()}
  end

  def handle_event("validate_time_entry", %{"time_entry" => attrs}, socket) do
    changeset =
      %TimeEntry{}
      |> Tracking.change_time_entry(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :time_entry_form, to_form(changeset))}
  end

  def handle_event("add_time_entry", %{"time_entry" => attrs}, socket) do
    attrs = Map.put(attrs, "project_id", socket.assigns.project.id)

    case Tracking.create_time_entry(socket.assigns.current_scope, attrs) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(:time_entry_form, to_form(change_new_time_entry(socket.assigns.project.id)))
         |> reload_time_entries()}

      {:error, changeset} ->
        {:noreply, assign(socket, :time_entry_form, to_form(changeset))}
    end
  end

  defp reload_members(socket) do
    scope = socket.assigns.current_scope
    project = socket.assigns.project
    members = Projects.list_project_members(scope, project.id)
    assign(socket, :member_rows, member_rows(project, members))
  end

  defp reload_categories(socket) do
    categories = Projects.list_categories(socket.assigns.current_scope, socket.assigns.project.id)
    assign(socket, :categories, categories)
  end

  defp reload_time_entries(socket) do
    entries = Tracking.list_time_entries(socket.assigns.current_scope, socket.assigns.project.id)
    category_options = Enum.map(socket.assigns.categories, &{&1.name, &1.id})

    socket
    |> assign(:time_entries, entries)
    |> assign(:category_options, category_options)
  end

  defp member_rows(project, members) do
    owner_row = %{id: "owner", full_name: User.full_name(project.user), email: project.user.email, owner?: true}

    other_rows =
      for m <- members, m.user_id != project.user_id do
        %{id: m.id, full_name: User.full_name(m.user), email: m.user.email, owner?: false}
      end

    [owner_row | other_rows]
  end

  defp member_error_message(changeset) do
    case changeset.errors[:user_id] do
      {"was not found", _} -> "No Ditto account found for this email"
      {"has already been taken", _} -> "This person is already a member"
      _ -> "Couldn't add that member"
    end
  end

  defp change_new_time_entry(project_id) do
    Tracking.change_time_entry(%TimeEntry{}, %{"date" => Date.to_iso8601(Date.utc_today()), "project_id" => project_id})
  end

  defp chapter_path(project_id, :members), do: ~p"/projects/#{project_id}/members"
  defp chapter_path(project_id, :categories), do: ~p"/projects/#{project_id}/categories"
  defp chapter_path(project_id, :time_entries), do: ~p"/projects/#{project_id}/time-entries"

  defp format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)

    friendly =
      cond do
        hours == 0 -> "#{mins}m"
        mins == 0 -> "#{hours}h"
        true -> "#{hours}h #{mins}m"
      end

    "#{friendly} (#{minutes}m)"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_with_rail flash={@flash} current_scope={@current_scope} active={:project}>
      <div class="grid gap-6 lg:grid-cols-[260px_1fr]">
        <.chapter_panel
          project={@project}
          chapter={@chapter}
          collapsed?={@collapsed?}
          member_count={length(@member_rows)}
          category_count={length(@categories)}
          time_entry_count={length(@time_entries)}
        />

        <section>
          <.members_chapter
            :if={@chapter == :members}
            member_rows={@member_rows}
            owner?={@owner?}
            member_email={@member_email}
            member_error={@member_error}
            confirming_member_id={@confirming_member_id}
          />
          <.categories_chapter
            :if={@chapter == :categories}
            categories={@categories}
            category_form={@category_form}
            editing_category_id={@editing_category_id}
            confirming_category_id={@confirming_category_id}
          />
          <.time_entries_chapter
            :if={@chapter == :time_entries}
            time_entries={@time_entries}
            time_entry_form={@time_entry_form}
            category_options={@category_options}
          />
        </section>
      </div>
    </Layouts.app_with_rail>
    """
  end

  attr :project, :map, required: true
  attr :chapter, :atom, required: true
  attr :collapsed?, :boolean, required: true
  attr :member_count, :integer, required: true
  attr :category_count, :integer, required: true
  attr :time_entry_count, :integer, required: true

  defp chapter_panel(assigns) do
    ~H"""
    <aside class="card bg-base-200 border border-base-300 h-fit">
      <div class="card-body p-4 gap-3">
        <div class="flex items-center justify-between">
          <h1 :if={!@collapsed?} class="font-semibold truncate">{@project.name}</h1>
          <button class="btn btn-ghost btn-xs btn-square" phx-click="toggle_collapse">
            <.icon name="ri-side-bar-line" class="size-4" />
          </button>
        </div>

        <div class="space-y-2">
          <.chapter_link
            project_id={@project.id}
            chapter={:members}
            current={@chapter}
            icon="ri-team-line"
            label="Members"
            count={@member_count}
            collapsed?={@collapsed?}
          />
          <.chapter_link
            project_id={@project.id}
            chapter={:categories}
            current={@chapter}
            icon="ri-price-tag-3-line"
            label="Categories"
            count={@category_count}
            collapsed?={@collapsed?}
          />
          <.chapter_link
            project_id={@project.id}
            chapter={:time_entries}
            current={@chapter}
            icon="ri-time-line"
            label="Time Entries"
            count={@time_entry_count}
            collapsed?={@collapsed?}
          />
        </div>
      </div>
    </aside>
    """
  end

  attr :project_id, :string, required: true
  attr :chapter, :atom, required: true
  attr :current, :atom, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :collapsed?, :boolean, required: true

  defp chapter_link(assigns) do
    ~H"""
    <.link
      navigate={chapter_path(@project_id, @chapter)}
      class={[
        "card shadow-none",
        @current == @chapter && "bg-base-300",
        @current != @chapter && "bg-base-100 border border-base-300 hover:border-primary"
      ]}
    >
      <div class="card-body p-3 flex-row items-center gap-2">
        <.icon name={@icon} />
        <span :if={!@collapsed?} class="font-medium text-sm">{@label}</span>
        <span :if={!@collapsed?} class="badge badge-sm ml-auto">{@count}</span>
      </div>
    </.link>
    """
  end

  attr :member_rows, :list, required: true
  attr :owner?, :boolean, required: true
  attr :member_email, :string, required: true
  attr :member_error, :any, required: true
  attr :confirming_member_id, :any, required: true

  defp members_chapter(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-4">Members</h2>

    <div :if={@owner?} class="card bg-primary/10 border border-base-300 mb-6">
      <div class="card-body gap-2">
        <h3 class="card-title text-sm"><.icon name="ri-user-add-line" /> Add member</h3>
        <form phx-submit="add_member" phx-change="update_member_email" class="flex gap-2">
          <input
            type="email"
            name="email"
            value={@member_email}
            placeholder="person@example.com"
            class={["input w-full", @member_error && "input-error"]}
          />
          <button class="btn btn-primary">Add</button>
        </form>
        <p :if={@member_error} class="text-error text-xs">{@member_error}</p>
      </div>
    </div>

    <div :if={length(@member_rows) == 1} class="card border-2 border-dashed border-base-300 mb-2">
      <div class="card-body flex-row items-center gap-3 text-base-content/50 py-4">
        <.icon name="ri-team-line" class="size-5" />
        <p class="text-sm">It's just you so far — add a member above to start collaborating.</p>
      </div>
    </div>

    <div class="space-y-2">
      <div :for={row <- @member_rows} class="card bg-base-200 border border-base-300">
        <div class="card-body p-4 flex-row items-center gap-3">
          <div class="avatar placeholder">
            <div class="bg-neutral text-neutral-content rounded-full w-10">
              <span>{String.first(row.full_name)}</span>
            </div>
          </div>
          <div class="grow">
            <p class="font-medium">
              {row.full_name} <span :if={row.owner?} class="badge badge-sm ml-1">Owner</span>
            </p>
            <p class="text-xs text-base-content/60">{row.email}</p>
          </div>

          <div :if={@owner? && !row.owner? && @confirming_member_id != row.id}>
            <button
              class="btn btn-ghost btn-sm btn-square text-error"
              phx-click="ask_remove_member"
              phx-value-id={row.id}
            >
              <.icon name="ri-delete-bin-line" />
            </button>
          </div>
          <div
            :if={@owner? && !row.owner? && @confirming_member_id == row.id}
            class="flex items-center gap-2 text-sm"
          >
            <span>Remove?</span>
            <button class="btn btn-error btn-xs" phx-click="confirm_remove_member" phx-value-id={row.id}>
              Yes
            </button>
            <button class="btn btn-ghost btn-xs" phx-click="cancel_remove_member">No</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :categories, :list, required: true
  attr :category_form, :map, required: true
  attr :editing_category_id, :any, required: true
  attr :confirming_category_id, :any, required: true

  defp categories_chapter(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-4">Categories</h2>

    <div class="card bg-primary/10 border border-base-300 mb-6">
      <div class="card-body gap-2">
        <h3 class="card-title text-sm"><.icon name="ri-price-tag-3-line" /> Add category</h3>
        <.form for={@category_form} phx-submit="add_category" phx-change="validate_category">
          <div class="flex gap-2">
            <.input field={@category_form[:name]} type="text" placeholder="e.g. Design" />
            <button class="btn btn-primary self-start">Add</button>
          </div>
        </.form>
      </div>
    </div>

    <div :if={@categories == []} class="card border-2 border-dashed border-base-300">
      <div class="card-body items-center text-center text-base-content/50 py-8">
        <.icon name="ri-price-tag-3-line" class="size-6" />
        <p class="text-sm">No categories yet — add one above.</p>
      </div>
    </div>

    <div class="space-y-2">
      <div :for={category <- @categories} class="card bg-base-200 border border-base-300">
        <div class="card-body p-4 flex-row items-center gap-3">
          <form
            :if={@editing_category_id == category.id}
            phx-submit="save_category_edit"
            class="grow flex gap-2"
          >
            <input type="hidden" name="id" value={category.id} />
            <input type="text" name="category[name]" value={category.name} class="input input-sm w-full" />
            <button class="btn btn-primary btn-sm">Save</button>
            <button type="button" class="btn btn-ghost btn-sm" phx-click="cancel_edit_category">
              Cancel
            </button>
          </form>

          <p :if={@editing_category_id != category.id} class="grow font-medium">{category.name}</p>

          <div
            :if={@editing_category_id != category.id && @confirming_category_id != category.id}
            class="flex gap-1"
          >
            <button
              class="btn btn-ghost btn-sm btn-square"
              phx-click="start_edit_category"
              phx-value-id={category.id}
            >
              <.icon name="ri-pencil-line" />
            </button>
            <button
              class="btn btn-ghost btn-sm btn-square text-error"
              phx-click="ask_remove_category"
              phx-value-id={category.id}
            >
              <.icon name="ri-delete-bin-line" />
            </button>
          </div>
          <div :if={@confirming_category_id == category.id} class="flex items-center gap-2 text-sm">
            <span>Remove?</span>
            <button
              class="btn btn-error btn-xs"
              phx-click="confirm_remove_category"
              phx-value-id={category.id}
            >
              Yes
            </button>
            <button class="btn btn-ghost btn-xs" phx-click="cancel_remove_category">No</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :time_entries, :list, required: true
  attr :time_entry_form, :map, required: true
  attr :category_options, :list, required: true

  defp time_entries_chapter(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-4">Time Entries</h2>

    <div class="card bg-base-200 border border-base-300 mb-6">
      <div class="card-body gap-3">
        <h3 class="card-title text-sm"><.icon name="ri-time-line" /> Log time</h3>
        <.form for={@time_entry_form} phx-submit="add_time_entry" phx-change="validate_time_entry">
          <div class="grid gap-3 md:grid-cols-4">
            <.input field={@time_entry_form[:date]} type="date" />
            <.input
              field={@time_entry_form[:category_id]}
              type="select"
              options={@category_options}
              prompt="Category"
            />
            <.input field={@time_entry_form[:duration]} type="number" placeholder="Minutes" />
            <.input field={@time_entry_form[:note]} type="text" placeholder="Note" />
            <button class="btn btn-primary md:col-span-4">Add entry</button>
          </div>
        </.form>
      </div>
    </div>

    <div :if={@time_entries == []} class="card border-2 border-dashed border-base-300">
      <div class="card-body items-center text-center text-base-content/50 py-10">
        <.icon name="ri-time-line" class="size-6" />
        <p class="text-sm">No time logged yet — add your first entry above.</p>
      </div>
    </div>

    <div :if={@time_entries != []} class="overflow-x-auto">
      <table class="table table-zebra">
        <thead>
          <tr>
            <th>Date</th>
            <th>Category</th>
            <th>Duration</th>
            <th>Note</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={entry <- @time_entries}>
            <td>{entry.date}</td>
            <td><span class="badge badge-ghost">{entry.category && entry.category.name}</span></td>
            <td>{format_duration(entry.duration)}</td>
            <td class="text-base-content/70">{entry.note}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
