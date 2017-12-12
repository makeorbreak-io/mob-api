defmodule ApiWeb.Admin.TeamControllerTest do
  use ApiWeb.ConnCase

  alias ApiWeb.{Team, TeamMember, CompetitionActions}
  # import Api.StringHelper

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
    |> Repo.preload([:members, :invites])

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_team_path(conn, :show, team))

    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "name" => team.name,
      "applied" => team.applied,
      "prize_preference" => team.prize_preference,
      "eligible" => team.eligible,
      "members" => [%{
        "id" => admin.id,
        "role" => "owner",
        "display_name" => "#{admin.first_name} #{admin.last_name}",
        "gravatar_hash" => UserHelper.gravatar_hash(admin)
      }],
      "invites" => team.invites,
      "disqualified_at" => nil,
      "project_name" => team.project_name,
      "project_desc" => team.project_desc,
      "technologies" => team.technologies
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

  test "doesn't update eligible if voting has started", %{conn: conn, jwt: jwt, admin: admin} do
    team = create_team(admin)
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_team_path(conn, :update, team), team: Map.merge(@valid_attrs, %{"eligible": true}))

    assert json_response(conn, 200)["data"]["eligible"] == false
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

  test "can't remove membership if voting has started", %{conn: conn, jwt: jwt, admin: admin} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %TeamMember{user_id: admin.id, team_id: team.id}
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_team_path(conn, :remove, team, admin.id))

    assert json_response(conn, 422)["errors"] == "Competition already started"
  end

  test "disqualify works", %{conn: conn, jwt: jwt} do
    user = create_user()
    team = create_team(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_team_path(conn, :disqualify, team.id))

    team = Repo.get!(Team, team.id)
    assert json_response(conn, 200)["data"] == %{
      "prize_preference" => nil,
      "name" => team.name,
      "members" => nil,
      "invites" => nil,
      "id" => team.id,
      "eligible" => false,
      "applied" => false,
      "disqualified_at" => DateTime.to_iso8601(team.disqualified_at),
      "project_name" => team.project_name,
      "project_desc" => team.project_desc,
      "technologies" => team.technologies
    }
  end

  # test "create repo works", %{conn: conn, admin: admin, jwt: jwt} do
  #   team = create_team(admin)

  #   conn = conn
  #   |> put_req_header("authorization", "Bearer #{jwt}")
  #   |> post(admin_team_path(conn, :create_repo, team))

  #   assert response(conn, 201)

  #   updated_team = Repo.get(Team, team.id)

  #   assert updated_team.repo["name"] == slugify(team.name)
  # end

  # test "add team members to repo works", %{conn: conn, jwt: jwt} do
  #   user = create_user()
  #   team = create_team(user)

  #   conn = conn
  #   |> put_req_header("authorization", "Bearer #{jwt}")
  #   |> post(admin_team_path(conn, :add_users_to_repo, team))

  #   assert response(conn, 204)
  # end
end