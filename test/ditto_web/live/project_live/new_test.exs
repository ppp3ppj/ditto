defmodule DittoWeb.ProjectLive.NewTest do
  use DittoWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "New project page" do
    setup :register_and_log_in_user

    test "renders the create form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/projects/new")
      assert html =~ "New Project"
      assert html =~ "Project name"
    end

    test "creates project and redirects to show page", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      {:ok, _show_lv, html} =
        lv
        |> form("#project_form", project: %{name: "My New Project", description: "Cool stuff"})
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "My New Project"
      assert html =~ "Project created successfully!"
      _ = user
    end

    test "shows validation error for blank name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      html =
        lv
        |> form("#project_form", project: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "shows live validation error on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      html =
        lv
        |> element("#project_form")
        |> render_change(project: %{name: ""})

      assert html =~ "can&#39;t be blank"
    end

    test "redirects to login when not authenticated" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/projects/new")
      assert path == ~p"/users/log-in"
    end
  end
end
