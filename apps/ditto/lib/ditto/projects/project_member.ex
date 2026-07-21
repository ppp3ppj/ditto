defmodule Ditto.Projects.ProjectMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_members" do
    belongs_to :user, Ditto.Accounts.User
    belongs_to :project, Ditto.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project_member, attrs) do
    project_member
    |> cast(attrs, [:user_id, :project_id])
    |> validate_required([:user_id, :project_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:project_id)
    |> unique_constraint(:user_id, name: :project_members_user_id_project_id_index)
  end
end
