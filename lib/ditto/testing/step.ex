defmodule Ditto.Testing.Step do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Testing.Case

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_steps" do
    field :description, :string
    field :expected_result, :string
    field :position, :integer, default: 0

    belongs_to :case, Case

    timestamps(type: :utc_datetime)
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:description, :expected_result, :position, :case_id])
    |> validate_required([:description, :case_id])
  end

  def update_changeset(step, attrs) do
    step
    |> cast(attrs, [:description, :expected_result])
    |> validate_required([:description])
  end
end
