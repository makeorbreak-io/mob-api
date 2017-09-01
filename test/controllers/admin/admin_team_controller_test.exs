defmodule Api.Admin.TeamControllerTest do
  use Api.ConnCase

  alias Api.{Team, TeamMember}

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    admin = create_admin()
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Guardian.Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "lists all teams on index", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_team_path(conn, :index))
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen team", %{conn: conn, admin: admin, jwt: jwt} do
    team = create_team(admin)
    |> Repo.preload([:members, :project, :invites])

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_team_path(conn, :show, team))

    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "name" => team.name,
      "applied" => team.applied,
      "prize_preference" => team.prize_preference,
      "members" => [%{
        "id" => admin.id,
        "role" => "owner",
        "display_name" => "#{admin.first_name} #{admin.last_name}",
        "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19"
      }],
      "invites" => team.invites,
      "project" => team.project
    }
  end

  test "updates team when data and request are valid", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner, %{name: "regular team"})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Team, @valid_attrs)
  end

  test "doesn't update team when request is invalid", %{conn: conn, admin: admin} do
    team = create_team(admin)

    conn = conn
    |> put(admin_team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "doesn't update team when data is invalid", %{conn: conn, jwt: jwt, admin: admin} do
    team = create_team(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_team_path(conn, :update, team), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "delete team works", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_team_path(conn, :delete, team))

    assert response(conn, 204)
    refute Repo.get(Team, team.id)
  end

  test "remove membership works", %{conn: conn, jwt: jwt, admin: admin} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %TeamMember{user_id: admin.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_team_path(conn, :remove, team, admin.id))

    assert response(conn, 204)
  end

  test "can't remove membership if user isn't in the DB", %{conn: conn, jwt: jwt, admin: admin} do
    team = create_team(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_team_path(conn, :remove, team, Ecto.UUID.generate()))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "User not found"
  end

  test "can't remove membership if request isn't valid", %{conn: conn} do
    owner = create_user(%{email: "host@example.com", password: "thisisapassword"})
    member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %TeamMember{user_id: member.id, team_id: team.id}

    conn = conn
    |> delete(admin_team_path(conn, :remove, team, member.id))

    assert response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "can't remove membership if user isn't in the team", %{conn: conn, jwt: jwt, admin: admin} do
    random_user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_team_path(conn, :remove, team, random_user.id))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "User isn't a member of team"
  end
end
