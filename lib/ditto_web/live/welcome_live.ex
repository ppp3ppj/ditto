defmodule DittoWeb.WelcomeLive do
  use DittoWeb, :live_view

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg text-center">
        <div class="mb-8">
          <h1 class="text-3xl font-bold mb-3">Welcome, @{@current_scope.user.username}!</h1>
          <p class="text-base-content/60">
            Your account is ready. To get started, join an organization using an invite code,
            or wait for an admin to add you directly.
          </p>
        </div>

        <div class="card bg-base-200 shadow-sm">
          <div class="card-body text-left">
            <h2 class="card-title text-lg">Join an Organization</h2>
            <p class="text-sm text-base-content/60 mb-4">
              Enter the invite code shared by your organization's admin.
            </p>

            <.form for={@form} phx-submit="join" phx-change="validate_code">
              <div class="flex gap-2">
                <div class="flex-1">
                  <.input
                    field={@form[:code]}
                    type="text"
                    placeholder="e.g. A3F7BC12"
                    autocomplete="off"
                    spellcheck="false"
                  />
                </div>
                <div class="flex items-start pt-1">
                  <.button variant="primary" phx-disable-with="Joining...">Join</.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <div class="divider my-8">OR</div>

        <div class="text-base-content/50 text-sm">
          <p>Ask your organization admin to add you directly from their Members page.</p>
          <p class="mt-2">They can search for your username: <span class="font-mono font-semibold">@{@current_scope.user.username}</span></p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user.organization_id do
      org = Accounts.get_organization!(user.organization_id)
      {:ok, push_navigate(socket, to: ~p"/orgs/#{org.slug}/dashboard")}
    else
      form = to_form(%{"code" => ""}, as: :join_code)
      {:ok, assign(socket, form: form)}
    end
  end

  @impl true
  def handle_event("join", %{"join_code" => %{"code" => code}}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.join_org_by_code(user, String.trim(code)) do
      {:ok, _user, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome to #{org.name}!")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/dashboard")}

      {:error, :invalid_code} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid invite code. Please check and try again.")
         |> assign(form: to_form(%{"code" => code}, as: :join_code))}
    end
  end

  def handle_event("validate_code", _params, socket) do
    {:noreply, socket}
  end
end
