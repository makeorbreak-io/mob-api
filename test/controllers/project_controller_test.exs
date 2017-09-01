defmodule Api.ProjectControllerTest do
  use Api.ConnCase

  alias Api.Project

  @valid_attrs %{
    description: "some content",
    name: "some content",
    technologies: ["elixir", "ruby"]
  }
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
    conn = get conn, project_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    project = Repo.insert! %Project{}
    conn = get conn, project_path(conn, :show, project)

    assert json_response(conn, 200)["data"] == %{
      "id" => project.id,
      "name" => project.name,
      "description" => project.description,
      "technologies" => project.technologies,
      "completed_at" => project.completed_at,
      "repo" => project.repo,
      "server" => project.server
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, project_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates resource when data and request valid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(project_path(conn, :create), project: @valid_attrs)

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "doesn't create resource when request is invalid", %{conn: conn} do
    conn = post(conn, project_path(conn, :create), project: @valid_attrs)

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "doesn't create resource when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(project_path(conn, :create), project: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates resource when data and request are valid", %{conn: conn, jwt: jwt} do
    project = Repo.insert! %Project{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(project_path(conn, :update, project), project: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "doesn't update resource when request is invalid", %{conn: conn} do
    project = Repo.insert! %Project{}

    conn = put(conn, project_path(conn, :update, project), project: @valid_attrs)

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "doesn't update resource when data is invalid", %{conn: conn, jwt: jwt} do
    project = Repo.insert! %Project{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(project_path(conn, :update, project), project: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn, jwt: jwt} do
    project = Repo.insert! %Project{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(project_path(conn, :delete, project))

    assert response(conn, 204)
    refute Repo.get(Project, project.id)
  end
end
