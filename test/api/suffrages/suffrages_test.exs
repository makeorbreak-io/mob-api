defmodule Api.SuffragesTest do
  use Api.DataCase

  alias Api.Suffrages
  alias Api.Suffrages.Candidate
  alias Api.Teams.Team

  setup do
    member = create_user()
    competition = create_competition()
    create_competition_attendance(competition, member)
    team = create_team(member, competition)

    check_in_everyone(competition.id)

    {
      :ok,
      %{
        competition: competition,
        suffrage: create_suffrage(competition.id),
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

  test "redeem paper vote", %{suffrage: s, admin: a, member: m, team: t, competition: c} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)

    {:ok, _} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not twice",
    %{suffrage: s, admin: a, member: m, team: t, competition: c} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    make_teams_eligible(c.id)
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

    :team_not_candidate = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote disqualified", %{suffrage: s, admin: a, member: m, team: t, competition: c} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)
    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)

    Suffrages.disqualify_team(t.id, s.id, a)
    t = Repo.get!(Team, t.id)

    Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote before start", %{suffrage: s, admin: a, member: m, team: t} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    :not_started = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote after end", %{suffrage: s, admin: a, member: m, team: t, competition: c} do
    {:ok, p} = Suffrages.create_paper_vote(s, a)

    make_teams_eligible(c.id)
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

  test "disqualify team", %{team: t1, suffrage: s1, competition: c1} do
    admin = create_admin()

    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    Suffrages.disqualify_team(t1.id, s1.id, admin)

    c = from(
      c in Candidate,
      where: c.team_id == ^t1.id,
      where: c.suffrage_id == ^s1.id )
    |> Repo.one()

    assert c.disqualified_at
    assert c.disqualified_by_id == admin.id
  end

  test "disqualify team twice", %{team: t1, suffrage: s1, competition: c1} do
    admin = create_admin()
    admin2 = create_admin()

    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    Suffrages.disqualify_team(t1.id, s1.id, admin)
    Suffrages.disqualify_team(t1.id, s1.id, admin2)

    c = from(
      c in Candidate,
      where: c.team_id == ^t1.id,
      where: c.suffrage_id == ^s1.id )
    |> Repo.one()

    assert c.disqualified_at
    assert c.disqualified_by_id == admin.id
  end

  test "assign missing preferences to team", %{team: t, competition: c, suffrage: s1} do
    s2 = create_suffrage(c.id)
    s3 = create_suffrage(c.id)

    assert t.prize_preference == nil
    Suffrages.assign_missing_preferences(c.id)
    assert Repo.get!(Team, t.id).prize_preference |> Enum.sort ==
      [s1.id, s2.id, s3.id] |> Enum.sort
  end
end

defmodule Api.SuffragesTest.CalculatePodium do
  use Api.DataCase

  alias Api.Suffrages
  alias Api.Suffrages.Suffrage
  alias Api.Teams.Team

  setup do
    c1 = create_competition()
    s1 = create_suffrage(c1.id)
    u1 = create_attendee(c1)
    t1 = create_team(u1, c1)

    u2 = create_attendee(c1)
    t2 = create_team(u2, c1)

    u3 = create_attendee(c1)
    t3 = create_team(u3, c1)

    u4 = create_attendee(c1)
    t4 = create_team(u4, c1)

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)


    Suffrages.start_suffrage(s1.id)

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
        c1: c1,
        s1: s1
      },
    }
  end

  test "calculate_podium", %{c1: c1, t1: t1, t2: t2, t3: t3, t4: t4, s1: s1} do
    create_vote(create_attendance_with_user(c1), s1, [t1.id, t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])
    create_vote(create_attendance_with_user(c1), s1, [t4.id])

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    assert Suffrages.calculate_podium(s1.id) == [
      t1.id,
      t2.id,
      t3.id,
    ]
  end

  test "calculate_podium tie", %{c1: c1, t1: t1, t2: t2, t3: t3, s1: s1} do
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])

    Team.changeset(t3, %{tie_breaker: 0}) |> Repo.update!
    Team.changeset(t2, %{tie_breaker: 10}) |> Repo.update!
    Team.changeset(t1, %{tie_breaker: 20}) |> Repo.update!

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    assert Suffrages.calculate_podium(s1.id) == [
      t2.id,
      t1.id,
      t3.id,
    ]
  end

  test "resolve_voting", %{t1: t1, t2: t2, t3: t3, c1: c1, s1: s1} do
    s2 = create_suffrage(c1.id)
    s3 = create_suffrage(c1.id)
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])

    create_vote(create_attendance_with_user(c1), s2, [t1.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t3.id])
    create_vote(create_attendance_with_user(c1), s2, [t3.id])

    create_vote(create_attendance_with_user(c1), s3, [t1.id])
    create_vote(create_attendance_with_user(c1), s3, [t1.id])
    create_vote(create_attendance_with_user(c1), s3, [t2.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)
    Suffrages.resolve_suffrage!(s1.id)

    Suffrages.start_suffrage(s2.id)
    Suffrages.resolve_suffrage!(s2.id)

    Suffrages.start_suffrage(s3.id)
    Suffrages.resolve_suffrage!(s3.id)

    assert Repo.get(Suffrage, s1.id).podium == [
      t1.id,
      t2.id,
      t3.id,
    ]
    assert Repo.get(Suffrage, s2.id).podium == [
      t2.id,
      t3.id,
      t1.id,
    ]
    assert Repo.get(Suffrage, s3.id).podium == [
      t3.id,
      t1.id,
      t2.id,
    ]
  end
end
