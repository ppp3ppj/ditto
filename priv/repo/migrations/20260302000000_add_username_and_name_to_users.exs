defmodule Ditto.Repo.Migrations.AddUsernameAndNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string, null: false, collate: :nocase, default: ""
      add :name, :string
    end

    create unique_index(:users, [:username])
  end
end
