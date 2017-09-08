defmodule Api.VotingControllerTest do
  use Api.ConnCase

  alias Api.{CompetitionActions, PaperVoteActions, TeamActions, StringHelper, Team}

  setup %{conn: conn} do
    user = create_user()
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)

    {:ok, %{
      user: user,
      jwt: jwt,
      claims: full_claims,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "before start", %{conn: conn} do
    conn = get conn, voting_path(conn, :info_begin)

    assert json_response(conn, 404) == %{
      "errors" => "Voting hasn't started yet"
    }
  end

  test "started without people", %{conn: conn} do
    CompetitionActions.start_voting()

    conn = get conn, voting_path(conn, :info_begin)

    assert json_response(conn, 200) ==  %{
      "paper_votes" => %{"initial_count" => 0},
      "participants" => %{"initial_count" => 0},
      "teams" => %{},
    }
  end

  test "started with some people", %{conn: conn} do
    cat = create_category()
    admin = create_admin()

    u1 = create_user()
    t1 = create_team(u1)

    u2 = create_user()
    t2 = create_team(u2)
    create_membership(t2, create_user())

    u3 = create_user()
    t3 = create_team(u3)
    create_membership(t3, create_user())
    create_membership(t3, create_user())

    PaperVoteActions.create(cat, admin)
    PaperVoteActions.annul(
      PaperVoteActions.create(cat, admin),
      admin
    )

    check_in_everyone()
    make_teams_eligible([t1, t2])

    TeamActions.disqualify(t1.id, admin)

    # Remember this shuffles the tie breakers.
    CompetitionActions.start_voting()
    t2 = Repo.get!(Team, t2.id)

    conn = get conn, voting_path(conn, :info_begin)

    assert json_response(conn, 200) ==  %{
      "paper_votes" => %{"initial_count" => 1},
      "participants" => %{"initial_count" => 5},
      "teams" => %{
        StringHelper.slugify(t2.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t2),
          },
          "tie_breaker" => t2.tie_breaker,
        },
      },
    }
  end

  test "started shows who could vote at the start", %{conn: conn} do
    u1 = create_user()
    t1 = create_team(u1)
    create_membership(t1, create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()
    TeamActions.disqualify(t1.id, create_admin())
    t1 = Repo.get!(Team, t1.id)

    conn = get conn, voting_path(conn, :info_begin)

    assert json_response(conn, 200) ==  %{
      "paper_votes" => %{"initial_count" => 0},
      "participants" => %{"initial_count" => 2},
      "teams" => %{
        StringHelper.slugify(t1.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t1),
          },
          "tie_breaker" => t1.tie_breaker,
        },
      },
    }
  end
end
