defmodule Ditto.Projects.ProjectInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Accounts.User
  alias Ditto.Projects.Project

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_invitations" do
    field :token, :string
    field :expires_at, :utc_datetime
    field :max_uses, :integer
    field :uses_count, :integer, default: 0

    belongs_to :project, Project
    belongs_to :created_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:project_id, :created_by_id, :token, :expires_at, :max_uses])
    |> validate_required([:project_id, :created_by_id, :token])
    |> validate_number(:max_uses, greater_than: 0)
    |> unique_constraint(:token)
  end
end
