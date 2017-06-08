defmodule Api.TeamController do
  
  use Api.Web, :controller

  alias Api.TeamActions

  plug :scrub_params, "team" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.SessionController] when action in [:create, :update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", teams: TeamActions.all)
  end

  def create(conn, %{"team" => team_params}) do
    case TeamActions.create(conn, team_params) do
      {:ok, team} ->
        team = Repo.preload(team, [:owner, :users, :project, :invites])

        conn
        |> put_status(:created)
        |> put_resp_header("location", team_path(conn, :show, team))
        |> render("show.json", team: team)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: TeamActions.get(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    case TeamActions.update(id, team_params) do
      {:ok, team} ->
        team = Repo.preload(team, [:owner, :users, :project, :invites])
        render(conn, "show.json", team: team)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    TeamActions.delete(conn, id)
    send_resp(conn, :no_content, "")
  end
end
