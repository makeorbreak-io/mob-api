defmodule ApiWeb.AdminStatsControllerTest do
  use ApiWeb.ConnCase

  alias Api.Workshops.Attendance
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

  # test "correct statistics are given", %{conn: conn, admin: admin, jwt: jwt} do
  #   create_user()
  #   create_user()
  #   team_owner = create_user()
  #   competition = create_competition()
  #   create_team(admin, competition)
  #   create_team(team_owner, competition, %{applied: true, name: "awesome team"})
  #   workshop = create_workshop()
  #   workshop_attendee = create_user(%{
  #     email: "example@email.com",
  #     first_name: "Jane doe",
  #     password: "thisisapassword"
  #   })

  #   Repo.insert! %Attendance{user_id: workshop_attendee.id, workshop_id: workshop.id}

  #   conn = conn
  #   |> put_req_header("authorization", "Bearer #{jwt}")
  #   |> get(admin_stats_path(conn, :stats))

  #   assert json_response(conn, 200)["data"] == %{
  #     "users" => %{
  #       "hackathon" => 1,
  #       "checked_in" => 0,
  #       "total" => 5
  #     },
  #     "roles" => [
  #       %{"role" => "admin", "total" => 1},
  #       %{"role" => "participant", "total" => 4},
  #     ],
  #     "teams" => %{
  #       "total" => 2,
  #       "applied" => 1
  #     },
  #     "workshops" => [
  #       %{
  #         "name" => workshop.name,
  #         "slug" => workshop.slug,
  #         "participants" => 1,
  #         "participant_limit" => 1
  #       }
  #     ]
  #   }
  # end
end
