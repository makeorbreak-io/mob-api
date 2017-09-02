defmodule Api.AdminStatsControllerTest do
  use Api.ConnCase

  alias Api.{Project, WorkshopAttendance}
  alias Guardian.Permissions

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

  test "correct statistics are given", %{conn: conn, admin: admin, jwt: jwt} do
    create_user()
    create_user()
    team_owner = create_user()
    create_team(admin)
    create_team(team_owner, %{applied: true, name: "awesome team"})
    workshop = create_workshop()
    workshop_attendee = create_user(%{
      email: "example@email.com",
      first_name: "Jane",
      last_name: "doe",
      password: "thisisapassword"
    })
    Repo.insert! %Project{}

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
      ],
      "projects" => %{
        "total" => 1
      }
    }
  end
end
