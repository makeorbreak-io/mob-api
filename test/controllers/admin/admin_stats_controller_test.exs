defmodule Api.AdminStatsControllerTest do
  use Api.ConnCase

  alias Api.{User}

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

  test "users and teams statistics are correct", %{conn: conn, admin: admin, jwt: jwt} do
    Repo.insert!(%User{})
    Repo.insert!(%User{})
    create_team(%{user_id: admin.id, name: "awesome team"})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_stats_path(conn, :stats))

    assert json_response(conn, 200)["data"] == %{
      "users" => %{
        "total" => 3,
        "participants" => 2,
      },
      "teams" => %{
        "total" => 1
      }
    }
  end
end