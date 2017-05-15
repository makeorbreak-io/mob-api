defmodule Api.TeamController do
  use Api.Web, :controller
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.SessionController] when action in [:create, :update, :delete]

  alias Api.Project
  alias Guardian.Plug

  def index(conn, _params) do
    projects = Repo.all(Project)
    render(conn, Api.TeamView, "index.json", teams: projects)
  end

  def create(conn, %{"team" => team_params}) do
    user = Plug.current_resource(conn)

    changeset = Project.changeset(%Project{}, Map.merge(team_params, %{
      "user_id" => user.id
    }))

    case Repo.insert(changeset) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", team_path(conn, :show, project))
        |> render(Api.TeamView, "show.json", team: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)
    render(conn, Api.TeamView, "show.json", team: project)
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, team_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        render(conn, Api.TeamView, "show.json", team: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(project)

    send_resp(conn, :no_content, "")
  end
end
