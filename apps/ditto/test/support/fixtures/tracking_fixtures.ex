defmodule Ditto.TrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ditto.Tracking` context.
  """

  import Ditto.AccountsFixtures, only: [user_fixture: 0]
  import Ditto.ProjectsFixtures, only: [project_fixture: 1, category_fixture: 1]

  @doc """
  Generate a time_entry.
  """
  def time_entry_fixture(attrs \\ %{}) do
    user = user_fixture()
    project = project_fixture(%{user_id: user.id})
    category = category_fixture(%{project_id: project.id})

    {:ok, time_entry} =
      attrs
      |> Enum.into(%{
        category_id: category.id,
        date: ~D[2026-07-20],
        duration: 42,
        note: "some note",
        project_id: project.id,
        user_id: user.id
      })
      |> Ditto.Tracking.create_time_entry()

    time_entry
  end
end
