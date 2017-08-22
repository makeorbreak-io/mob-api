defmodule Api.AdminStatsControllerTest do
  use Api.ConnCase

  alias Api.{User, WorkshopAttendance}

  setup %{conn: conn} do
    admin = create_admin
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Guardian.Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "correct statistics are given", %{conn: conn, admin: admin, jwt: jwt} do
    Repo.insert! %User{}
    Repo.insert! %User{}
    team_owner = Repo.insert! %User{}
    create_team(%{user_id: admin.id, name: "awesome team"})
    create_team(%{user_id: team_owner.id, name: "awesome team", applied: true})
    workshop = create_workshop
    workshop_attendee = create_user(%{
      email: "example@email.com",
      first_name: "Jane",
      last_name: "doe",
      password: "thisisapassword"
    })

    Repo.insert! %WorkshopAttendance{user_id: workshop_attendee.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_stats_path(conn, :stats))

    assert json_response(conn, 200)["data"] == %{
      "users" => %{
        "participants" => 4,
        "total" => 5
      },
      "teams" => %{
        "total" => 2,
        "applied" => 1
      },
      "workshops" => [
        %{
          "name" => workshop.name,
          "slug" => workshop.slug,
          "participants" => 1,
          "participant_limit" => 1
        }
      ]
    }
  end
end