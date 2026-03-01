defmodule Ditto.Repo.Migrations.AddOrgRoleSysadminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nothing)
      add :role, :string, default: "member", null: false
      add :is_sysadmin, :boolean, default: false, null: false
    end

    create index(:users, [:organization_id])
    create index(:users, [:is_sysadmin])
  end
end
