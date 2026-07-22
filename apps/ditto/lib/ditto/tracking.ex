defmodule Ditto.Tracking do
  @moduledoc """
  The Tracking context.
  """

  import Ecto.Query, warn: false
  alias Ditto.Repo
  alias Ditto.Accounts.Scope
  alias Ditto.Projects.{Category, Project}

  alias Ditto.Tracking.TimeEntry

  @doc """
  Returns the list of time_entries.

  ## Examples

      iex> list_time_entries()
      [%TimeEntry{}, ...]

  """
  def list_time_entries do
    Repo.all(TimeEntry)
  end

  def list_time_entries(%Scope{user: %{id: user_id}}) do
    TimeEntry
    |> where([t], t.user_id == ^user_id)
    |> preload([:project, :category])
    |> order_by([t], desc: t.date, desc: t.inserted_at)
    |> Repo.all()
  end

  def list_time_entries(%Scope{} = scope, project_id) when is_binary(project_id) do
    if project_accessible_by_user?(scope.user.id, project_id) do
      TimeEntry
      |> where([t], t.project_id == ^project_id)
      |> preload([:project, :category, :user])
      |> order_by([t], desc: t.date, desc: t.inserted_at)
      |> Repo.all()
    else
      []
    end
  end

  @doc """
  Gets a single time_entry.

  Raises `Ecto.NoResultsError` if the Time entry does not exist.

  ## Examples

      iex> get_time_entry!(123)
      %TimeEntry{}

      iex> get_time_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_time_entry!(id), do: Repo.get!(TimeEntry, id)

  @doc """
  Creates a time_entry.

  ## Examples

      iex> create_time_entry(%{field: value})
      {:ok, %TimeEntry{}}

      iex> create_time_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_time_entry(attrs) do
    %TimeEntry{}
    |> TimeEntry.changeset(attrs)
    |> Repo.insert()
  end

  def create_time_entry(%Scope{user: %{id: user_id}}, attrs) do
    project_id = Map.get(attrs, "project_id") || Map.get(attrs, :project_id)
    category_id = Map.get(attrs, "category_id") || Map.get(attrs, :category_id)
    attrs = Map.put(attrs, "user_id", user_id)

    cond do
      not project_accessible_by_user?(user_id, project_id) ->
        {:error, invalid_relation_changeset(:project_id)}

      not category_belongs_to_project?(category_id, project_id) ->
        {:error, invalid_relation_changeset(:category_id)}

      true ->
        %TimeEntry{}
        |> TimeEntry.changeset(attrs)
        |> Repo.insert()
    end
  end

  @doc """
  Updates a time_entry.

  ## Examples

      iex> update_time_entry(time_entry, %{field: new_value})
      {:ok, %TimeEntry{}}

      iex> update_time_entry(time_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_time_entry(%TimeEntry{} = time_entry, attrs) do
    time_entry
    |> TimeEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a time_entry.

  ## Examples

      iex> delete_time_entry(time_entry)
      {:ok, %TimeEntry{}}

      iex> delete_time_entry(time_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_time_entry(%TimeEntry{} = time_entry) do
    Repo.delete(time_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking time_entry changes.

  ## Examples

      iex> change_time_entry(time_entry)
      %Ecto.Changeset{data: %TimeEntry{}}

  """
  def change_time_entry(%TimeEntry{} = time_entry, attrs \\ %{}) do
    TimeEntry.changeset(time_entry, attrs)
  end

  defp project_accessible_by_user?(user_id, project_id)
       when is_binary(user_id) and is_binary(project_id) do
    Project
    |> join(:left, [p], pm in assoc(p, :project_members))
    |> where([p, pm], p.id == ^project_id and (p.user_id == ^user_id or pm.user_id == ^user_id))
    |> Repo.exists?()
  end

  defp project_accessible_by_user?(_, _), do: false

  defp category_belongs_to_project?(category_id, project_id)
       when is_binary(category_id) and is_binary(project_id) do
    Category
    |> where([c], c.id == ^category_id and c.project_id == ^project_id)
    |> Repo.exists?()
  end

  defp category_belongs_to_project?(_, _), do: false

  defp invalid_relation_changeset(field) do
    %TimeEntry{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(field, "is invalid")
  end
end
