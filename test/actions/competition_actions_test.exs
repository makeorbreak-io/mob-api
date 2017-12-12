defmodule ApiWeb.CompetitionActionsTest do
  use ApiWeb.ModelCase

  alias ApiWeb.{CompetitionActions}

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
    :already_started = CompetitionActions.start_voting()
  end

  test "end_voting without starting" do
    :not_started = CompetitionActions.end_voting()
  end

  test "end_voting twice" do
    {:ok, _} = CompetitionActions.start_voting()
    {:ok, _} = CompetitionActions.end_voting()
    :already_ended = CompetitionActions.end_voting()
  end
end

defmodule ApiWeb.CompetitionActionsTest.CalculatePodium do
  use ApiWeb.ModelCase

  alias ApiWeb.{CompetitionActions, Category}
  alias Ecto.{Changeset}

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
    CompetitionActions.start_voting()

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
    assert CompetitionActions.calculate_podium(cat) == [
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
    assert CompetitionActions.calculate_podium(cat) == [
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
    CompetitionActions.resolve_voting!

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