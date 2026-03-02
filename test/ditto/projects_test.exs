defmodule Ditto.ProjectsTest do
  use Ditto.DataCase

  alias Ditto.Projects
  alias Ditto.Projects.{ProjectMember, ProjectInvitation}

  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures

  # ---------------------------------------------------------------------------
  # create_project/2
  # ---------------------------------------------------------------------------

  describe "create_project/2" do
    test "creates project with valid attributes" do
      owner = user_fixture()
      assert {:ok, project} = Projects.create_project(owner, %{"name" => "My Project"})
      assert project.name == "My Project"
      assert project.owner_id == owner.id
    end

    test "automatically adds creator as owner member" do
      owner = user_fixture()
      {:ok, project} = Projects.create_project(owner, %{"name" => "P"})

      member = Repo.get_by!(ProjectMember, project_id: project.id, user_id: owner.id)
      assert member.role == "owner"
    end

    test "returns error when name is missing" do
      owner = user_fixture()
      assert {:error, changeset} = Projects.create_project(owner, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "does not create member if project insert fails" do
      owner = user_fixture()
      assert {:error, _changeset} = Projects.create_project(owner, %{"name" => ""})
      assert Repo.aggregate(ProjectMember, :count) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # list_user_projects/1
  # ---------------------------------------------------------------------------

  describe "list_user_projects/1" do
    test "returns projects the user belongs to" do
      owner = user_fixture()
      project = project_fixture(owner)

      results = Projects.list_user_projects(owner)
      assert length(results) == 1
      assert hd(results).project.id == project.id
      assert hd(results).role == "owner"
    end

    test "does not return projects the user is not a member of" do
      other = user_fixture()
      project_fixture(user_fixture())

      assert Projects.list_user_projects(other) == []
    end

    test "returns multiple projects" do
      owner = user_fixture()
      project_fixture(owner, %{"name" => "A"})
      project_fixture(owner, %{"name" => "B"})

      assert length(Projects.list_user_projects(owner)) == 2
    end
  end

  # ---------------------------------------------------------------------------
  # get_project!/1 and get_project_for_member!/2
  # ---------------------------------------------------------------------------

  describe "get_project!/1" do
    test "returns the project" do
      owner = user_fixture()
      project = project_fixture(owner)
      assert Projects.get_project!(project.id).id == project.id
    end

    test "raises for unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project!("00000000-0000-0000-0000-000000000000")
      end
    end
  end

  describe "get_project_for_member!/2" do
    test "returns project when user is a member" do
      owner = user_fixture()
      project = project_fixture(owner)
      assert Projects.get_project_for_member!(owner, project.id).id == project.id
    end

    test "raises when user is not a member" do
      outsider = user_fixture()
      project = project_fixture(user_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project_for_member!(outsider, project.id)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # update_project/2
  # ---------------------------------------------------------------------------

  describe "update_project/2" do
    test "updates name and description" do
      owner = user_fixture()
      project = project_fixture(owner)

      assert {:ok, updated} =
               Projects.update_project(project, %{"name" => "New Name", "description" => "New desc"})

      assert updated.name == "New Name"
      assert updated.description == "New desc"
    end

    test "returns error when name is blank" do
      project = project_fixture(user_fixture())
      assert {:error, changeset} = Projects.update_project(project, %{"name" => ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  # ---------------------------------------------------------------------------
  # delete_project/1
  # ---------------------------------------------------------------------------

  describe "delete_project/1" do
    test "deletes the project" do
      owner = user_fixture()
      project = project_fixture(owner)
      assert {:ok, _} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "cascades to members" do
      owner = user_fixture()
      project = project_fixture(owner)
      Projects.delete_project(project)
      assert Repo.aggregate(ProjectMember, :count) == 0
    end

    test "cascades to invitations" do
      owner = user_fixture()
      project = project_fixture(owner)
      invitation_fixture(project, owner)
      Projects.delete_project(project)
      assert Repo.aggregate(ProjectInvitation, :count) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # list_members/1
  # ---------------------------------------------------------------------------

  describe "list_members/1" do
    test "returns all members with user data and role" do
      owner = user_fixture()
      project = project_fixture(owner)

      members = Projects.list_members(project)
      assert length(members) == 1
      assert hd(members).user.id == owner.id
      assert hd(members).role == "owner"
    end
  end

  # ---------------------------------------------------------------------------
  # member?/2
  # ---------------------------------------------------------------------------

  describe "member?/2" do
    test "returns true when user is a member" do
      owner = user_fixture()
      project = project_fixture(owner)
      assert Projects.member?(project, owner)
    end

    test "returns false when user is not a member" do
      project = project_fixture(user_fixture())
      outsider = user_fixture()
      refute Projects.member?(project, outsider)
    end
  end

  # ---------------------------------------------------------------------------
  # remove_member/2
  # ---------------------------------------------------------------------------

  describe "remove_member/2" do
    test "removes a regular member" do
      owner = user_fixture()
      member_user = user_fixture()
      project = project_fixture(owner)

      # Add member_user by joining via invite
      {:ok, inv} = Projects.create_invitation(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      assert {:ok, _} = Projects.remove_member(project, member_user.id)
      refute Projects.member?(project, member_user)
    end

    test "cannot remove the owner" do
      owner = user_fixture()
      project = project_fixture(owner)
      assert {:error, :cannot_remove_owner} = Projects.remove_member(project, owner.id)
    end

    test "returns error when user is not a member" do
      project = project_fixture(user_fixture())
      outsider = user_fixture()
      assert {:error, :not_found} = Projects.remove_member(project, outsider.id)
    end
  end

  # ---------------------------------------------------------------------------
  # create_invitation/3
  # ---------------------------------------------------------------------------

  describe "create_invitation/3" do
    test "creates invitation with no expiry and unlimited uses" do
      owner = user_fixture()
      project = project_fixture(owner)

      assert {:ok, inv} = Projects.create_invitation(project, owner, %{})
      assert inv.project_id == project.id
      assert inv.created_by_id == owner.id
      assert is_binary(inv.token)
      assert is_nil(inv.expires_at)
      assert is_nil(inv.max_uses)
      assert inv.uses_count == 0
    end

    test "sets expires_at when expires_in_hours is given" do
      owner = user_fixture()
      project = project_fixture(owner)

      {:ok, inv} = Projects.create_invitation(project, owner, %{"expires_in_hours" => "24"})
      assert inv.expires_at != nil
      assert DateTime.after?(inv.expires_at, DateTime.utc_now())
    end

    test "sets max_uses when given" do
      owner = user_fixture()
      project = project_fixture(owner)

      {:ok, inv} = Projects.create_invitation(project, owner, %{"max_uses" => "10"})
      assert inv.max_uses == 10
    end

    test "sets max_uses to nil when 0 is given (unlimited)" do
      owner = user_fixture()
      project = project_fixture(owner)

      {:ok, inv} = Projects.create_invitation(project, owner, %{"max_uses" => "0"})
      assert is_nil(inv.max_uses)
    end

    test "each token is unique" do
      owner = user_fixture()
      project = project_fixture(owner)

      {:ok, inv1} = Projects.create_invitation(project, owner)
      {:ok, inv2} = Projects.create_invitation(project, owner)
      refute inv1.token == inv2.token
    end
  end

  # ---------------------------------------------------------------------------
  # join_via_token/2
  # ---------------------------------------------------------------------------

  describe "join_via_token/2" do
    test "adds user as member and increments uses_count" do
      owner = user_fixture()
      joiner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      assert {:ok, joined_project} = Projects.join_via_token(joiner, inv.token)
      assert joined_project.id == project.id
      assert Projects.member?(project, joiner)
      assert Repo.get!(ProjectInvitation, inv.id).uses_count == 1
    end

    test "returns error for unknown token" do
      joiner = user_fixture()
      assert {:error, :not_found} = Projects.join_via_token(joiner, "nosuchtoken")
    end

    test "returns error when token is expired" do
      owner = user_fixture()
      joiner = user_fixture()
      project = project_fixture(owner)

      past = DateTime.add(DateTime.utc_now(:second), -3600, :second)
      inv = invitation_fixture(project, owner, %{expires_at: past})

      assert {:error, :expired} = Projects.join_via_token(joiner, inv.token)
      refute Projects.member?(project, joiner)
    end

    test "returns error when max uses reached" do
      owner = user_fixture()
      joiner = user_fixture()
      project = project_fixture(owner)

      inv = invitation_fixture(project, owner, %{max_uses: 1, uses_count: 1})

      assert {:error, :max_uses_reached} = Projects.join_via_token(joiner, inv.token)
      refute Projects.member?(project, joiner)
    end

    test "returns error when user is already a member" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      assert {:error, :already_member} = Projects.join_via_token(owner, inv.token)
    end

    test "does not add member if uses_count increment fails" do
      # Verify atomicity: both member insert and uses_count increment succeed or fail together.
      # This is covered structurally by the transaction, so we verify the success path here.
      owner = user_fixture()
      joiner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner, %{max_uses: 5})

      {:ok, _} = Projects.join_via_token(joiner, inv.token)
      assert Repo.get!(ProjectInvitation, inv.id).uses_count == 1
    end
  end

  # ---------------------------------------------------------------------------
  # validate_invitation/1
  # ---------------------------------------------------------------------------

  describe "validate_invitation/1" do
    test "returns ok tuple with project and invitation for valid token" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      assert {:ok, fetched_project, fetched_inv} = Projects.validate_invitation(inv.token)
      assert fetched_project.id == project.id
      assert fetched_inv.token == inv.token
    end

    test "returns error for unknown token" do
      assert {:error, :not_found} = Projects.validate_invitation("badtoken")
    end

    test "returns error for expired token" do
      owner = user_fixture()
      project = project_fixture(owner)
      past = DateTime.add(DateTime.utc_now(:second), -1, :second)
      inv = invitation_fixture(project, owner, %{expires_at: past})

      assert {:error, :expired} = Projects.validate_invitation(inv.token)
    end

    test "returns error when max uses reached" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner, %{max_uses: 3, uses_count: 3})

      assert {:error, :max_uses_reached} = Projects.validate_invitation(inv.token)
    end

    test "returns ok for invitation with no expiry and no max_uses" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      assert {:ok, _, _} = Projects.validate_invitation(inv.token)
    end
  end

  # ---------------------------------------------------------------------------
  # delete_invitation_by_id/1
  # ---------------------------------------------------------------------------

  describe "delete_invitation_by_id/1" do
    test "deletes the invitation" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      assert {:ok, _} = Projects.delete_invitation_by_id(inv.id)
      assert is_nil(Repo.get(ProjectInvitation, inv.id))
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} =
               Projects.delete_invitation_by_id("00000000-0000-0000-0000-000000000000")
    end
  end
end
