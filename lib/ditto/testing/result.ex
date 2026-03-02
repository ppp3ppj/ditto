defmodule Ditto.Testing.Result do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Accounts.User
  alias Ditto.Testing.{Run, Case}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_results" do
    field :case_name, :string
    field :status, :string, default: "pending"
    field :notes, :string
    field :executed_at, :utc_datetime

    belongs_to :run, Run
    belongs_to :case, Case
    belongs_to :executed_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [:case_name, :status, :notes, :run_id, :case_id, :executed_by_id, :executed_at])
    |> validate_required([:case_name, :run_id, :case_id])
    |> validate_inclusion(:status, ["pending", "pass", "fail", "skip"])
  end

  def update_changeset(result, attrs) do
    result
    |> cast(attrs, [:status, :notes, :executed_by_id, :executed_at])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["pending", "pass", "fail", "skip"])
  end
end
