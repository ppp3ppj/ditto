defmodule DittoWeb.ProjectLive.ShowTest do
  use DittoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures

  alias Ditto.Projects

  describe "Show page - basic rendering" do
    setup :register_and_log_in_user

    test "renders project name and members", %{conn: conn, user: user} do
      project = project_fixture(user, %{"name" => "Show Me", "description" => "A description"})

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      assert html =~ "Show Me"
      assert html =~ "A description"
      assert html =~ user.username
      assert html =~ "owner"
    end

    test "redirects to login when not authenticated" do
      owner = user_fixture()
      project = project_fixture(owner)
      conn = build_conn()

      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/projects/#{project.id}")
      assert path == ~p"/users/log-in"
    end

    test "raises when user is not a member", %{conn: conn} do
      other_project = project_fixture(user_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/projects/#{other_project.id}")
      end
    end
  end

  describe "Show page - editing (owner only)" do
    setup :register_and_log_in_user

    test "owner can edit project name and description", %{conn: conn, user: user} do
      project = project_fixture(user, %{"name" => "Old Name"})

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

      lv |> element("button", "Edit") |> render_click()

      html =
        lv
        |> form("#project_edit_form", project: %{name: "New Name", description: "Updated"})
        |> render_submit()

      assert html =~ "New Name"
      assert html =~ "Project updated."
    end

    test "owner cannot save blank name", %{conn: conn, user: user} do
      project = project_fixture(user)

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")
      lv |> element("button", "Edit") |> render_click()

      html =
        lv
        |> form("#project_edit_form", project: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "member does not see Edit button", %{conn: conn, user: member_user} do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      refute html =~ ~r/<button[^>]*>Edit<\/button>/
    end
  end

  describe "Show page - delete project (owner only)" do
    setup :register_and_log_in_user

    test "owner can delete project", %{conn: conn, user: user} do
      project = project_fixture(user, %{"name" => "To Delete"})

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

      {:ok, _lv, html} =
        lv
        |> element("button[phx-click='delete_project']")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Project deleted."
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end
  end

  describe "Show page - member management (owner only)" do
    setup :register_and_log_in_user

    test "owner sees Remove button for other members", %{conn: conn, user: owner} do
      project = project_fixture(owner)
      member_user = user_fixture()
      inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      assert html =~ member_user.username
      assert html =~ "Remove"
    end

    test "owner cannot see Remove button for themselves", %{conn: conn, user: owner} do
      project = project_fixture(owner)

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")
      # The owner row should not have a Remove button
      refute lv |> element("[phx-value-user-id='#{owner.id}']") |> has_element?()
    end

    test "owner can remove a member", %{conn: conn, user: owner} do
      project = project_fixture(owner)
      member_user = user_fixture()
      inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

      html =
        lv
        |> element("[phx-click='remove_member'][phx-value-user-id='#{member_user.id}']")
        |> render_click()

      refute html =~ member_user.username
      refute Projects.member?(project, member_user)
    end

    test "member does not see Remove button", %{conn: conn, user: member_user} do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      refute html =~ "Remove"
    end
  end

  describe "Show page - invite links" do
    setup :register_and_log_in_user

    test "owner can create an invite link", %{conn: conn, user: owner} do
      project = project_fixture(owner)

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")
      lv |> element("button", "Create invite link") |> render_click()

      html =
        lv
        |> form("#invite_form")
        |> render_submit(%{invite: %{expires_in_hours: "24", max_uses: "10"}})

      assert html =~ "Invite link created!"
      assert html =~ "/projects/join/"
      assert html =~ "10"
    end

    test "member can also create an invite link", %{conn: conn, user: member_user} do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")
      lv |> element("button", "Create invite link") |> render_click()

      html =
        lv
        |> form("#invite_form")
        |> render_submit(%{invite: %{expires_in_hours: "", max_uses: "0"}})

      assert html =~ "Invite link created!"
    end

    test "owner can delete an invite link", %{conn: conn, user: owner} do
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      {:ok, lv, html} = live(conn, ~p"/projects/#{project.id}")
      assert html =~ inv.token

      html =
        lv
        |> element("[phx-click='delete_invite'][phx-value-id='#{inv.id}']")
        |> render_click()

      refute html =~ inv.token
      assert is_nil(Ditto.Repo.get(Ditto.Projects.ProjectInvitation, inv.id))
    end

    test "member does not see Delete button on invite links", %{conn: conn, user: member_user} do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)
      member_inv = invitation_fixture(project, owner)
      {:ok, _} = Projects.join_via_token(member_user, inv.token)

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      refute html =~ "phx-click=\"delete_invite\""
      _ = member_inv
    end

    test "invite link shows expiry and max uses info", %{conn: conn, user: owner} do
      project = project_fixture(owner)
      future = DateTime.add(DateTime.utc_now(:second), 86_400, :second)
      invitation_fixture(project, owner, %{expires_at: future, max_uses: 5})

      {:ok, _lv, html} = live(conn, ~p"/projects/#{project.id}")
      assert html =~ "5"
      assert html =~ "0/5 uses"
    end
  end
end
