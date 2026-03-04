defmodule Ditto.Testing do
  @moduledoc """
  The Testing context — test suite/scenario/case/step definitions and run execution.
  """

  import Ecto.Query, warn: false

  alias Ditto.Repo
  alias Ditto.Accounts.User
  alias Ditto.Projects.Project
  alias Ditto.Testing.{Suite, Scenario, Case, Step, Run, Result}

  ## Suites

  @doc "Returns all test suites for a project."
  def list_suites(%Project{} = project) do
    from(s in Suite,
      where: s.project_id == ^project.id,
      order_by: [asc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Gets a suite by id. Raises if not found."
  def get_suite!(id), do: Repo.get!(Suite, id)

  @doc "Gets a suite by id, ensuring it belongs to the given project. Raises if not found."
  def get_suite_for_project!(%Project{} = project, id) do
    from(s in Suite, where: s.id == ^id and s.project_id == ^project.id)
    |> Repo.one!()
  end

  @doc "Creates a test suite for a project."
  def create_suite(%Project{} = project, attrs) do
    %Suite{}
    |> Suite.changeset(Map.put(attrs, "project_id", project.id))
    |> Repo.insert()
  end

  @doc "Updates a test suite."
  def update_suite(%Suite{} = suite, attrs) do
    suite
    |> Suite.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a test suite (cascades to scenarios, cases, steps)."
  def delete_suite(%Suite{} = suite), do: Repo.delete(suite)

  @doc "Returns a changeset for creating/editing a suite."
  def change_suite(suite \\ %Suite{}, attrs \\ %{}) do
    Suite.update_changeset(suite, attrs)
  end

  ## Scenarios

  @doc "Returns all scenarios for a suite, ordered by position."
  def list_scenarios(%Suite{} = suite) do
    from(sc in Scenario,
      where: sc.suite_id == ^suite.id,
      order_by: [asc: sc.position, asc: sc.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Gets a scenario by id. Raises if not found."
  def get_scenario!(id), do: Repo.get!(Scenario, id)

  @doc "Creates a scenario for a suite."
  def create_scenario(%Suite{} = suite, attrs) do
    position = next_position(Scenario, :suite_id, suite.id)

    %Scenario{}
    |> Scenario.changeset(Map.merge(attrs, %{"suite_id" => suite.id, "position" => position}))
    |> Repo.insert()
  end

  @doc "Updates a scenario."
  def update_scenario(%Scenario{} = scenario, attrs) do
    scenario
    |> Scenario.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a scenario (cascades to cases and steps)."
  def delete_scenario(%Scenario{} = scenario), do: Repo.delete(scenario)

  @doc "Returns a changeset for creating/editing a scenario."
  def change_scenario(scenario \\ %Scenario{}, attrs \\ %{}) do
    Scenario.update_changeset(scenario, attrs)
  end

  @doc "Moves a scenario up (lower position) within its suite."
  def move_scenario_up(%Scenario{} = scenario) do
    swap_positions(Scenario, :suite_id, scenario.suite_id, scenario, :up)
  end

  @doc "Moves a scenario down (higher position) within its suite."
  def move_scenario_down(%Scenario{} = scenario) do
    swap_positions(Scenario, :suite_id, scenario.suite_id, scenario, :down)
  end

  ## Cases

  @doc "Returns all cases for a scenario, ordered by position."
  def list_cases(%Scenario{} = scenario) do
    from(c in Case,
      where: c.scenario_id == ^scenario.id,
      order_by: [asc: c.position, asc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Gets a case by id. Raises if not found."
  def get_case!(id), do: Repo.get!(Case, id)

  @doc "Creates a case for a scenario."
  def create_case(%Scenario{} = scenario, attrs) do
    position = next_position(Case, :scenario_id, scenario.id)

    %Case{}
    |> Case.changeset(Map.merge(attrs, %{"scenario_id" => scenario.id, "position" => position}))
    |> Repo.insert()
  end

  @doc "Updates a case."
  def update_case(%Case{} = test_case, attrs) do
    test_case
    |> Case.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a case (cascades to steps)."
  def delete_case(%Case{} = test_case), do: Repo.delete(test_case)

  @doc "Returns a changeset for creating/editing a case."
  def change_case(test_case \\ %Case{}, attrs \\ %{}) do
    Case.update_changeset(test_case, attrs)
  end

  @doc "Moves a case up within its scenario."
  def move_case_up(%Case{} = test_case) do
    swap_positions(Case, :scenario_id, test_case.scenario_id, test_case, :up)
  end

  @doc "Moves a case down within its scenario."
  def move_case_down(%Case{} = test_case) do
    swap_positions(Case, :scenario_id, test_case.scenario_id, test_case, :down)
  end

  ## Steps

  @doc "Returns all steps for a case, ordered by position."
  def list_steps(%Case{} = test_case) do
    from(st in Step,
      where: st.case_id == ^test_case.id,
      order_by: [asc: st.position, asc: st.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Gets a step by id. Raises if not found."
  def get_step!(id), do: Repo.get!(Step, id)

  @doc "Creates a step for a case."
  def create_step(%Case{} = test_case, attrs) do
    position = next_position(Step, :case_id, test_case.id)

    %Step{}
    |> Step.changeset(Map.merge(attrs, %{"case_id" => test_case.id, "position" => position}))
    |> Repo.insert()
  end

  @doc "Updates a step."
  def update_step(%Step{} = step, attrs) do
    step
    |> Step.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a step."
  def delete_step(%Step{} = step), do: Repo.delete(step)

  @doc "Returns a changeset for creating/editing a step."
  def change_step(step \\ %Step{}, attrs \\ %{}) do
    Step.update_changeset(step, attrs)
  end

  @doc "Moves a step up within its case."
  def move_step_up(%Step{} = step) do
    swap_positions(Step, :case_id, step.case_id, step, :up)
  end

  @doc "Moves a step down within its case."
  def move_step_down(%Step{} = step) do
    swap_positions(Step, :case_id, step.case_id, step, :down)
  end

  @doc "Returns steps for a list of case IDs, grouped by case_id."
  def list_steps_by_case([]), do: %{}

  def list_steps_by_case(case_ids) when is_list(case_ids) do
    from(s in Step,
      where: s.case_id in ^case_ids,
      order_by: [asc: s.position, asc: s.inserted_at]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.case_id)
  end

  ## Runs

  @doc "Returns all test runs for a project, newest first."
  def list_runs(%Project{} = project) do
    from(r in Run,
      where: r.project_id == ^project.id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Gets a test run by id. Raises if not found."
  def get_run!(id), do: Repo.get!(Run, id)

  @doc """
  Creates a test run and snapshots results for all cases in the selected suites/scenarios.

  `selections` is a map with optional keys:
    - `:suite_ids` — list of suite IDs (all cases in those suites included)
    - `:scenario_ids` — list of scenario IDs (all cases in those scenarios included)
  """
  def create_run(%Project{} = project, %User{} = creator, name, selections) do
    Repo.transact(fn ->
      with {:ok, run} <-
             %Run{}
             |> Run.changeset(%{
               name: name,
               project_id: project.id,
               created_by_id: creator.id,
               status: "pending"
             })
             |> Repo.insert(),
           cases when is_list(cases) <- gather_cases(selections),
           :ok <- insert_results(run, cases) do
        {:ok, run}
      end
    end)
  end

  @doc "Deletes a test run (cascades to results)."
  def delete_run(%Run{} = run), do: Repo.delete(run)

  @doc "Force-completes a run regardless of pending results."
  def finish_run(%Run{} = run) do
    now = DateTime.utc_now(:second)

    from(r in Run, where: r.id == ^run.id)
    |> Repo.update_all(set: [status: "completed", completed_at: now])

    :ok
  end

  @doc "Returns all run names for a project (efficient name-only query)."
  def list_run_names(%Project{} = project) do
    from(r in Run, where: r.project_id == ^project.id, select: r.name)
    |> Repo.all()
  end

  @doc """
  Suggests the next rerun name given an original name and list of existing names.

  Strips any existing " (rerun N)" suffix to get the base name, then finds the
  highest used N and returns "base (rerun N+1)".
  """
  def next_rerun_name(original_name, existing_names) do
    base =
      case Regex.run(~r/^(.*) \(rerun \d+\)$/, original_name) do
        [_full, captured_base] -> captured_base
        nil -> original_name
      end

    used_numbers =
      Enum.flat_map(existing_names, fn name ->
        case Regex.run(~r/^#{Regex.escape(base)} \(rerun (\d+)\)$/, name) do
          [_full, n_str] -> [String.to_integer(n_str)]
          nil -> []
        end
      end)

    next_n = if used_numbers == [], do: 1, else: Enum.max(used_numbers) + 1
    "#{base} (rerun #{next_n})"
  end

  @doc "Returns per-filter case counts for the rerun modal preview."
  def rerun_preview_counts(%Run{} = run) do
    %{total: total, pass: pass, fail: fail, skip: skip} = run_progress(run)

    %{
      all: total,
      failed: fail,
      skipped: skip,
      failed_and_skipped: fail + skip,
      passed: pass
    }
  end

  @doc """
  Creates a new test run as a rerun of `original_run`.

  `filter` is one of: `:all`, `:failed`, `:skipped`, `:failed_and_skipped`, `:passed`

  Cases deleted since the original run are silently omitted.
  """
  def rerun_run(%Run{} = original_run, %User{} = creator, name, filter)
      when filter in [:all, :failed, :skipped, :failed_and_skipped, :passed] do
    Repo.transact(fn ->
      original_results = list_results(original_run)

      statuses_to_include =
        case filter do
          :all -> ["pass", "fail", "skip", "pending"]
          :failed -> ["fail"]
          :skipped -> ["skip"]
          :failed_and_skipped -> ["fail", "skip"]
          :passed -> ["pass"]
        end

      case_ids =
        original_results
        |> Enum.filter(&(&1.status in statuses_to_include))
        |> Enum.map(& &1.case_id)

      with {:ok, run} <-
             %Run{}
             |> Run.changeset(%{
               name: name,
               project_id: original_run.project_id,
               created_by_id: creator.id,
               status: "pending"
             })
             |> Repo.insert(),
           cases <- gather_cases_from_ids(case_ids),
           :ok <- insert_results(run, cases) do
        {:ok, run}
      end
    end)
  end

  ## Results

  @doc "Returns all results for a run, ordered by case position within scenario."
  def list_results(%Run{} = run) do
    from(r in Result,
      where: r.run_id == ^run.id,
      join: c in Case,
      on: c.id == r.case_id,
      join: sc in Scenario,
      on: sc.id == c.scenario_id,
      order_by: [asc: sc.position, asc: sc.inserted_at, asc: c.position, asc: c.inserted_at],
      select: %{
        id: r.id,
        run_id: r.run_id,
        case_id: r.case_id,
        case_name: r.case_name,
        status: r.status,
        notes: r.notes,
        executed_by_id: r.executed_by_id,
        executed_at: r.executed_at,
        scenario_name: sc.name,
        scenario_id: sc.id
      }
    )
    |> Repo.all()
  end

  @doc "Gets a result by id. Raises if not found."
  def get_result!(id), do: Repo.get!(Result, id)

  @doc """
  Updates a test result (status, notes).
  Sets executed_by_id and executed_at automatically.
  Also auto-completes the run if all results are non-pending.
  """
  def update_result(%Result{} = result, %User{} = executor, attrs) do
    now = DateTime.utc_now(:second)

    Repo.transact(fn ->
      with {:ok, updated} <-
             result
             |> Result.update_changeset(
               Map.merge(attrs, %{
                 "executed_by_id" => executor.id,
                 "executed_at" => now
               })
             )
             |> Repo.update() do
        maybe_complete_run(result.run_id)
        {:ok, updated}
      end
    end)
  end

  @doc "Returns progress counts for a run."
  def run_progress(%Run{} = run) do
    results =
      from(r in Result, where: r.run_id == ^run.id, select: r.status)
      |> Repo.all()

    total = length(results)
    pass = Enum.count(results, &(&1 == "pass"))
    fail = Enum.count(results, &(&1 == "fail"))
    skip = Enum.count(results, &(&1 == "skip"))
    pending = Enum.count(results, &(&1 == "pending"))

    %{total: total, pass: pass, fail: fail, skip: skip, pending: pending}
  end

  @doc "Returns all suites with their scenarios for selection (used in run creation)."
  def list_suites_with_scenarios(%Project{} = project) do
    suites = list_suites(project)

    Enum.map(suites, fn suite ->
      scenarios = list_scenarios(suite)
      %{suite: suite, scenarios: scenarios}
    end)
  end

  @doc "Counts cases in a suite."
  def count_cases_in_suite(%Suite{} = suite) do
    from(c in Case,
      join: sc in Scenario,
      on: sc.id == c.scenario_id,
      where: sc.suite_id == ^suite.id
    )
    |> Repo.aggregate(:count)
  end

  ## Private helpers

  defp gather_cases(%{suite_ids: suite_ids, scenario_ids: scenario_ids}) do
    suite_cases =
      if Enum.empty?(suite_ids) do
        []
      else
        from(c in Case,
          join: sc in Scenario,
          on: sc.id == c.scenario_id,
          where: sc.suite_id in ^suite_ids,
          order_by: [asc: sc.position, asc: c.position]
        )
        |> Repo.all()
      end

    scenario_cases =
      if Enum.empty?(scenario_ids) do
        []
      else
        from(c in Case,
          where: c.scenario_id in ^scenario_ids,
          order_by: [asc: c.position]
        )
        |> Repo.all()
      end

    # Merge and deduplicate by id
    all_cases = suite_cases ++ scenario_cases
    all_cases |> Enum.uniq_by(& &1.id)
  end

  defp gather_cases(selections) do
    suite_ids = Map.get(selections, :suite_ids, [])
    scenario_ids = Map.get(selections, :scenario_ids, [])
    gather_cases(%{suite_ids: suite_ids, scenario_ids: scenario_ids})
  end

  defp insert_results(_run, []), do: :ok

  defp insert_results(run, cases) do
    results =
      Enum.reduce_while(cases, {:ok, []}, fn test_case, {:ok, acc} ->
        case %Result{}
             |> Result.changeset(%{
               run_id: run.id,
               case_id: test_case.id,
               case_name: test_case.name,
               status: "pending"
             })
             |> Repo.insert() do
          {:ok, result} -> {:cont, {:ok, [result | acc]}}
          {:error, _} = err -> {:halt, err}
        end
      end)

    case results do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp maybe_complete_run(run_id) do
    pending_count =
      from(r in Result, where: r.run_id == ^run_id and r.status == "pending")
      |> Repo.aggregate(:count)

    if pending_count == 0 do
      now = DateTime.utc_now(:second)

      from(r in Run, where: r.id == ^run_id)
      |> Repo.update_all(set: [status: "completed", completed_at: now])
    else
      from(r in Run, where: r.id == ^run_id and r.status == "pending")
      |> Repo.update_all(set: [status: "in_progress", started_at: DateTime.utc_now(:second)])
    end
  end

  defp gather_cases_from_ids([]), do: []

  defp gather_cases_from_ids(case_ids) when is_list(case_ids) do
    from(c in Case,
      join: sc in Scenario,
      on: sc.id == c.scenario_id,
      where: c.id in ^case_ids,
      order_by: [asc: sc.position, asc: sc.inserted_at, asc: c.position, asc: c.inserted_at]
    )
    |> Repo.all()
  end

  defp next_position(schema, parent_field, parent_id) do
    count =
      from(s in schema, where: field(s, ^parent_field) == ^parent_id)
      |> Repo.aggregate(:count)

    count
  end

  defp swap_positions(schema, parent_field, parent_id, item, direction) do
    siblings =
      from(s in schema,
        where: field(s, ^parent_field) == ^parent_id,
        order_by: [asc: s.position, asc: s.inserted_at]
      )
      |> Repo.all()

    index = Enum.find_index(siblings, &(&1.id == item.id))

    swap_index =
      case direction do
        :up -> index - 1
        :down -> index + 1
      end

    if swap_index >= 0 and swap_index < length(siblings) do
      sibling = Enum.at(siblings, swap_index)

      Repo.transaction(fn ->
        Repo.update_all(from(s in schema, where: s.id == ^item.id),
          set: [position: sibling.position]
        )

        Repo.update_all(from(s in schema, where: s.id == ^sibling.id),
          set: [position: item.position]
        )
      end)

      :ok
    else
      :ok
    end
  end
end
