defmodule Api.Admin.CompetitionControllerTest do
  use Api.ConnCase

  alias Api.{CompetitionActions, UserHelper}
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
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :start_voting))

    assert json_response(conn, 422)["errors"] == "Competition already started"
  end

  test "admin can end voting period", %{conn: conn, jwt: jwt} do
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert response(conn, 204)
  end

  test "admin can't end voting period if it's already ended", %{conn: conn, jwt: jwt} do
    CompetitionActions.start_voting()
    CompetitionActions.end_voting()

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
    CompetitionActions.start_voting()

    pv = create_paper_vote(cat, admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_competition_path(conn, :status))

    assert json_response(conn, 200) == %{
      "unredeemed_paper_votes" => [%{
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
      }],
      "voting_status" => "started",
      "missing_voters" => [
        %{
          "team" => %{
            "id" => t2.id,
            "name" => t2.name
          },
          "users" => [
            %{
              "display_name" => UserHelper.display_name(u2),
              "first_name" => u2.first_name,
              "last_name" => u2.last_name,
              "gravatar_hash" => UserHelper.gravatar_hash(u2),
              "id" => u2.id,
              "tshirt_size" => u2.tshirt_size,
              "email" => u2.email
            },
            %{
              "display_name" => UserHelper.display_name(u3),
              "first_name" => u3.first_name,
              "last_name" => u3.last_name,
              "gravatar_hash" => UserHelper.gravatar_hash(u3),
              "id" => u3.id,
              "tshirt_size" => u3.tshirt_size,
              "email" => u3.email
            }
          ]
        },
        %{
          "team" => %{
            "id" => t3.id,
            "name" => t3.name
          },
          "users" => [
            %{
              "display_name" => UserHelper.display_name(u4),
              "first_name" => u4.first_name,
              "last_name" => u4.last_name,
              "gravatar_hash" => UserHelper.gravatar_hash(u4),
              "id" => u4.id,
              "tshirt_size" => u4.tshirt_size,
              "email" => u4.email
            }
          ]
        }
      ]
    }
  end
end
