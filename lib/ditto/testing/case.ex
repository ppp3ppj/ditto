defmodule Ditto.Testing.Case do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Testing.{Scenario, Step}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_cases" do
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0

    belongs_to :scenario, Scenario
    has_many :steps, Step, foreign_key: :case_id

    timestamps(type: :utc_datetime)
  end

  def changeset(test_case, attrs) do
    test_case
    |> cast(attrs, [:name, :description, :position, :scenario_id])
    |> validate_required([:name, :scenario_id])
    |> validate_length(:name, min: 1, max: 200)
  end

  def update_changeset(test_case, attrs) do
    test_case
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
  end
end
