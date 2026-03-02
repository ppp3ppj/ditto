defmodule Ditto.Projects.ProjectMember do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Accounts.User
  alias Ditto.Projects.Project

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_members" do
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime

    belongs_to :project, Project
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:project_id, :user_id, :role, :joined_at])
    |> validate_required([:project_id, :user_id, :role, :joined_at])
    |> validate_inclusion(:role, ["owner", "member"])
    |> unique_constraint([:project_id, :user_id])
  end
end
