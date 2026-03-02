defmodule Ditto.Testing.Scenario do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Testing.{Suite, Case}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_scenarios" do
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0

    belongs_to :suite, Suite
    has_many :cases, Case, foreign_key: :scenario_id

    timestamps(type: :utc_datetime)
  end

  def changeset(scenario, attrs) do
    scenario
    |> cast(attrs, [:name, :description, :position, :suite_id])
    |> validate_required([:name, :suite_id])
    |> validate_length(:name, min: 1, max: 200)
  end

  def update_changeset(scenario, attrs) do
    scenario
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
  end
end
