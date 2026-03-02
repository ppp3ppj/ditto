defmodule Ditto.Repo.Migrations.CreateTestSteps do
  use Ecto.Migration

  def change do
    create table(:test_steps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :case_id, references(:test_cases, type: :binary_id, on_delete: :delete_all), null: false
      add :description, :text, null: false
      add :expected_result, :text
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:test_steps, [:case_id])
  end
end
