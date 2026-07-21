defmodule Ditto.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    belongs_to :user, Ditto.Accounts.User
    has_many :categories, Ditto.Projects.Category
    has_many :time_entries, Ditto.Tracking.TimeEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name, name: :projects_user_id_name_index)
    |> foreign_key_constraint(:user_id)
  end
end
