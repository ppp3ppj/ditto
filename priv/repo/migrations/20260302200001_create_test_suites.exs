defmodule Ditto.Repo.Migrations.CreateTestSuites do
  use Ecto.Migration

  def change do
    create table(:test_suites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:test_suites, [:project_id])
  end
end
