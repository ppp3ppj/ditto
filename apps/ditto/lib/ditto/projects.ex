defmodule Ditto.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Ditto.Repo
  alias Ditto.Accounts
  alias Ditto.Accounts.Scope

  alias Ditto.Projects.Project

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Repo.all(Project)
  end

  def list_projects(%Scope{user: %{id: user_id}}) do
    Project
    |> join(:left, [p], pm in assoc(p, :project_members))
    |> where([p, pm], p.user_id == ^user_id or pm.user_id == ^user_id)
    |> distinct(true)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  def list_owned_projects(%Scope{user: %{id: user_id}}) do
    Project
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Gets a single project the given scope can access, preloaded with its owner.

  Raises `Ecto.NoResultsError` if the project doesn't exist or isn't accessible.
  """
  def get_accessible_project!(%Scope{} = scope, id) do
    scope
    |> accessible_projects_query()
    |> where([p], p.id == ^id)
    |> Repo.one!()
    |> Repo.preload(:user)
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def create_project(%Scope{user: %{id: user_id}}, attrs) do
    attrs = Map.put(attrs, "user_id", user_id)

    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  alias Ditto.Projects.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  def list_categories(scope, project_id \\ nil)

  def list_categories(%Scope{} = scope, nil) do
    scope
    |> accessible_projects_query()
    |> join(:inner, [p, ...], c in assoc(p, :categories))
    |> order_by([..., c], asc: c.name)
    |> select([..., c], c)
    |> Repo.all()
  end

  def list_categories(%Scope{} = scope, project_id) do
    scope
    |> accessible_projects_query()
    |> where([p], p.id == ^project_id)
    |> join(:inner, [p, ...], c in assoc(p, :categories))
    |> order_by([..., c], asc: c.name)
    |> select([..., c], c)
    |> Repo.all()
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def create_category(%Scope{} = scope, attrs) do
    project_id = Map.get(attrs, "project_id") || Map.get(attrs, :project_id)

    if project_accessible?(scope, project_id) do
      %Category{}
      |> Category.changeset(attrs)
      |> Repo.insert()
    else
      {:error, unauthorized_changeset(%Category{}, :project_id)}
    end
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Ditto.Projects.ProjectMember

  @doc """
  Returns the list of project_members.

  ## Examples

      iex> list_project_members()
      [%ProjectMember{}, ...]

  """
  def list_project_members do
    Repo.all(ProjectMember)
  end

  def list_project_members(%Scope{} = scope, project_id) do
    members =
      scope
      |> accessible_projects_query()
      |> where([p], p.id == ^project_id)
      |> join(:inner, [p, ...], pm in assoc(p, :project_members))
      |> order_by([..., pm], asc: pm.inserted_at)
      |> select([..., pm], pm)
      |> Repo.all()

    Repo.preload(members, [:user, :project])
  end

  @doc """
  Gets a single project_member.

  Raises `Ecto.NoResultsError` if the Project member does not exist.

  ## Examples

      iex> get_project_member!(123)
      %ProjectMember{}

      iex> get_project_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project_member!(id), do: Repo.get!(ProjectMember, id)

  @doc """
  Creates a project_member.

  ## Examples

      iex> create_project_member(%{field: value})
      {:ok, %ProjectMember{}}

      iex> create_project_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project_member(attrs) do
    %ProjectMember{}
    |> ProjectMember.changeset(attrs)
    |> Repo.insert()
  end

  def invite_project_member(%Scope{user: %{id: user_id}}, project_id, email)
      when is_binary(project_id) and is_binary(email) do
    with %Project{} <- Repo.get_by(Project, id: project_id, user_id: user_id),
         %Accounts.User{} = invitee <- Accounts.get_user_by_email(email) do
      %ProjectMember{}
      |> ProjectMember.changeset(%{project_id: project_id, user_id: invitee.id})
      |> Repo.insert()
    else
      nil ->
        {:error, unauthorized_changeset(%ProjectMember{}, :project_id)}

      _ ->
        {:error, unauthorized_changeset(%ProjectMember{}, :user_id, "was not found")}
    end
  end

  @doc """
  Updates a project_member.

  ## Examples

      iex> update_project_member(project_member, %{field: new_value})
      {:ok, %ProjectMember{}}

      iex> update_project_member(project_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project_member(%ProjectMember{} = project_member, attrs) do
    project_member
    |> ProjectMember.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project_member.

  ## Examples

      iex> delete_project_member(project_member)
      {:ok, %ProjectMember{}}

      iex> delete_project_member(project_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project_member(%ProjectMember{} = project_member) do
    Repo.delete(project_member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project_member changes.

  ## Examples

      iex> change_project_member(project_member)
      %Ecto.Changeset{data: %ProjectMember{}}

  """
  def change_project_member(%ProjectMember{} = project_member, attrs \\ %{}) do
    ProjectMember.changeset(project_member, attrs)
  end

  defp accessible_projects_query(%Scope{user: %{id: user_id}}) do
    Project
    |> join(:left, [p], pm in assoc(p, :project_members))
    |> where([p, pm], p.user_id == ^user_id or pm.user_id == ^user_id)
    |> distinct(true)
  end

  defp project_accessible?(%Scope{} = scope, project_id) when is_binary(project_id) do
    scope
    |> accessible_projects_query()
    |> where([p], p.id == ^project_id)
    |> Repo.exists?()
  end

  defp project_accessible?(_scope, _project_id), do: false

  defp unauthorized_changeset(struct, field, message \\ "is invalid") do
    struct
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(field, message)
  end
end
