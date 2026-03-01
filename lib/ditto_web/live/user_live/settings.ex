defmodule DittoWeb.UserLive.Settings do
  use DittoWeb, :live_view

  on_mount {DittoWeb.UserAuth, :require_sudo_mode}

  alias Ditto.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Manage your account profile, email address and password settings</:subtitle>
        </.header>
      </div>

      <%!-- Profile --%>
      <.form for={@profile_form} id="profile_form" phx-submit="update_profile" phx-change="validate_profile">
        <div class="form-control w-full">
          <label class="label"><span class="label-text font-medium">Username</span></label>
          <div class="flex items-center gap-2">
            <span class="input input-bordered w-full opacity-60 select-none flex items-center">
              @{@current_scope.user.username}
            </span>
          </div>
          <label class="label">
            <span class="label-text-alt text-base-content/50">Username cannot be changed.</span>
          </label>
        </div>
        <.input
          field={@profile_form[:name]}
          type="text"
          label="Name"
          autocomplete="name"
          placeholder="Your display name"
        />
        <.button variant="primary" phx-disable-with="Saving...">Save Profile</.button>
      </.form>

      <div class="divider" />

      <%!-- Organization info --%>
      <div>
        <h2 class="text-lg font-semibold mb-3">Organization</h2>
        <%= if @current_scope.user.is_sysadmin do %>
          <div class="flex items-center gap-3 p-4 rounded-lg bg-base-200">
            <div>
              <p class="font-medium">System Administrator</p>
              <p class="text-sm text-base-content/60">
                Full access across all organizations.
              </p>
            </div>
            <span class="badge badge-error badge-sm ml-auto">Sysadmin</span>
          </div>
          <div class="mt-2">
            <.link navigate={~p"/sysadmin"} class="link link-primary text-sm">
              Go to Sysadmin Dashboard →
            </.link>
          </div>
        <% else %>
          <%= if org = @current_scope.organization do %>
            <div class="flex items-center justify-between p-4 rounded-lg bg-base-200">
              <div>
                <p class="font-medium">{org.name}</p>
                <p class="text-sm text-base-content/60">/{org.slug}</p>
              </div>
              <div class="flex items-center gap-2">
                <span class="badge badge-neutral badge-sm capitalize">
                  {@current_scope.user.role}
                </span>
                <.link navigate={~p"/orgs/#{org.slug}/dashboard"} class="link link-primary text-sm">
                  Dashboard →
                </.link>
              </div>
            </div>
          <% else %>
            <div class="p-4 rounded-lg bg-base-200 text-base-content/60 text-sm">
              You are not a member of any organization.
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="divider" />

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          spellcheck="false"
          required
        />
        <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
      </.form>

      <div class="divider" />

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          spellcheck="false"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          spellcheck="false"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
          spellcheck="false"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile_changeset = Accounts.change_user_profile(user)
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated_user} ->
        profile_form =
          updated_user
          |> Accounts.change_user_profile()
          |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(profile_form: profile_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
