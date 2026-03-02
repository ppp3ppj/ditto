defmodule Ditto.Repo.Migrations.CreateTestCases do
  use Ecto.Migration

  def change do
    create table(:test_cases, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :scenario_id, references(:test_scenarios, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:test_cases, [:scenario_id])
  end
end
