defmodule DittoWeb.ProjectLive.IndexTest do
  use DittoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures

  describe "Index page" do
    setup :register_and_log_in_user

    test "renders empty state when user has no projects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/projects")
      assert html =~ "My Projects"
      assert html =~ "You don&#39;t have any projects yet."
    end

    test "lists projects the user belongs to", %{conn: conn, user: user} do
      project = project_fixture(user, %{"name" => "Awesome App"})

      {:ok, _lv, html} = live(conn, ~p"/projects")
      assert html =~ "Awesome App"
      assert html =~ "owner"
      refute html =~ "You don&#39;t have any projects yet."
      _ = project
    end

    test "does not show projects the user is not a member of", %{conn: conn} do
      other = user_fixture()
      project_fixture(other, %{"name" => "Secret Project"})

      {:ok, _lv, html} = live(conn, ~p"/projects")
      refute html =~ "Secret Project"
    end

    test "New Project button links to /projects/new", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/projects")
      assert lv |> element("a", "New Project") |> render() =~ "/projects/new"
    end

    test "redirects to login when not authenticated", %{conn: _conn} do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/projects")
      assert path == ~p"/users/log-in"
    end
  end
end
