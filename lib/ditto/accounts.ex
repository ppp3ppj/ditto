defmodule Ditto.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ditto.Repo

  alias Ditto.Accounts.{User, UserToken, UserNotifier, Organization, Scope}

  ## Organizations

  @doc """
  Creates an organization.
  """
  def create_organization(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single organization by id.

  Raises `Ecto.NoResultsError` if the Organization does not exist.
  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Gets an organization by its slug. Returns nil if not found.
  """
  def get_organization_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Organization, slug: slug)
  end

  @doc """
  Lists all organizations. Only callable by sysadmins.
  """
  def list_organizations(%Scope{user: %User{is_sysadmin: true}}) do
    Repo.all(Organization)
  end

  def list_organizations(_scope), do: {:error, :unauthorized}

  @doc """
  Updates an organization. Requires admin role within that org or sysadmin.
  """
  def update_organization(%Scope{user: user}, %Organization{} = org, attrs) do
    with :ok <- Bodyguard.permit(Ditto.Accounts.Policy, :update_organization, user, org) do
      org
      |> Organization.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Registers a user and creates their organization in a single transaction.
  The user becomes the admin of the new organization.
  """
  def register_user_with_organization(user_attrs, org_attrs) do
    Repo.transact(fn ->
      with {:ok, org} <- create_organization(org_attrs),
           {:ok, user} <-
             %User{}
             |> User.registration_changeset(
               Map.merge(user_attrs, %{
                 "organization_id" => org.id,
                 "role" => "admin"
               })
             )
             |> Repo.insert() do
        {:ok, {user, org}}
      end
    end)
  end

  @doc """
  Updates a user's role within their organization.
  Requires admin role in the same org, or sysadmin.
  Prevents removing the last admin.
  """
  def update_user_role(%Scope{user: actor, organization: org}, %User{} = target_user, new_role) do
    with :ok <- Bodyguard.permit(Ditto.Accounts.Policy, :update_user_role, actor, org),
         :ok <- ensure_not_removing_last_admin(target_user, new_role) do
      target_user
      |> User.role_changeset(%{role: new_role})
      |> Repo.update()
    end
  end

  defp ensure_not_removing_last_admin(%User{role: "admin", organization_id: org_id}, new_role)
       when new_role != "admin" do
    admin_count =
      Repo.one(
        from u in User,
          where: u.organization_id == ^org_id and u.role == "admin",
          select: count()
      )

    if admin_count <= 1, do: {:error, :last_admin}, else: :ok
  end

  defp ensure_not_removing_last_admin(_user, _new_role), do: :ok

  @doc """
  Updates a user's sysadmin status. Only callable by another sysadmin.
  """
  def update_sysadmin_status(%Scope{user: %User{is_sysadmin: true}}, %User{} = target_user, is_sysadmin) do
    target_user
    |> User.sysadmin_changeset(%{is_sysadmin: is_sysadmin})
    |> Repo.update()
  end

  def update_sysadmin_status(_scope, _user, _is_sysadmin), do: {:error, :unauthorized}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.
  """
  def change_organization(org, attrs \\ %{}) do
    Organization.changeset(org, attrs)
  end

  @doc """
  Lists all users in an organization. Requires admin or manager role, or sysadmin.
  """
  def list_org_users(%Scope{user: actor, organization: org}) do
    with :ok <- Bodyguard.permit(Ditto.Accounts.Policy, :view_members, actor, org) do
      users =
        Repo.all(
          from u in User,
            where: u.organization_id == ^org.id,
            order_by: [asc: u.inserted_at]
        )

      {:ok, users}
    end
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(identifier, password)
      when is_binary(identifier) and is_binary(password) do
    user =
      if String.contains?(identifier, "@") do
        Repo.get_by(User, email: identifier)
      else
        Repo.get_by(User, username: String.downcase(identifier))
      end

    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.
  """
  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, Keyword.merge([hash_password: false], opts))
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Ditto.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile (name).
  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates the user profile (name).
  """
  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Ditto.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
