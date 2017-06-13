defmodule Api.TeamControllerTest do
  use Api.ConnCase

  alias Api.Team

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

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

  test "shows chosen resource", %{conn: conn} do
    team = Repo.insert! %Team{}
    |> Repo.preload([:users, :project, :owner, :invites])
  
    conn = get conn, team_path(conn, :show, team)
    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "name" => team.name,
      "members" => team.users,
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

  test "creates resource when data and request are valid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @valid_attrs)

    id = json_response(conn, 201)["data"]["id"]

    assert id
    assert Repo.get(Team, id)
  end

  test "doesn't create resource when request is invalid", %{conn: conn} do
    conn = post(conn, team_path(conn, :create), team: @valid_attrs)

    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "doesn't create resource when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates resource when data and request are valid", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Team, @valid_attrs)
  end

  test "doesn't update resource when request is invalid", %{conn: conn} do
    team = Repo.insert! %Team{}

    conn = put(conn, team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)["errors"] != %{}
  end

  test "doesn't update resource when data is invalid", %{conn: conn, jwt: jwt} do
    team = Repo.insert! %Team{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource if user is it's owner", %{conn: conn, jwt: jwt, user: user} do
    team = Repo.insert! %Team{user_id: user.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))
    
    assert response(conn, 204)
    refute Repo.get(Team, team.id)
  end

  test "doesn't delete resource if user isn't it's owner", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: owner.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))
    
    assert response(conn, 401)
    assert Repo.get(Team, team.id)
  end
end