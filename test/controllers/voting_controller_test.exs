defmodule ApiWeb.VotingControllerTest do
  use ApiWeb.ConnCase

  alias ApiWeb.{CompetitionActions, TeamActions, Team, Vote, Category, Repo}
  import ApiWeb.StringHelper, only: [slugify: 1]

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

  test "ended with some people 1", %{conn: conn, user: u1} do
    admin = create_admin()

    # Useful
    t1 = create_team(u1)

    # Funny
    u2 = create_user()
    t2 = create_team(u2)

    # Hardcore
    u3 = create_user()
    t3 = create_team(u3)

    # Disqualified
    u4 = create_user()
    t4 = create_team(u4)

    # Not eligible
    u5 = create_user()
    create_team(u5)


    [
      useful,
      funny,
      hardcore,
    ] = [
      Repo.get_by!(Category, name: "useful"),
      Repo.get_by!(Category, name: "funny"),
      Repo.get_by!(Category, name: "hardcore"),
    ]

    annul_paper_vote(create_paper_vote(useful, admin), admin)

    voters =
      (1..3)
      |> Enum.map(fn _n -> create_user() end)

    check_in_everyone()
    [t1, t2, t3, t4] = make_teams_eligible([t1, t2, t3, t4])
    CompetitionActions.start_voting()
    [t1, t2, t3, t4] = [t1, t2, t3, t4] |> Enum.map(fn t -> Repo.get!(Team, t.id) end)

    TeamActions.disqualify(t4.id, admin)

    [v1, v2, v3] = voters |> Enum.map(fn uv ->
      create_vote(uv, "useful", [t1.id])
      create_vote(uv, "funny", [t2.id])
      create_vote(uv, "hardcore", [t3.id])
    end)

    pv_a_u2 = redeem_paper_vote(create_paper_vote(useful, admin), t2, u1, admin)
    pv_b_u2 = redeem_paper_vote(create_paper_vote(useful, admin), t2, u1, admin)
    pv_c_u3 = redeem_paper_vote(create_paper_vote(useful, admin), t3, u1, admin)

    pv_a_f3 = redeem_paper_vote(create_paper_vote(funny, admin), t3, u1, admin)
    pv_b_f3 = redeem_paper_vote(create_paper_vote(funny, admin), t3, u1, admin)
    pv_c_f1 = redeem_paper_vote(create_paper_vote(funny, admin), t1, u1, admin)

    pv_a_h1 = redeem_paper_vote(create_paper_vote(hardcore, admin), t1, u1, admin)
    pv_b_h1 = redeem_paper_vote(create_paper_vote(hardcore, admin), t1, u1, admin)
    pv_c_h2 = redeem_paper_vote(create_paper_vote(hardcore, admin), t2, u1, admin)

    CompetitionActions.end_voting()
    conn = get conn, voting_path(conn, :info_end)
    assert json_response(conn, 200) ==  %{
      "paper_votes" => %{"initial_count" => 9, "final_count" => 9},
      "participants" => %{"initial_count" => 8, "final_count" => 7},
      "teams" => %{
        slugify(t1.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t1),
            "key" => t1.prize_preference_hmac_secret,
            "contents" => Enum.join(t1.prize_preference || [], ","),
          },
          "tie_breaker" => t1.tie_breaker,
          "disqualified" => false,
        },
        slugify(t2.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t2),
            "key" => t2.prize_preference_hmac_secret,
            "contents" => Enum.join(t2.prize_preference || [], ","),
          },
          "tie_breaker" => t2.tie_breaker,
          "disqualified" => false,
        },
        slugify(t3.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t3),
            "key" => t3.prize_preference_hmac_secret,
            "contents" => Enum.join(t3.prize_preference || [], ","),
          },
          "tie_breaker" => t3.tie_breaker,
          "disqualified" => false,
        },
        slugify(t4.name) => %{
          "prize_preference" => %{
            "hmac" => Team.preference_hmac(t4),
          },
          "tie_breaker" => t4.tie_breaker,
          "disqualified" => true,
        },
      },
      "podiums" => %{
        "useful" => [slugify(t1.name), slugify(t2.name), slugify(t3.name)],
        "funny" => [slugify(t2.name), slugify(t3.name), slugify(t1.name)],
        "hardcore" => [slugify(t3.name), slugify(t1.name), slugify(t2.name)],
      },
      "votes" => %{
        "useful" => %{
          v1.voter_identity => [slugify(t1.name)],
          v2.voter_identity => [slugify(t1.name)],
          v3.voter_identity => [slugify(t1.name)],
          pv_a_u2.id => [slugify(t2.name)],
          pv_b_u2.id => [slugify(t2.name)],
          pv_c_u3.id => [slugify(t3.name)],
        },
        "funny" => %{
          v1.voter_identity => [slugify(t2.name)],
          v2.voter_identity => [slugify(t2.name)],
          v3.voter_identity => [slugify(t2.name)],
          pv_a_f3.id => [slugify(t3.name)],
          pv_b_f3.id => [slugify(t3.name)],
          pv_c_f1.id => [slugify(t1.name)],
        },
        "hardcore" => %{
          v1.voter_identity => [slugify(t3.name)],
          v2.voter_identity => [slugify(t3.name)],
          v3.voter_identity => [slugify(t3.name)],
          pv_a_h1.id => [slugify(t1.name)],
          pv_b_h1.id => [slugify(t1.name)],
          pv_c_h2.id => [slugify(t2.name)],
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

  test "user can't edit his votes before the competition begins", %{conn: conn0, jwt: jwt, user: u1} do
    create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    conn1 = conn0
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn0, :upsert_votes), votes: %{
      useful: [t3.id, t2.id],
      hardcore: [t2.id],
      funny: [t3.id, t2.id]
    })

    assert json_response(conn1, 422)["errors"] == "Competition hasn't started yet"
  end

  test "user can't edit his votes after competition end", %{conn: conn0, jwt: jwt, user: u1} do
    create_team(u1)

    t2 = create_team(create_user())
    t3 = create_team(create_user())

    check_in_everyone()
    make_teams_eligible()

    CompetitionActions.start_voting()

    create_vote(u1, "useful", [t2.id])
    create_vote(u1, "hardcore", [t3.id])
    create_vote(u1, "funny", [t2.id, t3.id])

    conn1 = conn0
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn0, :upsert_votes), votes: %{
      useful: [t3.id, t2.id],
      hardcore: [t2.id],
      funny: [t3.id, t2.id]
    })

    assert json_response(conn1, 200) == %{
      "useful" => [t3.id, t2.id],
      "hardcore" => [t2.id],
      "funny" => [t3.id, t2.id]
    }

    CompetitionActions.end_voting()

    conn2 = conn0
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(voting_path(conn0, :upsert_votes), votes: %{
      useful: [t2.id],
      hardcore: [t3.id],
      funny: [t2.id],
    })

    assert json_response(conn2, 422)["errors"] == "Competition already ended"

    assert Repo.get_by!(
      Vote,
      voter_identity: u1.voter_identity,
      category_id: Repo.get_by!(Category, name: "useful").id
    ).ballot == [t3.id, t2.id]

    assert Repo.get_by!(
      Vote,
      voter_identity: u1.voter_identity,
      category_id: Repo.get_by!(Category, name: "hardcore").id
    ).ballot == [t2.id]

    assert Repo.get_by!(
      Vote,
      voter_identity: u1.voter_identity,
      category_id: Repo.get_by!(Category, name: "funny").id
    ).ballot == [t3.id, t2.id]
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
