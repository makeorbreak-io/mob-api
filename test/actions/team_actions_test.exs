defmodule Api.TeamActionsTest do
  use Api.ModelCase

  alias Api.{Team, TeamActions}

  @valid_attrs %{name: "awesome team"}

  test "shuffle_tie_breakers" do
    initial_teams =
      for _ <- (1..10),
      do: Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))

    {:ok, _} = TeamActions.shuffle_tie_breakers

    tie_breakers = fn
      teams -> Enum.map(teams, &(&1.tie_breaker))
    end
    # This is flaky, since they can happen to be shuffled to their initial
    # order, but I can't think of anything better to check.
    refute tie_breakers.(initial_teams) == tie_breakers.(Team |> Repo.all)
  end
end
