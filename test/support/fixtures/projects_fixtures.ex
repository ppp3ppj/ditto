defmodule Ditto.ProjectsFixtures do
  @moduledoc """
  Test helpers for creating project-related entities.
  """

  alias Ditto.Projects
  alias Ditto.Repo

  def valid_project_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "name" => "Project #{System.unique_integer([:positive])}",
      "description" => "A test project"
    })
  end

  @doc "Creates a project owned by the given user."
  def project_fixture(owner, attrs \\ %{}) do
    {:ok, project} = Projects.create_project(owner, valid_project_attributes(attrs))
    project
  end

  @doc """
  Creates an invitation for the given project. Accepts overrides:
    - `:expires_at` — set a specific UTC datetime (useful for expired invitations)
    - `:max_uses` — integer or nil
    - `:uses_count` — integer, default 0
  """
  def invitation_fixture(project, creator, overrides \\ %{}) do
    {:ok, inv} = Projects.create_invitation(project, creator)

    if map_size(overrides) > 0 do
      inv
      |> Ecto.Changeset.change(overrides)
      |> Repo.update!()
    else
      inv
    end
  end
end
