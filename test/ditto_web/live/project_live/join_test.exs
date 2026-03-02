defmodule DittoWeb.ProjectLive.JoinTest do
  use DittoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures

  describe "Join page" do
    setup :register_and_log_in_user

    test "shows project info for a valid invite token", %{conn: conn, user: user} do
      owner = user_fixture()
      project = project_fixture(owner, %{"name" => "Invite Me Project"})
      inv = invitation_fixture(project, owner)

      {:ok, _lv, html} = live(conn, ~p"/projects/join/#{inv.token}")

      assert html =~ "You&#39;re invited!"
      assert html =~ "Invite Me Project"
      assert html =~ "Join Project"
      _ = user
    end

    test "joining adds user as member and redirects to project", %{conn: conn, user: user} do
      owner = user_fixture()
      project = project_fixture(owner, %{"name" => "Team Project"})
      inv = invitation_fixture(project, owner)

      {:ok, lv, _html} = live(conn, ~p"/projects/join/#{inv.token}")

      {:ok, _show_lv, html} =
        lv
        |> element("button", "Join Project")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Team Project"
      assert html =~ "You joined Team Project!"
      assert Ditto.Projects.member?(project, user)
    end

    test "redirects to project if already a member", %{conn: conn, user: user} do
      project = project_fixture(user, %{"name" => "Already In"})
      inv = invitation_fixture(project, user)

      assert {:ok, _lv, html} =
               live(conn, ~p"/projects/join/#{inv.token}")
               |> follow_redirect(conn)

      assert html =~ "Already In"
    end

    test "shows expired message for an expired token", %{conn: conn} do
      owner = user_fixture()
      project = project_fixture(owner)
      past = DateTime.add(DateTime.utc_now(:second), -3600, :second)
      inv = invitation_fixture(project, owner, %{expires_at: past})

      {:ok, _lv, html} = live(conn, ~p"/projects/join/#{inv.token}")
      assert html =~ "Invite Link Expired"
      refute html =~ "Join Project"
    end

    test "shows max uses message when limit reached", %{conn: conn} do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner, %{max_uses: 1, uses_count: 1})

      {:ok, _lv, html} = live(conn, ~p"/projects/join/#{inv.token}")
      assert html =~ "Invite Link Full"
      refute html =~ "Join Project"
    end

    test "shows invalid message for unknown token", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/projects/join/doesnotexist")
      assert html =~ "Invalid Invite Link"
      refute html =~ "Join Project"
    end

    test "redirects to login when not authenticated" do
      owner = user_fixture()
      project = project_fixture(owner)
      inv = invitation_fixture(project, owner)

      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/projects/join/#{inv.token}")
      assert path == ~p"/users/log-in"
    end
  end
end
