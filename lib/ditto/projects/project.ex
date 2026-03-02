defmodule Ditto.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Accounts.User
  alias Ditto.Projects.{ProjectMember, ProjectInvitation}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :description, :string

    belongs_to :owner, User
    has_many :project_members, ProjectMember
    has_many :members, through: [:project_members, :user]
    has_many :project_invitations, ProjectInvitation

    timestamps(type: :utc_datetime)
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :owner_id])
    |> validate_required([:name, :owner_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
  end

  def update_changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
  end
end
