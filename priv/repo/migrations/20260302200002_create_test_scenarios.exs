defmodule Ditto.Repo.Migrations.CreateTestScenarios do
  use Ecto.Migration

  def change do
    create table(:test_scenarios, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :suite_id, references(:test_suites, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:test_scenarios, [:suite_id])
  end
end
