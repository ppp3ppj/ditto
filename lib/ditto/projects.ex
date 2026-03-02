defmodule Ditto.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false

  alias Ditto.Repo
  alias Ditto.Accounts.User
  alias Ditto.Projects.{Project, ProjectMember, ProjectInvitation}

  ## Projects

  @doc """
  Returns all projects the user is a member of.
  """
  def list_user_projects(%User{} = user) do
    from(p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id and pm.user_id == ^user.id,
      select: %{project: p, role: pm.role, joined_at: pm.joined_at},
      order_by: [asc: pm.joined_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single project by id. Raises if not found.
  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Gets a project only if the given user is a member of it. Raises if not found.
  """
  def get_project_for_member!(%User{} = user, project_id) do
    from(p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id and pm.user_id == ^user.id,
      where: p.id == ^project_id
    )
    |> Repo.one!()
  end

  @doc """
  Creates a project and adds the creator as the owner in a single transaction.
  """
  def create_project(%User{} = creator, attrs) do
    Repo.transact(fn ->
      with {:ok, project} <-
             %Project{}
             |> Project.changeset(Map.put(attrs, "owner_id", creator.id))
             |> Repo.insert(),
           {:ok, _member} <- add_member(project, creator, "owner") do
        {:ok, project}
      end
    end)
  end

  @doc """
  Updates a project's name and description.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project (cascades to members and invitations).
  """
  def delete_project(%Project{} = project), do: Repo.delete(project)

  @doc """
  Returns a changeset for creating/editing a project.
  """
  def change_project(project \\ %Project{}, attrs \\ %{}) do
    Project.update_changeset(project, attrs)
  end

  ## Members

  @doc """
  Lists all members of a project, preloaded with their user data.
  """
  def list_members(%Project{} = project) do
    from(pm in ProjectMember,
      where: pm.project_id == ^project.id,
      join: u in User,
      on: u.id == pm.user_id,
      select: %{id: pm.id, user: u, role: pm.role, joined_at: pm.joined_at},
      order_by: [asc: pm.joined_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the membership record for a user in a project, or nil.
  """
  def get_member(%Project{} = project, %User{} = user) do
    Repo.get_by(ProjectMember, project_id: project.id, user_id: user.id)
  end

  @doc """
  Checks if a user is already a member of a project.
  """
  def member?(%Project{} = project, %User{} = user) do
    Repo.exists?(
      from pm in ProjectMember,
        where: pm.project_id == ^project.id and pm.user_id == ^user.id
    )
  end

  @doc """
  Removes a member from a project. Cannot remove the owner.
  """
  def remove_member(%Project{} = project, user_id) do
    case Repo.get_by(ProjectMember, project_id: project.id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      %ProjectMember{role: "owner"} ->
        {:error, :cannot_remove_owner}

      member ->
        Repo.delete(member)
    end
  end

  defp add_member(%Project{} = project, %User{} = user, role) do
    %ProjectMember{}
    |> ProjectMember.changeset(%{
      project_id: project.id,
      user_id: user.id,
      role: role,
      joined_at: DateTime.utc_now(:second)
    })
    |> Repo.insert()
  end

  ## Invitations

  @doc """
  Lists all invitations for a project, preloaded with creator user.
  """
  def list_invitations(%Project{} = project) do
    from(inv in ProjectInvitation,
      where: inv.project_id == ^project.id,
      join: u in User,
      on: u.id == inv.created_by_id,
      select: %{
        id: inv.id,
        token: inv.token,
        expires_at: inv.expires_at,
        max_uses: inv.max_uses,
        uses_count: inv.uses_count,
        created_by: u,
        inserted_at: inv.inserted_at
      },
      order_by: [desc: inv.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Creates an invite link for a project.

  Accepts attrs:
    - `expires_in_hours` (integer or nil) — nil means never expires
    - `max_uses` (integer or nil) — nil means unlimited
  """
  def create_invitation(%Project{} = project, %User{} = creator, attrs \\ %{}) do
    token = generate_token()

    expires_at =
      case Map.get(attrs, "expires_in_hours") do
        nil -> nil
        "" -> nil
        hours when is_binary(hours) -> add_hours(String.to_integer(hours))
        hours when is_integer(hours) -> add_hours(hours)
      end

    max_uses =
      case Map.get(attrs, "max_uses") do
        nil -> nil
        "" -> nil
        "0" -> nil
        uses when is_binary(uses) -> String.to_integer(uses)
        uses when is_integer(uses) -> uses
      end

    %ProjectInvitation{}
    |> ProjectInvitation.changeset(%{
      project_id: project.id,
      created_by_id: creator.id,
      token: token,
      expires_at: expires_at,
      max_uses: max_uses
    })
    |> Repo.insert()
  end

  @doc """
  Finds an invitation by its token value, or returns nil.
  """
  def get_invitation_by_token(token) do
    Repo.get_by(ProjectInvitation, token: token)
  end

  @doc """
  Deletes an invitation (requires a DB-loaded struct).
  """
  def delete_invitation(%ProjectInvitation{} = invitation), do: Repo.delete(invitation)

  @doc """
  Deletes an invitation by its id. Returns `{:ok, struct}` or `{:error, :not_found}`.
  """
  def delete_invitation_by_id(id) do
    case Repo.get(ProjectInvitation, id) do
      nil -> {:error, :not_found}
      inv -> Repo.delete(inv)
    end
  end

  @doc """
  Attempts to join a project via an invite token.

  Returns:
    - `{:ok, project}` on success
    - `{:error, :not_found}` — token doesn't exist
    - `{:error, :expired}` — link has expired
    - `{:error, :max_uses_reached}` — link has been used too many times
    - `{:error, :already_member}` — user is already in the project
  """
  def join_via_token(%User{} = user, token) do
    case get_invitation_by_token(token) do
      nil ->
        {:error, :not_found}

      invitation ->
        cond do
          expired?(invitation) ->
            {:error, :expired}

          max_uses_reached?(invitation) ->
            {:error, :max_uses_reached}

          true ->
            project = get_project!(invitation.project_id)

            if member?(project, user) do
              {:error, :already_member}
            else
              Repo.transact(fn ->
                with {:ok, _member} <- add_member(project, user, "member"),
                     {:ok, _inv} <- increment_uses(invitation) do
                  {:ok, project}
                end
              end)
            end
        end
    end
  end

  @doc """
  Validates a token and returns the project if the invite is still valid,
  or an error tuple. Used for displaying the join page without consuming the token.
  """
  def validate_invitation(token) do
    case get_invitation_by_token(token) do
      nil ->
        {:error, :not_found}

      inv ->
        cond do
          expired?(inv) -> {:error, :expired}
          max_uses_reached?(inv) -> {:error, :max_uses_reached}
          true -> {:ok, get_project!(inv.project_id), inv}
        end
    end
  end

  ## Helpers

  defp generate_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp add_hours(hours) do
    DateTime.utc_now(:second) |> DateTime.add(hours * 3600, :second)
  end

  defp expired?(%ProjectInvitation{expires_at: nil}), do: false

  defp expired?(%ProjectInvitation{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now(:second)) == :lt
  end

  defp max_uses_reached?(%ProjectInvitation{max_uses: nil}), do: false

  defp max_uses_reached?(%ProjectInvitation{max_uses: max_uses, uses_count: uses_count}) do
    uses_count >= max_uses
  end

  defp increment_uses(%ProjectInvitation{} = inv) do
    inv
    |> Ecto.Changeset.change(uses_count: inv.uses_count + 1)
    |> Repo.update()
  end
end
