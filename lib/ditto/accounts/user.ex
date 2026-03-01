defmodule Ditto.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(admin manager member)

  schema "users" do
    field :email, :string
    field :username, :string
    field :name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :role, :string, default: "member"
    field :is_sysadmin, :boolean, default: false
    field :org_name, :string, virtual: true
    field :org_slug, :string, virtual: true

    belongs_to :organization, Ditto.Accounts.Organization

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns true if the user is a system administrator.
  """
  def is_sysadmin?(%__MODULE__{is_sysadmin: true}), do: true
  def is_sysadmin?(_), do: false

  @doc """
  Guard macro for checking sysadmin status in function guards.
  """
  defguard is_sysadmin(user) when user.is_sysadmin == true

  @doc """
  A user changeset for registration with email and password.

  Sets `confirmed_at` automatically so no email confirmation step is needed.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username, :name, :password, :organization_id, :role, :org_name, :org_slug])
    |> validate_email(opts)
    |> validate_username(opts)
    |> validate_password(opts)
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
  end

  @doc """
  A user changeset for updating the profile (name only; username is immutable).
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_length(:name, max: 100)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for changing the user's role within their organization.
  """
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles, message: "must be one of: #{Enum.join(@roles, ", ")}")
  end

  @doc """
  A user changeset for updating sysadmin status.
  """
  def sysadmin_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_sysadmin])
    |> validate_required([:is_sysadmin])
  end

  @doc """
  A user changeset for assigning or changing organization membership.
  """
  def organization_changeset(user, attrs) do
    user
    |> cast(attrs, [:organization_id, :role])
    |> validate_required([:organization_id])
    |> validate_inclusion(:role, @roles, message: "must be one of: #{Enum.join(@roles, ", ")}")
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, Ditto.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  defp validate_username(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:username])
      |> validate_length(:username, min: 3, max: 39)
      |> validate_format(:username, ~r/^[a-zA-Z0-9][a-zA-Z0-9_-]*$/,
        message: "must start with a letter or number and only contain letters, numbers, _ or -"
      )
      |> update_change(:username, &String.downcase/1)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:username, Ditto.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Ditto.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end
end
