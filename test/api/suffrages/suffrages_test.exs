defmodule Api.SuffragesTest do
  use Api.DataCase

  alias Api.Suffrages
  alias Api.Teams.Team

  setup do
    member = create_user()
    competition = create_competition()
    create_competition_attendance(competition, member)
    team = create_team(member, competition)

    [member] = check_in_everyone(competition.id)

    {
      :ok,
      %{
        competition: competition,
        suffrage: create_suffrage(competition),
        admin: create_admin(),
        member: member,
        team: team,
      },
    }
  end

  test "before start", %{suffrage: suffrage} do
     assert Suffrages.suffrage_status(suffrage.id) == :not_started
  end

  test "start_suffrage", %{suffrage: suffrage} do
    {:ok, _} = Suffrages.start_suffrage(suffrage.id)
    assert Suffrages.suffrage_status(suffrage.id) == :started
  end

  test "end_suffrage", %{suffrage: suffrage} do
    {:ok, _} = Suffrages.start_suffrage(suffrage.id)
    {:ok, _} = Suffrages.end_suffrage(suffrage.id)
    assert Suffrages.suffrage_status(suffrage.id) == :ended
  end

  test "start_suffrage twice", %{suffrage: suffrage} do
    {:ok, _} = Suffrages.start_suffrage(suffrage.id)
    :already_started = Suffrages.start_suffrage(suffrage.id)
  end

  test "end_suffrage without starting", %{suffrage: suffrage} do
    :not_started = Suffrages.end_suffrage(suffrage.id)
  end

  test "end_suffrage twice", %{suffrage: suffrage} do
    {:ok, _} = Suffrages.start_suffrage(suffrage.id)
    {:ok, _} = Suffrages.end_suffrage(suffrage.id)
    :already_ended = Suffrages.end_suffrage(suffrage.id)
  end

  test "create paper vote", %{suffrage: s, admin: a} do
    {:ok, _} = Suffrages.create_paper_vote(s, a)
  end

  test "create paper vote after end", %{suffrage: s, admin: a} do
    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    :already_ended = Suffrages.create_paper_vote(s, a)
  end

  test "redeem paper vote", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    Suffrages.start_suffrage(s.id)

    {:ok, _} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not twice", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    Suffrages.start_suffrage(s.id)

    {:ok, p} = Suffrages.redeem_paper_vote(p, t, m, s, a)
    :already_redeemed = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not annulled", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    Suffrages.start_suffrage(s.id)

    {:ok, p} = Suffrages.annul_paper_vote(p, a, s)
    :annulled = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not eligible", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    # Notice I'm not making teams eligible
    Suffrages.start_suffrage(s.id)

    :team_not_eligible = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote disqualified", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    Suffrages.start_suffrage(s.id)

    Suffrages.disqualify_team(t, s, a)
    t = Repo.get!(Team, t.id)

    :team_disqualified = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote before start", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    :not_started = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote after end", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    :already_ended = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "annul paper vote", %{suffrage: s, admin: a} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    {:ok, _} = Suffrages.annul_paper_vote(p, a, s)
  end

  test "annul paper vote after end", %{suffrage: s, admin: a} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    :already_ended = Suffrages.annul_paper_vote(p, a, s)
  end
end

defmodule Api.VotingTest.CalculatePodium do
  use Api.DataCase

  alias Api.Competitions

  setup do
    c1 = create_competition()
    u1 = create_user()
    t1 = create_team(u1, c1)

    u2 = create_user()
    t2 = create_team(u2, c1)

    u3 = create_user()
    t3 = create_team(u3, c1)

    u4 = create_user()
    t4 = create_team(u4, c1)

    check_in_everyone(c1.id)
    Suffrages.start_suffrage()

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

  # test "calculate_podium", %{t1: t1, t2: t2, t3: t3, t4: t4} do
  #   cat = create_category()
  #   create_vote(create_user(), cat.name, [t1.id, t2.id])
  #   create_vote(create_user(), cat.name, [t1.id])
  #   create_vote(create_user(), cat.name, [t1.id])
  #   create_vote(create_user(), cat.name, [t2.id])
  #   create_vote(create_user(), cat.name, [t2.id])
  #   create_vote(create_user(), cat.name, [t3.id])
  #   create_vote(create_user(), cat.name, [t3.id])
  #   create_vote(create_user(), cat.name, [t4.id])

  #   check_in_everyone()
  #   assert Voting.calculate_podium(cat) == [
  #     t1.id,
  #     t2.id,
  #     t3.id,
  #   ]
  # end

  # test "calculate_podium tie", %{t1: t1, t2: t2, t3: t3} do
  #   cat = create_category()
  #   create_vote(create_user(), cat.name, [t1.id])
  #   create_vote(create_user(), cat.name, [t1.id])
  #   create_vote(create_user(), cat.name, [t2.id])
  #   create_vote(create_user(), cat.name, [t2.id])
  #   create_vote(create_user(), cat.name, [t3.id])

  #   Changeset.change(t3, tie_breaker: 0) |> Repo.update!
  #   Changeset.change(t2, tie_breaker: 10) |> Repo.update!
  #   Changeset.change(t1, tie_breaker: 20) |> Repo.update!

  #   check_in_everyone()
  #   assert Voting.calculate_podium(cat) == [
  #     t2.id,
  #     t1.id,
  #     t3.id,
  #   ]
  # end

  # test "resolve_voting", %{t1: t1, t2: t2, t3: t3} do
  #   create_vote(create_user(), "useful", [t1.id])
  #   create_vote(create_user(), "useful", [t1.id])
  #   create_vote(create_user(), "useful", [t1.id])
  #   create_vote(create_user(), "useful", [t2.id])
  #   create_vote(create_user(), "useful", [t2.id])
  #   create_vote(create_user(), "useful", [t3.id])

  #   create_vote(create_user(), "funny", [t1.id])
  #   create_vote(create_user(), "funny", [t2.id])
  #   create_vote(create_user(), "funny", [t2.id])
  #   create_vote(create_user(), "funny", [t2.id])
  #   create_vote(create_user(), "funny", [t3.id])
  #   create_vote(create_user(), "funny", [t3.id])

  #   create_vote(create_user(), "hardcore", [t1.id])
  #   create_vote(create_user(), "hardcore", [t1.id])
  #   create_vote(create_user(), "hardcore", [t2.id])
  #   create_vote(create_user(), "hardcore", [t3.id])
  #   create_vote(create_user(), "hardcore", [t3.id])
  #   create_vote(create_user(), "hardcore", [t3.id])

  #   check_in_everyone()
  #   Voting.resolve_voting!

  #   assert Repo.get_by!(Category, name: "useful").podium == [
  #     t1.id,
  #     t2.id,
  #     t3.id,
  #   ]
  #   assert Repo.get_by!(Category, name: "funny").podium == [
  #     t2.id,
  #     t3.id,
  #     t1.id,
  #   ]
  #   assert Repo.get_by!(Category, name: "hardcore").podium == [
  #     t3.id,
  #     t1.id,
  #     t2.id,
  #   ]
  # end
end
