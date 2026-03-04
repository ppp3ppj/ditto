defmodule Ditto.TestingTest do
  use Ditto.DataCase, async: true

  alias Ditto.Testing
  alias Ditto.Testing.{Suite, Scenario, Case, Step, Run, Result}

  import Ditto.AccountsFixtures
  import Ditto.ProjectsFixtures
  import Ditto.TestingFixtures

  # ---------------------------------------------------------------------------
  # Suites
  # ---------------------------------------------------------------------------

  describe "create_suite/2" do
    test "creates a suite with valid attributes" do
      owner = user_fixture()
      project = project_fixture(owner)

      assert {:ok, suite} = Testing.create_suite(project, %{"name" => "Login Tests"})
      assert suite.name == "Login Tests"
      assert suite.project_id == project.id
    end

    test "returns error when name is blank" do
      owner = user_fixture()
      project = project_fixture(owner)

      assert {:error, changeset} = Testing.create_suite(project, %{"name" => ""})
      assert %{name: [_ | _]} = errors_on(changeset)
    end

    test "stores optional description" do
      owner = user_fixture()
      project = project_fixture(owner)

      {:ok, suite} =
        Testing.create_suite(project, %{"name" => "S", "description" => "Some desc"})

      assert suite.description == "Some desc"
    end
  end

  describe "list_suites/1" do
    test "returns all suites for a project in insertion order" do
      owner = user_fixture()
      project = project_fixture(owner)

      s1 = suite_fixture(project, %{"name" => "A"})
      s2 = suite_fixture(project, %{"name" => "B"})

      ids = Testing.list_suites(project) |> Enum.map(& &1.id)
      assert ids == [s1.id, s2.id]
    end

    test "does not return suites from other projects" do
      owner = user_fixture()
      project = project_fixture(owner)
      other_project = project_fixture(owner)

      suite_fixture(other_project)

      assert Testing.list_suites(project) == []
    end
  end

  describe "update_suite/2" do
    test "updates name and description" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:ok, updated} =
               Testing.update_suite(suite, %{"name" => "New Name", "description" => "New desc"})

      assert updated.name == "New Name"
      assert updated.description == "New desc"
    end

    test "returns error when name is blank" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:error, changeset} = Testing.update_suite(suite, %{"name" => ""})
      assert %{name: [_ | _]} = errors_on(changeset)
    end
  end

  describe "delete_suite/1" do
    test "deletes the suite" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:ok, _} = Testing.delete_suite(suite)
      assert Repo.aggregate(Suite, :count) == 0
    end

    test "cascades to scenarios and cases" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)

      Testing.delete_suite(suite)

      assert Repo.aggregate(Scenario, :count) == 0
      assert Repo.aggregate(Case, :count) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Scenarios
  # ---------------------------------------------------------------------------

  describe "create_scenario/2" do
    test "creates a scenario with position assigned" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:ok, sc} = Testing.create_scenario(suite, %{"name" => "Happy Path"})
      assert sc.suite_id == suite.id
      assert sc.position == 0
    end

    test "increments position for each new scenario" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      {:ok, sc1} = Testing.create_scenario(suite, %{"name" => "A"})
      {:ok, sc2} = Testing.create_scenario(suite, %{"name" => "B"})

      assert sc1.position == 0
      assert sc2.position == 1
    end

    test "returns error when name is blank" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:error, changeset} = Testing.create_scenario(suite, %{"name" => ""})
      assert %{name: [_ | _]} = errors_on(changeset)
    end
  end

  describe "move_scenario_up/1 and move_scenario_down/1" do
    test "swaps positions correctly" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      sc1 = scenario_fixture(suite, %{"name" => "First"})
      sc2 = scenario_fixture(suite, %{"name" => "Second"})

      Testing.move_scenario_down(sc1)

      [first, second] = Testing.list_scenarios(suite)
      assert first.id == sc2.id
      assert second.id == sc1.id
    end

    test "move_up on first scenario is a no-op" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      sc = scenario_fixture(suite)
      assert :ok = Testing.move_scenario_up(sc)
    end
  end

  # ---------------------------------------------------------------------------
  # Cases
  # ---------------------------------------------------------------------------

  describe "create_case/2" do
    test "creates a case with position assigned" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)

      assert {:ok, tc} = Testing.create_case(scenario, %{"name" => "Login with valid creds"})
      assert tc.scenario_id == scenario.id
      assert tc.position == 0
    end

    test "returns error when name is blank" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)

      assert {:error, changeset} = Testing.create_case(scenario, %{"name" => ""})
      assert %{name: [_ | _]} = errors_on(changeset)
    end
  end

  describe "delete_case/1" do
    test "cascades to steps" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      tc = case_fixture(scenario)
      step_fixture(tc)

      Testing.delete_case(tc)

      assert Repo.aggregate(Step, :count) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Steps
  # ---------------------------------------------------------------------------

  describe "create_step/2" do
    test "creates a step with a description" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      tc = case_fixture(scenario)

      assert {:ok, step} =
               Testing.create_step(tc, %{
                 "description" => "Click login",
                 "expected_result" => "Dashboard appears"
               })

      assert step.description == "Click login"
      assert step.expected_result == "Dashboard appears"
      assert step.case_id == tc.id
    end

    test "returns error when description is blank" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      tc = case_fixture(scenario)

      assert {:error, changeset} = Testing.create_step(tc, %{"description" => ""})
      assert %{description: [_ | _]} = errors_on(changeset)
    end
  end

  # ---------------------------------------------------------------------------
  # Runs
  # ---------------------------------------------------------------------------

  describe "create_run/4" do
    test "creates a run with pending results for each case in selected suites" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "Case A"})
      case_fixture(scenario, %{"name" => "Case B"})

      assert {:ok, run} =
               Testing.create_run(project, owner, "My Run", %{
                 suite_ids: [suite.id],
                 scenario_ids: []
               })

      assert run.name == "My Run"
      assert run.status == "pending"
      assert run.project_id == project.id

      results = Testing.list_results(run)
      assert length(results) == 2
      assert Enum.all?(results, &(&1.status == "pending"))
    end

    test "snapshots case name at creation time" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      tc = case_fixture(scenario, %{"name" => "Original Name"})

      {:ok, run} =
        Testing.create_run(project, owner, "Run", %{suite_ids: [suite.id], scenario_ids: []})

      Testing.update_case(tc, %{"name" => "Renamed"})

      [result] = Testing.list_results(run)
      assert result.case_name == "Original Name"
    end

    test "deduplicates cases when suite and scenario both selected" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)

      {:ok, run} =
        Testing.create_run(project, owner, "Run", %{
          suite_ids: [suite.id],
          scenario_ids: [scenario.id]
        })

      assert length(Testing.list_results(run)) == 1
    end

    test "creates an empty run when no cases exist in selection" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert {:ok, run} =
               Testing.create_run(project, owner, "Empty Run", %{
                 suite_ids: [suite.id],
                 scenario_ids: []
               })

      assert Testing.list_results(run) == []
    end
  end

  describe "delete_run/1" do
    test "deletes run and cascades to results" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)
      run = run_fixture(project, owner, [suite.id])

      {:ok, _} = Testing.delete_run(run)

      assert Repo.aggregate(Run, :count) == 0
      assert Repo.aggregate(Result, :count) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Results & auto-completion
  # ---------------------------------------------------------------------------

  describe "update_result/3" do
    test "marks a result as pass and records executor" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)
      run = run_fixture(project, owner, [suite.id])

      [result] = Testing.list_results(run)
      assert {:ok, updated} =
               Testing.update_result(Repo.get!(Result, result.id), owner, %{"status" => "pass"})

      assert updated.status == "pass"
      assert updated.executed_by_id == owner.id
      assert updated.executed_at != nil
    end

    test "auto-completes run when all results are marked" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "C1"})
      case_fixture(scenario, %{"name" => "C2"})
      run = run_fixture(project, owner, [suite.id])

      [r1, r2] = Testing.list_results(run)

      Testing.update_result(Repo.get!(Result, r1.id), owner, %{"status" => "pass"})
      assert Testing.get_run!(run.id).status == "in_progress"

      Testing.update_result(Repo.get!(Result, r2.id), owner, %{"status" => "fail"})
      assert Testing.get_run!(run.id).status == "completed"
    end

    test "transitions run from pending to in_progress on first mark" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "C1"})
      case_fixture(scenario, %{"name" => "C2"})
      run = run_fixture(project, owner, [suite.id])

      assert run.status == "pending"

      [r1, _r2] = Testing.list_results(run)
      Testing.update_result(Repo.get!(Result, r1.id), owner, %{"status" => "skip"})

      assert Testing.get_run!(run.id).status == "in_progress"
    end

    test "saves notes on a result" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)
      run = run_fixture(project, owner, [suite.id])

      [result] = Testing.list_results(run)

      {:ok, updated} =
        Testing.update_result(Repo.get!(Result, result.id), owner, %{
          "status" => "fail",
          "notes" => "Broken on mobile"
        })

      assert updated.notes == "Broken on mobile"
    end
  end

  describe "run_progress/1" do
    test "returns correct counts" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "C1"})
      case_fixture(scenario, %{"name" => "C2"})
      case_fixture(scenario, %{"name" => "C3"})
      run = run_fixture(project, owner, [suite.id])

      [r1, r2, _r3] = Testing.list_results(run)
      Testing.update_result(Repo.get!(Result, r1.id), owner, %{"status" => "pass"})
      Testing.update_result(Repo.get!(Result, r2.id), owner, %{"status" => "fail"})

      progress = Testing.run_progress(run)

      assert progress == %{total: 3, pass: 1, fail: 1, skip: 0, pending: 1}
    end

    test "returns all-pending for a fresh run" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)
      run = run_fixture(project, owner, [suite.id])

      assert %{total: 1, pass: 0, fail: 0, skip: 0, pending: 1} = Testing.run_progress(run)
    end
  end

  # ---------------------------------------------------------------------------
  # finish_run/1
  # ---------------------------------------------------------------------------

  describe "finish_run/1" do
    test "force-completes a run even with pending results" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "C1"})
      case_fixture(scenario, %{"name" => "C2"})
      run = run_fixture(project, owner, [suite.id])

      [r1, _r2] = Testing.list_results(run)
      Testing.update_result(Repo.get!(Result, r1.id), owner, %{"status" => "pass"})

      assert :ok = Testing.finish_run(run)

      completed = Testing.get_run!(run.id)
      assert completed.status == "completed"
      assert completed.completed_at != nil
    end

    test "pending results remain pending after finish" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario)
      run = run_fixture(project, owner, [suite.id])

      Testing.finish_run(run)

      progress = Testing.run_progress(run)
      assert progress.pending == 1
    end
  end

  # ---------------------------------------------------------------------------
  # next_rerun_name/2
  # ---------------------------------------------------------------------------

  describe "next_rerun_name/2" do
    test "appends (rerun 1) when no reruns exist" do
      assert Testing.next_rerun_name("My Run", ["My Run", "Other Run"]) == "My Run (rerun 1)"
    end

    test "increments to next available number" do
      existing = ["My Run", "My Run (rerun 1)", "My Run (rerun 2)"]
      assert Testing.next_rerun_name("My Run", existing) == "My Run (rerun 3)"
    end

    test "strips existing (rerun N) suffix before computing next" do
      existing = ["My Run", "My Run (rerun 1)"]
      assert Testing.next_rerun_name("My Run (rerun 1)", existing) == "My Run (rerun 2)"
    end

    test "handles gaps and picks max+1" do
      existing = ["My Run (rerun 1)", "My Run (rerun 5)"]
      assert Testing.next_rerun_name("My Run", existing) == "My Run (rerun 6)"
    end

    test "handles names with parentheses" do
      existing = ["My (special) Run"]
      assert Testing.next_rerun_name("My (special) Run", existing) == "My (special) Run (rerun 1)"
    end
  end

  # ---------------------------------------------------------------------------
  # rerun_preview_counts/1
  # ---------------------------------------------------------------------------

  describe "rerun_preview_counts/1" do
    test "returns correct counts per filter" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "Pass"})
      case_fixture(scenario, %{"name" => "Fail"})
      case_fixture(scenario, %{"name" => "Skip"})
      run = run_fixture(project, owner, [suite.id])

      [r_pass, r_fail, r_skip] = Testing.list_results(run)
      Testing.update_result(Repo.get!(Result, r_pass.id), owner, %{"status" => "pass"})
      Testing.update_result(Repo.get!(Result, r_fail.id), owner, %{"status" => "fail"})
      Testing.update_result(Repo.get!(Result, r_skip.id), owner, %{"status" => "skip"})

      counts = Testing.rerun_preview_counts(Testing.get_run!(run.id))

      assert counts.all == 3
      assert counts.passed == 1
      assert counts.failed == 1
      assert counts.skipped == 1
      assert counts.failed_and_skipped == 2
    end
  end

  # ---------------------------------------------------------------------------
  # rerun_run/4
  # ---------------------------------------------------------------------------

  describe "rerun_run/4" do
    setup do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      scenario = scenario_fixture(suite)
      case_fixture(scenario, %{"name" => "Pass"})
      case_fixture(scenario, %{"name" => "Fail"})
      case_fixture(scenario, %{"name" => "Skip"})
      run = run_fixture(project, owner, [suite.id])

      [r_pass, r_fail, r_skip] = Testing.list_results(run)
      Testing.update_result(Repo.get!(Result, r_pass.id), owner, %{"status" => "pass"})
      Testing.update_result(Repo.get!(Result, r_fail.id), owner, %{"status" => "fail"})
      Testing.update_result(Repo.get!(Result, r_skip.id), owner, %{"status" => "skip"})

      completed_run = Testing.get_run!(run.id)
      %{owner: owner, project: project, run: completed_run}
    end

    test "creates a new run with :all cases", %{owner: owner, project: project, run: run} do
      assert {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun All", :all)
      assert length(Testing.list_results(new_run)) == 3
      assert new_run.project_id == project.id
      assert new_run.status == "pending"
    end

    test "filters to failed cases only with :failed", %{owner: owner, run: run} do
      {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun Fail", :failed)
      results = Testing.list_results(new_run)
      assert length(results) == 1
      assert hd(results).case_name == "Fail"
    end

    test "filters to skipped cases only with :skipped", %{owner: owner, run: run} do
      {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun Skip", :skipped)
      results = Testing.list_results(new_run)
      assert length(results) == 1
      assert hd(results).case_name == "Skip"
    end

    test "includes failed and skipped with :failed_and_skipped", %{owner: owner, run: run} do
      {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun FS", :failed_and_skipped)
      assert length(Testing.list_results(new_run)) == 2
    end

    test "filters to passed cases only with :passed", %{owner: owner, run: run} do
      {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun Pass", :passed)
      results = Testing.list_results(new_run)
      assert length(results) == 1
      assert hd(results).case_name == "Pass"
    end

    test "new run results all start as pending", %{owner: owner, run: run} do
      {:ok, new_run} = Testing.rerun_run(run, owner, "Rerun", :all)
      assert Enum.all?(Testing.list_results(new_run), &(&1.status == "pending"))
    end

  end

  # ---------------------------------------------------------------------------
  # list_run_names/1
  # ---------------------------------------------------------------------------

  describe "list_run_names/1" do
    test "returns all run names for the project" do
      owner = user_fixture()
      project = project_fixture(owner)

      run_fixture(project, owner, [], "Alpha")
      run_fixture(project, owner, [], "Beta")

      names = Testing.list_run_names(project)
      assert "Alpha" in names
      assert "Beta" in names
    end

    test "does not include runs from other projects" do
      owner = user_fixture()
      project = project_fixture(owner)
      other = project_fixture(owner)

      run_fixture(other, owner, [], "Other Run")

      assert Testing.list_run_names(project) == []
    end
  end

  # ---------------------------------------------------------------------------
  # count_cases_in_suite/1
  # ---------------------------------------------------------------------------

  describe "count_cases_in_suite/1" do
    test "returns total case count across all scenarios" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)
      sc1 = scenario_fixture(suite)
      sc2 = scenario_fixture(suite)
      case_fixture(sc1)
      case_fixture(sc1)
      case_fixture(sc2)

      assert Testing.count_cases_in_suite(suite) == 3
    end

    test "returns 0 for empty suite" do
      owner = user_fixture()
      project = project_fixture(owner)
      suite = suite_fixture(project)

      assert Testing.count_cases_in_suite(suite) == 0
    end
  end
end
