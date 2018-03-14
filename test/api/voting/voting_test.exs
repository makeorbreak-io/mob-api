defmodule Api.VotingTest do
  use Api.DataCase

  alias Api.Competitions
  alias Api.Teams
  alias Api.Teams.Team
  alias Api.Voting

  setup do
    member = create_user()
    team = create_team(member, create_competition())

    [member] = check_in_everyone()

    {
      :ok,
      %{
        category: create_category(),
        admin: create_admin(),
        member: member,
        team: team,
      },
    }
  end

  # test "create", %{category: c, admin: a} do
  #   {:ok, _} = Voting.create_paper_vote(c, a)
  # end

  # test "create after end", %{category: c, admin: a} do
  #   Competitions.start_voting()
  #   Competitions.end_voting()

  #   :already_ended = Voting.create_paper_vote(c, a)
  # end

  # test "redeem", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])
  #   Competitions.start_voting()

  #   {:ok, _} = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem not twice", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])
  #   Competitions.start_voting()

  #   {:ok, p} = Voting.redeem_paper_vote(p, t, m, a)
  #   :already_redeemed = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem not annulled", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])
  #   Competitions.start_voting()

  #   {:ok, p} = Voting.annul_paper_vote(p, a)
  #   :annulled = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem not eligible", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   # Notice I'm not making teams eligible
  #   Competitions.start_voting()

  #   :team_not_eligible = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem disqualified", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])
  #   Competitions.start_voting()

  #   Teams.disqualify_team(t.id, a)
  #   t = Repo.get!(Team, t.id)

  #   :team_disqualified = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem before start", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])

  #   :not_started = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "redeem after end", %{category: c, admin: a, member: m, team: t} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   [t] = make_teams_eligible([t])
  #   Competitions.start_voting()
  #   Competitions.end_voting()

  #   :already_ended = Voting.redeem_paper_vote(p, t, m, a)
  # end

  # test "annul", %{category: c, admin: a} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)
  #   {:ok, _} = Voting.annul_paper_vote(p, a)
  # end

  # test "annul after end", %{category: c, admin: a} do
  #   {:ok, p} = Voting.create_paper_vote(c, a)

  #   Competitions.start_voting()
  #   Competitions.end_voting()

  #   :already_ended = Voting.annul_paper_vote(p, a)
  # end
end

defmodule Api.VotingTest.CalculatePodium do
  use Api.DataCase

  alias Api.Voting
  alias Api.Competitions
  alias Api.Competitions.Category
  alias Ecto.Changeset

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
