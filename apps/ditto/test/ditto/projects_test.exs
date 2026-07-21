defmodule Ditto.ProjectsTest do
  use Ditto.DataCase

  alias Ditto.Projects
  import Ditto.AccountsFixtures

  describe "projects" do
    alias Ditto.Projects.Project

    import Ditto.ProjectsFixtures

    @invalid_attrs %{name: nil, user_id: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      user = user_fixture()
      valid_attrs = %{name: "some name", user_id: user.id}

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "create_project/1 enforces uniqueness of name per user" do
      user = user_fixture()
      assert {:ok, _project} = Projects.create_project(%{name: "T project", user_id: user.id})

      assert {:error, changeset} =
               Projects.create_project(%{name: "T project", user_id: user.id})

      assert "has already been taken" in errors_on(changeset).name
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "categories" do
    alias Ditto.Projects.Category

    import Ditto.ProjectsFixtures

    @invalid_attrs %{name: nil, project_id: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Projects.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Projects.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      project = project_fixture()
      valid_attrs = %{name: "some name", project_id: project.id}

      assert {:ok, %Category{} = category} = Projects.create_category(valid_attrs)
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_category(@invalid_attrs)
    end

    test "create_category/1 enforces uniqueness of name per project" do
      project = project_fixture()

      assert {:ok, _category} =
               Projects.create_category(%{name: "Develop", project_id: project.id})

      assert {:error, changeset} =
               Projects.create_category(%{name: "Develop", project_id: project.id})

      assert "has already been taken" in errors_on(changeset).name
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Category{} = category} = Projects.update_category(category, update_attrs)
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_category(category, @invalid_attrs)
      assert category == Projects.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Projects.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Projects.change_category(category)
    end
  end

  describe "project_members" do
    alias Ditto.Projects.ProjectMember

    import Ditto.ProjectsFixtures

    @invalid_attrs %{user_id: nil, project_id: nil}

    test "list_project_members/0 returns all project_members" do
      project_member = project_member_fixture()
      assert Projects.list_project_members() == [project_member]
    end

    test "get_project_member!/1 returns the project_member with given id" do
      project_member = project_member_fixture()
      assert Projects.get_project_member!(project_member.id) == project_member
    end

    test "create_project_member/1 with valid data creates a project_member" do
      user = user_fixture()
      project = project_fixture()
      valid_attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, %ProjectMember{} = _project_member} =
               Projects.create_project_member(valid_attrs)
    end

    test "create_project_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project_member(@invalid_attrs)
    end

    test "update_project_member/2 with valid data updates the project_member" do
      project_member = project_member_fixture()
      user = user_fixture()
      project = project_fixture()
      update_attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, %ProjectMember{} = _project_member} =
               Projects.update_project_member(project_member, update_attrs)
    end

    test "update_project_member/2 with invalid data returns error changeset" do
      project_member = project_member_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_project_member(project_member, @invalid_attrs)

      assert project_member == Projects.get_project_member!(project_member.id)
    end

    test "delete_project_member/1 deletes the project_member" do
      project_member = project_member_fixture()
      assert {:ok, %ProjectMember{}} = Projects.delete_project_member(project_member)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project_member!(project_member.id) end
    end

    test "change_project_member/1 returns a project_member changeset" do
      project_member = project_member_fixture()
      assert %Ecto.Changeset{} = Projects.change_project_member(project_member)
    end

    test "create_project_member/1 enforces uniqueness per user/project pair" do
      user = user_fixture()
      project = project_fixture()
      attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, _project_member} = Projects.create_project_member(attrs)
      assert {:error, changeset} = Projects.create_project_member(attrs)
      assert "has already been taken" in errors_on(changeset).user_id
    end
  end
end
