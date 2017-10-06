defmodule Api.TeamsTest do
  use Api.DataCase

  alias Api.Teams
  alias Api.Teams.Team

  @team_valid_attrs %{name: "awesome team"}

  test "shuffle_tie_breakers" do
    initial_teams =
      for _ <- (1..10),
      do: Repo.insert!(Team.changeset(%Team{}, @team_valid_attrs, Repo))

    {:ok, _} = Teams.shuffle_tie_breakers

    tie_breakers = fn
      teams -> Enum.map(teams, &(&1.tie_breaker))
    end
    # This is flaky, since they can happen to be shuffled to their initial
    # order, but I can't think of anything better to check.
    refute tie_breakers.(initial_teams) == tie_breakers.(Team |> Repo.all)
  end

  test "disqualify team" do
    t = create_team(create_user())
    admin = create_admin()

    Teams.disqualify_team(t.id, admin)

    t = Repo.get!(Team, t.id)
    assert t.disqualified_at
    assert t.disqualified_by_id == admin.id
  end

  test "disqualify team twice" do
    t = create_team(create_user())
    admin = create_admin()
    admin2 = create_admin()

    Teams.disqualify_team(t.id, admin)
    d1 = Repo.get!(Team, t.id).disqualified_at

    Teams.disqualify_team(t.id, admin2)

    t = Repo.get!(Team, t.id)
    assert t.disqualified_at == d1
    assert t.disqualified_by_id == admin.id
  end

  test "assign missing preferences to team" do
    t = create_team(create_user())

    assert t.prize_preference == nil
    Teams.assign_missing_preferences
    assert Repo.get!(Team, t.id).prize_preference |> Enum.sort ==
      ["funny", "hardcore", "useful"] |> Enum.sort
  end
end
