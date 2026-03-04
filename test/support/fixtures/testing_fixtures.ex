defmodule Ditto.TestingFixtures do
  @moduledoc """
  Test helpers for creating testing-domain entities
  (suites, scenarios, cases, steps, runs, results).
  """

  alias Ditto.Testing

  def suite_fixture(project, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "Suite #{System.unique_integer([:positive])}"
      })

    {:ok, suite} = Testing.create_suite(project, attrs)
    suite
  end

  def scenario_fixture(suite, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "Scenario #{System.unique_integer([:positive])}"
      })

    {:ok, scenario} = Testing.create_scenario(suite, attrs)
    scenario
  end

  def case_fixture(scenario, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "Case #{System.unique_integer([:positive])}"
      })

    {:ok, test_case} = Testing.create_case(scenario, attrs)
    test_case
  end

  def step_fixture(test_case, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "description" => "Step #{System.unique_integer([:positive])}"
      })

    {:ok, step} = Testing.create_step(test_case, attrs)
    step
  end

  @doc """
  Creates a run for a project selecting the given suite IDs.
  """
  def run_fixture(project, creator, suite_ids \\ [], name \\ nil) do
    name = name || "Run #{System.unique_integer([:positive])}"

    {:ok, run} =
      Testing.create_run(project, creator, name, %{
        suite_ids: suite_ids,
        scenario_ids: []
      })

    run
  end
end
