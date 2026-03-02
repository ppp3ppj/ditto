defmodule DittoWeb.SysadminLive.Organizations do
  use DittoWeb, :live_view

  alias Ditto.Accounts
  alias Ditto.Accounts.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          All Organizations
          <:subtitle>System-wide organization management</:subtitle>
          <:actions>
            <.link navigate={~p"/sysadmin"} class="btn btn-sm">Back to Dashboard</.link>
          </:actions>
        </.header>

        <%!-- Create Organization --%>
        <div class="mt-6 card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title text-base">Create Organization</h2>
            <.form for={@new_org_form} phx-submit="create_org" phx-change="validate_org">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.input
                  field={@new_org_form[:name]}
                  type="text"
                  label="Name"
                  placeholder="Acme Corp"
                  required
                />
                <.input
                  field={@new_org_form[:slug]}
                  type="text"
                  label="URL Slug"
                  placeholder="acme-corp"
                  required
                />
              </div>
              <div class="mt-4">
                <.button variant="primary" phx-disable-with="Creating...">
                  Create Organization
                </.button>
              </div>
            </.form>
          </div>
        </div>

        <div class="mt-6 bg-base-100 shadow overflow-hidden rounded-lg">
          <ul role="list" class="divide-y divide-base-300">
            <%= for org <- @organizations do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between gap-4">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <p class="font-medium truncate">{org.name}</p>
                      <%= if !org.active do %>
                        <span class="badge badge-warning badge-sm">Inactive</span>
                      <% end %>
                    </div>
                    <p class="text-sm text-base-content/60">/{org.slug}</p>
                  </div>
                  <div class="flex items-center gap-4">
                    <div class="text-right">
                      <p class="text-xs text-base-content/40 mb-1">Invite Code</p>
                      <span class="font-mono text-sm font-semibold tracking-widest select-all">
                        {org.join_code || "—"}
                      </span>
                    </div>
                    <.link navigate={~p"/orgs/#{org.slug}/dashboard"} class="btn btn-sm">
                      View
                    </.link>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>

          <%= if @organizations == [] do %>
            <div class="px-4 py-8 text-center text-base-content/50">
              No organizations yet.
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    organizations =
      case Accounts.list_organizations(scope) do
        list when is_list(list) -> list
        _ -> []
      end

    new_org_changeset = Accounts.change_organization(%Organization{})

    {:ok, assign(socket, organizations: organizations, new_org_form: to_form(new_org_changeset))}
  end

  @impl true
  def handle_event("validate_org", %{"organization" => params}, socket) do
    changeset =
      %Organization{}
      |> Accounts.change_organization(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, new_org_form: to_form(changeset))}
  end

  def handle_event("create_org", %{"organization" => params}, socket) do
    case Accounts.create_organization(params) do
      {:ok, org} ->
        scope = socket.assigns.current_scope

        organizations =
          case Accounts.list_organizations(scope) do
            list when is_list(list) -> list
            _ -> []
          end

        new_org_changeset = Accounts.change_organization(%Organization{})

        {:noreply,
         socket
         |> put_flash(:info, "\"#{org.name}\" created. Invite code: #{org.join_code}")
         |> assign(organizations: organizations, new_org_form: to_form(new_org_changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, new_org_form: to_form(changeset))}
    end
  end
end
