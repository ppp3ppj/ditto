defmodule Ditto.Repo.Migrations.AddUniqueIndexesToProjectsAndCategories do
  use Ecto.Migration

  def change do
    create unique_index(:projects, [:user_id, :name])
    create unique_index(:categories, [:project_id, :name])
  end
end
