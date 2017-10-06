defmodule Api.VotingTest do
  use Api.DataCase

  alias Api.Competitions
  alias Api.Teams
  alias Api.Teams.Team
  alias Api.Voting

  setup do
    member = create_user()
    team = create_team(member)

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

  test "create", %{category: c, admin: a} do
    {:ok, _} = Voting.create_paper_vote(c, a)
  end

  test "create after end", %{category: c, admin: a} do
    Competitions.start_voting()
    Competitions.end_voting()

    :already_ended = Voting.create_paper_vote(c, a)
  end

  test "redeem", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])
    Competitions.start_voting()

    {:ok, _} = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem not twice", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])
    Competitions.start_voting()

    {:ok, p} = Voting.redeem_paper_vote(p, t, m, a)
    :already_redeemed = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem not annulled", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])
    Competitions.start_voting()

    {:ok, p} = Voting.annul_paper_vote(p, a)
    :annulled = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem not eligible", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    # Notice I'm not making teams eligible
    Competitions.start_voting()

    :team_not_eligible = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem disqualified", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])
    Competitions.start_voting()

    Teams.disqualify_team(t.id, a)
    t = Repo.get!(Team, t.id)

    :team_disqualified = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem before start", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])

    :not_started = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "redeem after end", %{category: c, admin: a, member: m, team: t} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    [t] = make_teams_eligible([t])
    Competitions.start_voting()
    Competitions.end_voting()

    :already_ended = Voting.redeem_paper_vote(p, t, m, a)
  end

  test "annul", %{category: c, admin: a} do
    {:ok, p} = Voting.create_paper_vote(c, a)
    {:ok, _} = Voting.annul_paper_vote(p, a)
  end

  test "annul after end", %{category: c, admin: a} do
    {:ok, p} = Voting.create_paper_vote(c, a)

    Competitions.start_voting()
    Competitions.end_voting()

    :already_ended = Voting.annul_paper_vote(p, a)
  end
end
