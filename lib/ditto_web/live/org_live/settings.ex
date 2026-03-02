defmodule DittoWeb.OrgLive.Settings do
  use DittoWeb, :live_view

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>
          Organization Settings
          <:subtitle>{@org.name}</:subtitle>
        </.header>

        <div class="mt-8">
          <.form for={@form} phx-submit="save" phx-change="validate">
            <.input field={@form[:name]} type="text" label="Organization Name" required />
            <.input
              field={@form[:slug]}
              type="text"
              label="URL Slug"
              required
            />

            <div class="mt-6 flex gap-4">
              <.button variant="primary" phx-disable-with="Saving...">Save Changes</.button>
              <.link navigate={~p"/orgs/#{@org.slug}/dashboard"} class="btn">
                Cancel
              </.link>
            </div>
          </.form>
        </div>

        <div class="divider mt-8" />

        <%!-- Invite Code section --%>
        <div>
          <h2 class="text-lg font-semibold mb-2">Invite Code</h2>
          <p class="text-sm text-base-content/60 mb-4">
            Share this code with users so they can join your organization from the Welcome page.
          </p>
          <div class="flex items-center gap-3">
            <div class="input input-bordered font-mono text-lg tracking-widest select-all flex items-center px-4 py-2">
              {@org.join_code || "—"}
            </div>
            <.button phx-click="regenerate_code" phx-disable-with="Regenerating...">
              Regenerate
            </.button>
          </div>
          <p class="text-xs text-base-content/40 mt-2">
            Regenerating will invalidate the current code immediately.
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    org = scope.organization
    current_user = scope.user

    if current_user.role != "admin" && !current_user.is_sysadmin do
      {:ok,
       socket
       |> put_flash(:error, "Only admins can access organization settings.")
       |> push_navigate(to: ~p"/orgs/#{org.slug}/dashboard")}
    else
      changeset = Accounts.change_organization(org)
      {:ok, assign(socket, org: org, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"organization" => params}, socket) do
    changeset =
      socket.assigns.org
      |> Accounts.change_organization(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"organization" => params}, socket) do
    scope = socket.assigns.current_scope
    org = socket.assigns.org

    case Accounts.update_organization(scope, org, params) do
      {:ok, updated_org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully.")
         |> push_navigate(to: ~p"/orgs/#{updated_org.slug}/settings")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to update this organization.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("regenerate_code", _params, socket) do
    scope = socket.assigns.current_scope
    org = socket.assigns.org

    case Accounts.regenerate_org_join_code(scope, org) do
      {:ok, updated_org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invite code regenerated.")
         |> assign(org: updated_org)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to regenerate invite code.")}
    end
  end
end
