defmodule Ditto.TrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ditto.Tracking` context.
  """

  @doc """
  Generate a time_entry.
  """
  def time_entry_fixture(attrs \\ %{}) do
    {:ok, time_entry} =
      attrs
      |> Enum.into(%{
        date: ~D[2026-07-20],
        duration: 42,
        note: "some note"
      })
      |> Ditto.Tracking.create_time_entry()

    time_entry
  end
end
