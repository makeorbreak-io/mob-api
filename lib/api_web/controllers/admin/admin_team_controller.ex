defmodule ApiWeb.Admin.TeamController do
  use Api.Web, :controller

  alias ApiWeb.{TeamActions, ErrorController, Team}
  alias Guardian.{Plug, Plug.EnsureAuthenticated, Plug.EnsurePermissions}

  action_fallback ErrorController

  plug :scrub_params, "team" when action in [:update]
  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", teams: TeamActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: TeamActions.get(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    with {:ok, t} <- TeamActions.update_any(id, team_params),
      do: render(conn, "show.json", team: t)
  end

  def delete(conn, %{"id" => id}) do
    TeamActions.delete_any(id)
    send_resp(conn, :no_content, "")
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    with {:ok} <- TeamActions.remove_any(id, user_id),
      do: send_resp(conn, :no_content, "")
  end

  def disqualify(conn, %{"id" => id}) do
    TeamActions.disqualify(id, Plug.current_resource(conn))
    render(conn, "show.json", team: Repo.get!(Team, id))
  end

  def create_repo(conn, %{"id" => id}) do
    with :ok <- TeamActions.create_repo(id),
      do: send_resp(conn, :created, "")
  end

  def add_users_to_repo(conn, %{"id" => id}) do
    with :ok <- TeamActions.add_users_to_repo(id),
      do: send_resp(conn, :no_content, "")
  end
end
