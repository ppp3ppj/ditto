defmodule Ditto.Repo.Migrations.CreateProjectInvitations do
  use Ecto.Migration

  def change do
    create table(:project_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :expires_at, :utc_datetime
      add :max_uses, :integer
      add :uses_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:project_invitations, [:project_id])
    create unique_index(:project_invitations, [:token])
  end
end
