defmodule Ditto.Repo.Migrations.CreateTestResults do
  use Ecto.Migration

  def change do
    create table(:test_results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:test_runs, type: :binary_id, on_delete: :delete_all), null: false
      add :case_id, references(:test_cases, type: :binary_id, on_delete: :nothing), null: false
      add :case_name, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :notes, :text
      add :executed_by_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :executed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:test_results, [:run_id])
    create index(:test_results, [:case_id])
  end
end
