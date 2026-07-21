defmodule Ditto.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ditto.Projects` context.
  """

  import Ditto.AccountsFixtures, only: [user_fixture: 0]

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    user = user_fixture()

    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "some name",
        user_id: user.id
      })
      |> Ditto.Projects.create_project()

    project
  end

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    project = project_fixture()

    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name",
        project_id: project.id
      })
      |> Ditto.Projects.create_category()

    category
  end

  @doc """
  Generate a project_member.
  """
  def project_member_fixture(attrs \\ %{}) do
    user = user_fixture()
    project = project_fixture()

    {:ok, project_member} =
      attrs
      |> Enum.into(%{
        user_id: user.id,
        project_id: project.id
      })
      |> Ditto.Projects.create_project_member()

    project_member
  end
end
