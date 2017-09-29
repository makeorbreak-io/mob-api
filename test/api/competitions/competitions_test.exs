defmodule Api.CompetitionsTest do
  use Api.DataCase

  alias Api.Competitions
  alias Api.Competitions.Team

  @team_valid_attrs %{name: "awesome team"}

  test "before start" do
    assert Competitions.voting_status == :not_started
  end

  test "start_voting" do
    {:ok, _} = Competitions.start_voting()
    assert Competitions.voting_status == :started
  end

  test "end_voting" do
    {:ok, _} = Competitions.start_voting()
    {:ok, _} = Competitions.end_voting()
    assert Competitions.voting_status == :ended
  end

  test "start_voting twice" do
    {:ok, _} = Competitions.start_voting()
    :already_started = Competitions.start_voting()
  end

  test "end_voting without starting" do
    :not_started = Competitions.end_voting()
  end

  test "end_voting twice" do
    {:ok, _} = Competitions.start_voting()
    {:ok, _} = Competitions.end_voting()
    :already_ended = Competitions.end_voting()
  end

  test "shuffle_tie_breakers" do
    initial_teams =
      for _ <- (1..10),
      do: Repo.insert!(Team.changeset(%Team{}, @team_valid_attrs, Repo))

    {:ok, _} = Competitions.shuffle_tie_breakers

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

    Competitions.disqualify_team(t.id, admin)

    t = Repo.get!(Team, t.id)
    assert t.disqualified_at
    assert t.disqualified_by_id == admin.id
  end

  test "disqualify team twice" do
    t = create_team(create_user())
    admin = create_admin()
    admin2 = create_admin()

    Competitions.disqualify_team(t.id, admin)
    d1 = Repo.get!(Team, t.id).disqualified_at

    Competitions.disqualify_team(t.id, admin2)

    t = Repo.get!(Team, t.id)
    assert t.disqualified_at == d1
    assert t.disqualified_by_id == admin.id
  end

  test "assign missing preferences to team" do
    t = create_team(create_user())

    assert t.prize_preference == nil
    Competitions.assign_missing_preferences
    assert Repo.get!(Team, t.id).prize_preference |> Enum.sort ==
      ["funny", "hardcore", "useful"] |> Enum.sort
  end
end

defmodule Api.CompetitionsTest.CalculatePodium do
  use Api.DataCase

  alias Api.Voting
  alias Api.Competitions
  alias Api.Competitions.Category
  alias Ecto.Changeset

  setup do
    u1 = create_user()
    t1 = create_team(u1)

    u2 = create_user()
    t2 = create_team(u2)

    u3 = create_user()
    t3 = create_team(u3)

    u4 = create_user()
    t4 = create_team(u4)

    check_in_everyone()
    make_teams_eligible()
    Competitions.start_voting()

    {
      :ok,
      %{
        u1: u1,
        u2: u2,
        u3: u3,
        t1: t1,
        t2: t2,
        t3: t3,
        t4: t4,
      },
    }
  end

  test "calculate_podium", %{t1: t1, t2: t2, t3: t3, t4: t4} do
    cat = create_category()
    create_vote(create_user(), cat.name, [t1.id, t2.id])
    create_vote(create_user(), cat.name, [t1.id])
    create_vote(create_user(), cat.name, [t1.id])
    create_vote(create_user(), cat.name, [t2.id])
    create_vote(create_user(), cat.name, [t2.id])
    create_vote(create_user(), cat.name, [t3.id])
    create_vote(create_user(), cat.name, [t3.id])
    create_vote(create_user(), cat.name, [t4.id])

    check_in_everyone()
    assert Voting.calculate_podium(cat) == [
      t1.id,
      t2.id,
      t3.id,
    ]
  end

  test "calculate_podium tie", %{t1: t1, t2: t2, t3: t3} do
    cat = create_category()
    create_vote(create_user(), cat.name, [t1.id])
    create_vote(create_user(), cat.name, [t1.id])
    create_vote(create_user(), cat.name, [t2.id])
    create_vote(create_user(), cat.name, [t2.id])
    create_vote(create_user(), cat.name, [t3.id])

    Changeset.change(t3, tie_breaker: 0) |> Repo.update!
    Changeset.change(t2, tie_breaker: 10) |> Repo.update!
    Changeset.change(t1, tie_breaker: 20) |> Repo.update!

    check_in_everyone()
    assert Voting.calculate_podium(cat) == [
      t2.id,
      t1.id,
      t3.id,
    ]
  end

  test "resolve_voting", %{t1: t1, t2: t2, t3: t3} do
    create_vote(create_user(), "useful", [t1.id])
    create_vote(create_user(), "useful", [t1.id])
    create_vote(create_user(), "useful", [t1.id])
    create_vote(create_user(), "useful", [t2.id])
    create_vote(create_user(), "useful", [t2.id])
    create_vote(create_user(), "useful", [t3.id])

    create_vote(create_user(), "funny", [t1.id])
    create_vote(create_user(), "funny", [t2.id])
    create_vote(create_user(), "funny", [t2.id])
    create_vote(create_user(), "funny", [t2.id])
    create_vote(create_user(), "funny", [t3.id])
    create_vote(create_user(), "funny", [t3.id])

    create_vote(create_user(), "hardcore", [t1.id])
    create_vote(create_user(), "hardcore", [t1.id])
    create_vote(create_user(), "hardcore", [t2.id])
    create_vote(create_user(), "hardcore", [t3.id])
    create_vote(create_user(), "hardcore", [t3.id])
    create_vote(create_user(), "hardcore", [t3.id])

    check_in_everyone()
    Voting.resolve_voting!

    assert Repo.get_by!(Category, name: "useful").podium == [
      t1.id,
      t2.id,
      t3.id,
    ]
    assert Repo.get_by!(Category, name: "funny").podium == [
      t2.id,
      t3.id,
      t1.id,
    ]
    assert Repo.get_by!(Category, name: "hardcore").podium == [
      t3.id,
      t1.id,
      t2.id,
    ]
  end
end
