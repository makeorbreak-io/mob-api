defmodule Api.ProjectController do
  use Api.Web, :controller
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.SessionController] when action in [:create, :update, :delete]

  alias Api.{Project, ChangesetView, ErrorView}

  def index(conn, _params) do
    projects = Repo.all(from p in Project, where: not is_nil(p.applied_at))
    render(conn, "index.json", projects: projects)
  end

  def create(conn, %{"id" => id, "project" => project_params}) do
    project = Repo.get!(Project, id)

    changeset = Project.changeset(project, Map.merge(project_params, %{
      "applied_at" => Ecto.DateTime.utc
    }))

    case Repo.update(changeset) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_path(conn, :show, project))
        |> render("show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    query = from p in Project, where: not is_nil(p.applied_at)
    project = Repo.get!(query, id)
    render(conn, "show.json", project: project)
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        render(conn, "show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)

    changeset = Project.changeset(project, %{applied_at: nil, completed_at: nil})

    case Repo.update(changeset) do
      {:ok, project} ->
        send_resp(conn, :no_content, "")
      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", error: "Unable to delete project")
    end
  end
end
