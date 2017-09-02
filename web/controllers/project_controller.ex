defmodule Api.ProjectController do

  use Api.Web, :controller

  alias Api.{Controller.Errors, ProjectActions}

  plug :scrub_params, "project" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Errors] when action in [:create, :update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", projects: ProjectActions.all)
  end

  def create(conn, %{"project" => project_params}) do
    case ProjectActions.create(project_params) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_path(conn, :show, project))
        |> render("show.json", project: project)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", project: ProjectActions.get(id))
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    case ProjectActions.update(id, project_params) do
      {:ok, project} -> render(conn, "show.json", project: project)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ProjectActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end
