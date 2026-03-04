defmodule Ditto.Testing.Suite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Projects.Project
  alias Ditto.Testing.Scenario

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_suites" do
    field :name, :string
    field :description, :string

    belongs_to :project, Project
    has_many :scenarios, Scenario, foreign_key: :suite_id

    timestamps(type: :utc_datetime)
  end

  def changeset(suite, attrs) do
    suite
    |> cast(attrs, [:name, :description, :project_id])
    |> validate_required([:name, :project_id])
    |> validate_length(:name, min: 1, max: 200)
  end

  def update_changeset(suite, attrs) do
    suite
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
  end
end
