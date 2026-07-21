defmodule Ditto.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ditto.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ditto.Projects.create_project()

    project
  end

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ditto.Projects.create_category()

    category
  end
end
