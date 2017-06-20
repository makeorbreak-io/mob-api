defmodule Api.TeamControllerTest do
  use Api.ConnCase

  alias Api.{Team, TeamMember}

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = create_user
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)

    {:ok, %{
      user: user,
      jwt: jwt,
      claims: full_claims,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, team_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen team", %{conn: conn} do
    team = Repo.insert! %Team{}
    |> Repo.preload([:members, :project, :owner, :invites])
  
    conn = get conn, team_path(conn, :show, team)
    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "name" => team.name,
      "members" => team.members,
      "invites" => team.invites,
      "owner" => team.owner,
      "project" => team.project
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, team_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates team when data and request are valid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @valid_attrs)

    id = json_response(conn, 201)["data"]["id"]

    assert id
    assert Repo.get(Team, id)
  end

  test "doesn't create team when request is invalid", %{conn: conn} do
    conn = post(conn, team_path(conn, :create), team: @valid_attrs)

    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "doesn't create team when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates team when data and request are valid", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Team, @valid_attrs)
  end

  test "doesn't update team when request is invalid", %{conn: conn, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)
    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "doesn't update team when data is invalid", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "doesn't update team if user isn't its owner", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: owner.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end

  test "deletes team if user is its owner", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))
    
    assert response(conn, 204)
    refute Repo.get(Team, team.id)
  end

  test "doesn't delete team if user isn't it's owner", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: owner.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))
    
    assert json_response(conn, 401)
    assert Repo.get(Team, team.id)
  end

  test "remove membership works if triggered by team owner", %{conn: conn, jwt: jwt, user: user} do
    team_member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: user.id}
    Repo.insert! %TeamMember{user_id: team_member.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, team_member.id))
    
    assert response(conn, 204)
  end

  test "remove membership works if triggered by own member", %{conn: conn, jwt: jwt, user: user} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: owner.id}
    Repo.insert! %TeamMember{user_id: user.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, user.id))
    
    assert response(conn, 204)
  end

  test "remove membership doesn't work if user isn't owner of team", %{conn: conn, jwt: jwt} do
    team_member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: team_member.id}
    Repo.insert! %TeamMember{user_id: team_member.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, team_member.id))
    
    assert response(conn, 401)
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end

  test "remove membership doesn't work if user isn't in the DB", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}
    
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, Ecto.UUID.generate()))
    
    assert response(conn, 401)
    assert json_response(conn, 401)["error"] == "User not found"
  end

  test "remove membership doesn't work if request isn't valid", %{conn: conn, user: user} do
    team_member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: user.id}
    Repo.insert! %TeamMember{user_id: team_member.id, team_id: team.id}

    conn = conn
    |> delete(team_path(conn, :remove, team, team_member.id))
    
    assert response(conn, 401)
    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "remove membership doesn't work if user isn't in the Team", %{conn: conn, jwt: jwt, user: user} do
    random_user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: user.id}
    
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, random_user.id))
    
    assert response(conn, 401)
    assert json_response(conn, 401)["error"] == "User isn't a member of team"
  end
end