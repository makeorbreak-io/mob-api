defmodule Api.VotingControllerTest do
  use Api.ConnCase

  alias Api.{CompetitionActions, TeamActions, Team, Vote, Category, Repo}
  import Api.StringHelper, only: [slugify: 1]

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
      "errors" => "Competition hasn't started yet"
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

  test "started with some people", %{conn: conn, user: u1} do
    cat = create_category()
    admin = create_admin()

    t1 = create_team(u1)

    u2 = create_user()
    t2 = create_team(u2)
    create_membership(t2, create_user())

    u3 = create_user()
    t3 = create_team(u3)
    create_membership(t3, create_user())
    create_membership(t3, create_user())

    create_paper_vote(cat, admin)
    annul_paper_vote(create_paper_vote(cat, admin), admin)

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
        slugify(t2.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t2),
          },
          "tie_breaker" => t2.tie_breaker,
        },
      },
    }
  end

  test "started shows who could vote at the start", %{conn: conn, user: u1} do
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
        slugify(t1.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t1),
          },
          "tie_breaker" => t1.tie_breaker,
        },
      },
    }
  end

  test "valid votes are inserted", %{conn: conn, jwt: jwt, user: u1} do
    create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()


    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn, :upsert_votes), votes: %{
      useful: [t2.id],
      hardcore: [t3.id],
      funny: [t2.id, t3.id]
    })

    assert json_response(conn, 200) == %{
      "useful" => [t2.id],
      "hardcore" => [t3.id],
      "funny" => [t2.id, t3.id]
    }

    category = Repo.get_by(Category, name: "useful")

    vote = Repo.one(from v in Vote,
      where: v.voter_identity == ^u1.voter_identity
        and v.category_id == ^category.id)

    assert vote.ballot == [t2.id]
  end

  test "user can edit his votes", %{conn: conn, jwt: jwt, user: u1} do
    create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()

    create_vote(u1, "useful", [t2.id])
    create_vote(u1, "hardcore", [t3.id])
    create_vote(u1, "funny", [t2.id, t3.id])

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn, :upsert_votes), votes: %{
      useful: [t3.id, t2.id],
      hardcore: [t2.id],
      funny: [t3.id, t2.id]
    })

    assert json_response(conn, 200) == %{
      "useful" => [t3.id, t2.id],
      "hardcore" => [t2.id],
      "funny" => [t3.id, t2.id]
    }

    category = Repo.get_by(Category, name: "useful")

    vote = Repo.one(from v in Vote,
      where: v.voter_identity == ^u1.voter_identity
        and v.category_id == ^category.id)

    assert vote.ballot == [t3.id, t2.id]
  end

  test "invalid votes return error", %{conn: conn, jwt: jwt, user: u1} do
    t1 = create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()


    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn, :upsert_votes), votes: %{
      useful: [t2.id, t1.id],
      hardcore: [t3.id],
      funny: [t2.id, t3.id]
    })

    assert json_response(conn, 422)["errors"] == "Invalid vote"
  end

  test "user can get his current votes", %{conn: conn, jwt: jwt, user: u1} do
    create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()

    create_vote(u1, "useful", [t2.id, t3.id])
    create_vote(u1, "hardcore", [t3.id])
    create_vote(u1, "funny", [t2.id, t3.id])


    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(voting_path(conn, :get_votes))

    assert json_response(conn, 200) == %{
      "useful" => [t2.id, t3.id],
      "hardcore" => [t3.id],
      "funny" => [t2.id, t3.id]
    }
  end
end
