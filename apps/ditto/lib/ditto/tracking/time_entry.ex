defmodule Ditto.Tracking.TimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "time_entries" do
    field :date, :date
    field :duration, :integer
    field :note, :string
    belongs_to :user, Ditto.Accounts.User
    belongs_to :project, Ditto.Projects.Project
    belongs_to :category, Ditto.Projects.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, [:date, :duration, :note, :user_id, :project_id, :category_id])
    |> validate_required([:date, :duration, :note, :user_id, :project_id, :category_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:category_id)
  end
end
