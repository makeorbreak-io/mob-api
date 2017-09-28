defmodule ApiWeb.Admin.TeamController do
  use Api.Web, :controller

  alias Api.Competitions
  alias Api.Competitions.Team
  alias ApiWeb.ErrorController
  alias Guardian.{Plug, Plug.EnsureAuthenticated, Plug.EnsurePermissions}

  action_fallback ErrorController

  plug :scrub_params, "team" when action in [:update]
  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", teams: Competitions.list_teams)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: Competitions.get_team(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    with {:ok, t} <- Competitions.update_any_team(id, team_params),
      do: render(conn, "show.json", team: t)
  end

  def delete(conn, %{"id" => id}) do
    Competitions.delete_any_team(id)
    send_resp(conn, :no_content, "")
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    with {:ok} <- Competitions.remove_any_membership(id, user_id),
      do: send_resp(conn, :no_content, "")
  end

  def disqualify(conn, %{"id" => id}) do
    Competitions.disqualify_team(id, Plug.current_resource(conn))
    render(conn, "show.json", team: Repo.get!(Team, id))
  end

  def create_repo(conn, %{"id" => id}) do
    with :ok <- Competitions.create_repo(id),
      do: send_resp(conn, :created, "")
  end

  def add_users_to_repo(conn, %{"id" => id}) do
    with :ok <- Competitions.add_users_to_repo(id),
      do: send_resp(conn, :no_content, "")
  end
end
