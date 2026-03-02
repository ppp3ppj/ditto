defmodule DittoWeb.ProjectLive.Join do
  use DittoWeb, :live_view

  alias Ditto.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md text-center">
        <div :if={@invite_status == :valid}>
          <.header>
            You're invited!
            <:subtitle>
              Join <strong><%= @project.name %></strong>
            </:subtitle>
          </.header>
          <p :if={@project.description} class="mt-2 text-gray-500"><%= @project.description %></p>

          <div class="mt-6 space-y-2">
            <.button phx-click="join" phx-disable-with="Joining..." class="btn btn-primary w-full">
              Join Project
            </.button>
            <.link navigate={~p"/projects"} class="block text-sm text-gray-500 hover:underline">
              Maybe later
            </.link>
          </div>
        </div>

        <div :if={@invite_status == :expired}>
          <.header>Invite Link Expired</.header>
          <p class="mt-2 text-gray-500">This invite link has expired. Ask a project member for a new one.</p>
          <.link navigate={~p"/projects"} class="mt-4 inline-block font-semibold text-brand hover:underline">
            ← Back to my projects
          </.link>
        </div>

        <div :if={@invite_status == :max_uses_reached}>
          <.header>Invite Link Full</.header>
          <p class="mt-2 text-gray-500">This invite link has reached its maximum number of uses. Ask a project member for a new one.</p>
          <.link navigate={~p"/projects"} class="mt-4 inline-block font-semibold text-brand hover:underline">
            ← Back to my projects
          </.link>
        </div>

        <div :if={@invite_status == :not_found}>
          <.header>Invalid Invite Link</.header>
          <p class="mt-2 text-gray-500">This invite link is invalid or has been deleted.</p>
          <.link navigate={~p"/projects"} class="mt-4 inline-block font-semibold text-brand hover:underline">
            ← Back to my projects
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    user = socket.assigns.current_scope.user

    case Projects.validate_invitation(token) do
      {:ok, project, _inv} ->
        if Projects.member?(project, user) do
          {:ok,
           socket
           |> put_flash(:info, "You're already a member of #{project.name}.")
           |> push_navigate(to: ~p"/projects/#{project.id}")}
        else
          {:ok, assign(socket, invite_status: :valid, project: project, token: token)}
        end

      {:error, reason} ->
        {:ok, assign(socket, invite_status: reason, project: nil, token: token)}
    end
  end

  @impl true
  def handle_event("join", _params, socket) do
    user = socket.assigns.current_scope.user

    case Projects.join_via_token(user, socket.assigns.token) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "You joined #{project.name}!")
         |> push_navigate(to: ~p"/projects/#{project.id}")}

      {:error, :already_member} ->
        project = socket.assigns.project

        {:noreply,
         socket
         |> put_flash(:info, "You're already a member of #{project.name}.")
         |> push_navigate(to: ~p"/projects/#{project.id}")}

      {:error, :expired} ->
        {:noreply, assign(socket, invite_status: :expired)}

      {:error, :max_uses_reached} ->
        {:noreply, assign(socket, invite_status: :max_uses_reached)}

      {:error, :not_found} ->
        {:noreply, assign(socket, invite_status: :not_found)}
    end
  end
end
