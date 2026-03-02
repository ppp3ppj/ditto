defmodule Ditto.Repo.Migrations.AddJoinCodeToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :join_code, :string
    end

    create unique_index(:organizations, [:join_code])
  end
end
