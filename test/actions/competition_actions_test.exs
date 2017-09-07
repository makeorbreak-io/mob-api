defmodule Api.CompetitionActionsTest do
  use Api.ModelCase

  alias Api.{CompetitionActions}

  test "before start" do
    assert CompetitionActions.voting_status == :not_started
  end

  test "start_voting" do
    {:ok, _} = CompetitionActions.start_voting()
    assert CompetitionActions.voting_status == :started
  end

  test "end_voting" do
    {:ok, _} = CompetitionActions.start_voting()
    {:ok, _} = CompetitionActions.end_voting()
    assert CompetitionActions.voting_status == :ended
  end

  test "start_voting twice" do
    {:ok, _} = CompetitionActions.start_voting()
    {:error, :already_started} = CompetitionActions.start_voting()
  end

  test "end_voting without starting" do
    {:error, :not_started} = CompetitionActions.end_voting()
  end

  test "end_voting twice" do
    {:ok, _} = CompetitionActions.start_voting()
    {:ok, _} = CompetitionActions.end_voting()
    {:error, :already_ended} = CompetitionActions.end_voting()
  end
end
