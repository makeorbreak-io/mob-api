defmodule ApiWeb.Admin.CompetitionControllerTest do
  use ApiWeb.ConnCase

  alias Api.Competitions
  alias Api.Teams.Team
  alias Guardian.{Permissions}

  setup %{conn: conn} do
    admin = create_admin()
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "admin can start voting period", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :start_voting))

    assert response(conn, 204)
  end

  test "admin can't start voting period if it's already started", %{conn: conn, jwt: jwt} do
    Competitions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :start_voting))

    assert json_response(conn, 422)["errors"] == "Competition already started"
  end

  test "admin can end voting period", %{conn: conn, jwt: jwt} do
    Competitions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert response(conn, 204)
  end

  test "admin can't end voting period if it's already ended", %{conn: conn, jwt: jwt} do
    Competitions.start_voting()
    Competitions.end_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert json_response(conn, 422)["errors"] == "Competition already ended"
  end

  test "admin can't end voting period if it hasn't started", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert json_response(conn, 422)["errors"] == "Competition hasn't started yet"
  end

  test "status show correct info", %{conn: conn, jwt: jwt, admin: u1} do
    cat = create_category()
    admin = create_admin()

    create_team(u1)

    u2 = create_user()
    u3 = create_user()
    t2 = create_team(u2)
    create_membership(t2, u3)

    u4 = create_user()
    t3 = create_team(u4)

    check_in_everyone()
    make_teams_eligible()

    create_vote(u1, "useful", [t2.id, t3.id])
    create_vote(u1, "hardcore", [t3.id])
    create_vote(u1, "funny", [t2.id, t3.id])

    # Remember this shuffles the tie breakers.
    Competitions.start_voting()

    t2 = Repo.get(Team, t2.id)
    t3 = Repo.get(Team, t3.id)

    pv = create_paper_vote(cat, admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_competition_path(conn, :status))

    assert json_response(conn, 200)["unredeemed_paper_votes"] == [%{
      "annulled_at" => nil,
      "annulled_by_id" => nil,
      "category_id" => cat.id,
      "category_name" => cat.name,
      "created_by_id" => admin.id,
      "id" => pv.id,
      "redeemed_at" => nil,
      "redeeming_admin_id" => nil,
      "redeeming_member_id" => nil,
      "team_id" => nil
    }]

    assert json_response(conn, 200)["voting_status"] == "started"

    missing_voters = json_response(conn, 200)["missing_voters"]

    assert Enum.member?(
      missing_voters,
      %{
        "team" => team_view(t2),
        "users" => [u2, u3]
          |> Enum.sort_by(&(&1.id))
          |> Enum.map(fn u -> admin_user_short_view(u) end)
      }
    )

    assert Enum.member?(
      missing_voters,
      %{
        "team" => team_view(t3),
        "users" => [admin_user_short_view(u4)]
      }
    )
  end
end
