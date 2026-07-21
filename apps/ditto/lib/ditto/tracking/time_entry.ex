defmodule Ditto.Tracking.TimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "time_entries" do
    field :date, :date
    field :duration, :integer
    field :note, :string
    field :user_id, :binary_id
    field :project_id, :binary_id
    field :category_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, [:date, :duration, :note])
    |> validate_required([:date, :duration, :note])
  end
end
