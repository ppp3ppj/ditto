defmodule DittoWeb.UserLive.Registration do
  use DittoWeb, :live_view

  alias Ditto.Accounts
  alias Ditto.Accounts.{User, Organization}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Create your account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <div class="mb-6">
            <h2 class="text-lg font-semibold mb-2">Organization</h2>
            <.input
              field={@form[:org_name]}
              type="text"
              label="Organization Name"
              autocomplete="organization"
              placeholder="Acme Corp"
              required
            />
            <.input
              field={@form[:org_slug]}
              type="text"
              label="Organization URL Slug"
              autocomplete="off"
              placeholder="acme-corp"
              required
            />
          </div>

          <div>
            <h2 class="text-lg font-semibold mb-2">Your Account</h2>
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              spellcheck="false"
              required
              phx-mounted={JS.focus()}
            />
            <.input
              field={@form[:username]}
              type="text"
              label="Username"
              autocomplete="off"
              spellcheck="false"
              required
            />
            <.input
              field={@form[:name]}
              type="text"
              label="Name (optional)"
              autocomplete="name"
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
            />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm password"
              autocomplete="new-password"
              required
            />
          </div>

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create account & organization
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: DittoWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = build_combined_changeset(%{})
    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"registration" => params}, socket) do
    user_attrs = Map.take(params, ["email", "username", "name", "password", "password_confirmation"])
    org_attrs = %{"name" => params["org_name"], "slug" => params["org_slug"]}

    case Accounts.register_user_with_organization(user_attrs, org_attrs) do
      {:ok, {_user, org}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created! Welcome to #{org.name}.")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong. Please try again.")
         |> assign_form(build_combined_changeset(params))}
    end
  end

  def handle_event("validate", %{"registration" => params}, socket) do
    changeset = build_combined_changeset(params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  # Build a combined changeset for live form validation.
  # org_name and org_slug are virtual fields on User, so their values are
  # preserved in the changeset and re-rendered correctly by the form.
  defp build_combined_changeset(params) do
    user_attrs = Map.take(params, ["email", "username", "name", "password", "password_confirmation", "org_name", "org_slug"])
    org_attrs = %{name: params["org_name"] || "", slug: params["org_slug"] || ""}

    user_cs =
      %User{}
      |> User.registration_changeset(user_attrs, validate_unique: false, hash_password: false)

    org_cs =
      %Organization{}
      |> Organization.changeset(org_attrs)

    # Merge org errors into user changeset for unified form error display
    org_errors =
      Enum.map(org_cs.errors, fn {field, {msg, opts}} ->
        mapped_field =
          case field do
            :name -> :org_name
            :slug -> :org_slug
            other -> other
          end

        {mapped_field, {msg, opts}}
      end)

    %{user_cs | errors: user_cs.errors ++ org_errors, valid?: user_cs.valid? && org_cs.valid?}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "registration")
    assign(socket, form: form)
  end
end
