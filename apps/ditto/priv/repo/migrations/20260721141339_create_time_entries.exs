defmodule Ditto.Repo.Migrations.CreateTimeEntries do
  use Ecto.Migration

  def change do
    create table(:time_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date
      add :duration, :integer
      add :note, :text
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :project_id, references(:projects, on_delete: :nothing, type: :binary_id)
      add :category_id, references(:categories, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:time_entries, [:user_id])
    create index(:time_entries, [:project_id])
    create index(:time_entries, [:category_id])
  end
end
