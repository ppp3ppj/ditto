defmodule Ditto.Projects.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "categories" do
    field :name, :string
    belongs_to :project, Ditto.Projects.Project
    has_many :time_entries, Ditto.Tracking.TimeEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :project_id])
    |> validate_required([:name, :project_id])
    |> unique_constraint(:name, name: :categories_project_id_name_index)
    |> foreign_key_constraint(:project_id)
  end
end
