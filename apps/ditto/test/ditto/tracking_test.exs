defmodule Ditto.TrackingTest do
  use Ditto.DataCase

  alias Ditto.Tracking
  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures

  describe "time_entries" do
    alias Ditto.Tracking.TimeEntry

    import Ditto.TrackingFixtures

    @invalid_attrs %{
      date: nil,
      duration: nil,
      note: nil,
      user_id: nil,
      project_id: nil,
      category_id: nil
    }

    test "list_time_entries/0 returns all time_entries" do
      time_entry = time_entry_fixture()
      assert Tracking.list_time_entries() == [time_entry]
    end

    test "get_time_entry!/1 returns the time_entry with given id" do
      time_entry = time_entry_fixture()
      assert Tracking.get_time_entry!(time_entry.id) == time_entry
    end

    test "create_time_entry/1 with valid data creates a time_entry" do
      user = user_fixture()
      project = project_fixture(%{user_id: user.id})
      category = category_fixture(%{project_id: project.id})

      valid_attrs = %{
        date: ~D[2026-07-20],
        duration: 42,
        note: "some note",
        user_id: user.id,
        project_id: project.id,
        category_id: category.id
      }

      assert {:ok, %TimeEntry{} = time_entry} = Tracking.create_time_entry(valid_attrs)
      assert time_entry.date == ~D[2026-07-20]
      assert time_entry.duration == 42
      assert time_entry.note == "some note"
    end

    test "create_time_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracking.create_time_entry(@invalid_attrs)
    end

    test "update_time_entry/2 with valid data updates the time_entry" do
      time_entry = time_entry_fixture()
      update_attrs = %{date: ~D[2026-07-21], duration: 43, note: "some updated note"}

      assert {:ok, %TimeEntry{} = time_entry} =
               Tracking.update_time_entry(time_entry, update_attrs)

      assert time_entry.date == ~D[2026-07-21]
      assert time_entry.duration == 43
      assert time_entry.note == "some updated note"
    end

    test "update_time_entry/2 with invalid data returns error changeset" do
      time_entry = time_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracking.update_time_entry(time_entry, @invalid_attrs)
      assert time_entry == Tracking.get_time_entry!(time_entry.id)
    end

    test "delete_time_entry/1 deletes the time_entry" do
      time_entry = time_entry_fixture()
      assert {:ok, %TimeEntry{}} = Tracking.delete_time_entry(time_entry)
      assert_raise Ecto.NoResultsError, fn -> Tracking.get_time_entry!(time_entry.id) end
    end

    test "change_time_entry/1 returns a time_entry changeset" do
      time_entry = time_entry_fixture()
      assert %Ecto.Changeset{} = Tracking.change_time_entry(time_entry)
    end
  end
end
