defmodule Api.ProjectControllerTest do
  use Api.ConnCase

  alias Api.Project
  alias Ecto.DateTime
  
  @valid_attrs %{
    description: "some content",
    name: "some content",
    technologies: "some content",
    team_name: "awesome team"
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
    create_team

    for _ <- 1..2 do
      %Project{}
      |> Project.changeset(%{applied_at: DateTime.utc, team_name: "awesome team"})
      |> Repo.insert!
    end

    conn = get conn, project_path(conn, :index)
    projects = json_response(conn, 200)["data"]

    assert length(projects) == 2
  end

  test "shows chosen resource", %{conn: conn} do
    project =       %Project{}
      |> Project.changeset(%{applied_at: DateTime.utc, team_name: "awesome team"})
      |> Repo.insert!

    conn = get conn, project_path(conn, :show, project)
    assert json_response(conn, 200)["data"] == %{
      "id" => project.id,
      "name" => project.name,
      "description" => project.description,
      "technologies" => project.technologies,
      "applied_at" => DateTime.to_iso8601(project.applied_at),
      "completed_at" => project.completed_at,
      "repo" => project.repo,
      "server" => project.server,
      "student_team" => project.student_team
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, project_path(conn, :show, "30e2751a-3d6c-4424-811b-ab1e1f8f0e31")
    end
  end

  test "creates resource when data is valid", %{conn: conn, jwt: jwt} do
    team = create_team

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(project_path(conn, :create), id: team.id, project: @valid_attrs)

    project = json_response(conn, 201)["data"]
    
    assert project
    assert project["applied_at"]
  end

  test "updates resource when data is valid", %{conn: conn, jwt: jwt} do
    project = Repo.insert! %Project{}
    conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(project_path(conn, :update, project), project: @valid_attrs)

    assert Repo.get_by(Project, @valid_attrs)
  end

  test "doesn't update resource when data is invalid", %{conn: conn, jwt: jwt} do
    project = Repo.insert! %Project{}
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(project_path(conn, :update, project), project: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes resource", %{conn: conn, jwt: jwt} do
    project = %Project{}
    |> Project.changeset(%{applied_at: nil, team_name: "awesome team"})
    |> Repo.insert!

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(project_path(conn, :delete, project))

    assert response(conn, 204)
  end
end
