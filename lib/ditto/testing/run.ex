defmodule Ditto.Testing.Run do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ditto.Accounts.User
  alias Ditto.Projects.Project
  alias Ditto.Testing.Result

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "test_runs" do
    field :name, :string
    field :status, :string, default: "pending"
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :project, Project
    belongs_to :created_by, User
    has_many :results, Result, foreign_key: :run_id

    timestamps(type: :utc_datetime)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:name, :status, :started_at, :completed_at, :project_id, :created_by_id])
    |> validate_required([:name, :project_id, :created_by_id])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_inclusion(:status, ["pending", "in_progress", "completed"])
  end
end
