defmodule Ditto.Repo.Migrations.AddUniqueIndexToProjectMembers do
  use Ecto.Migration

  def change do
    create unique_index(:project_members, [:user_id, :project_id])
  end
end
