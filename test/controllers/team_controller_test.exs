defmodule Api.TeamControllerTest do
  use Api.ConnCase

  alias Api.Project
  
  @valid_attrs %{team_name: "awesome team"}
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
    team = Repo.insert! %Project{team_name: "awesome team"}
    conn = get conn, team_path(conn, :show, team)
    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "team_name" => team.team_name
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, team_path(conn, :show, "30e2751a-3d6c-4424-811b-ab1e1f8f0e31")
    end
  end

  test "creates resource when data is valid", %{conn: conn, jwt: jwt, user: user} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @valid_attrs)

    id = json_response(conn, 201)["data"]["id"]
    team = Repo.get(Project, id)
    
    assert team
    assert team.user_id == user.id
  end

  test "doesn't create resource when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates resource when data is valid", %{conn: conn, jwt: jwt} do
    team = Repo.insert! %Project{}
    conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert Repo.get_by(Project, @valid_attrs)
  end

  test "doesn't update resource when data is invalid", %{conn: conn, jwt: jwt} do
    team = Repo.insert! %Project{}
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes resource", %{conn: conn, jwt: jwt} do
    team = Repo.insert! %Project{}
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))

    assert response(conn, 204)
    refute Repo.get(Project, team.id)
  end
end
