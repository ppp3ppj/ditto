defmodule DittoWeb.ProjectLive.New do
  use DittoWeb, :live_view

  alias Ditto.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <.header>
          New Project
          <:subtitle>
            <.link navigate={~p"/projects"} class="font-semibold text-brand hover:underline">
              ← Back to projects
            </.link>
          </:subtitle>
        </.header>

        <.form for={@form} id="project_form" phx-submit="save" phx-change="validate" class="mt-6 space-y-4">
          <.input
            field={@form[:name]}
            type="text"
            label="Project name"
            placeholder="My awesome project"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description (optional)"
            placeholder="What is this project about?"
            rows="3"
          />
          <.button phx-disable-with="Creating..." class="btn btn-primary w-full">
            Create Project
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Projects.change_project()
    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("validate", %{"project" => params}, socket) do
    changeset = Projects.change_project(%Ditto.Projects.Project{}, params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"project" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Projects.create_project(user, params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully!")
         |> push_navigate(to: ~p"/projects/#{project.id}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: "project"))
  end
end
