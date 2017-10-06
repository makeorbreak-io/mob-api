defmodule ApiWeb.TeamController do
  use Api.Web, :controller

  alias Api.Accounts
  alias Api.Teams
  alias ApiWeb.ErrorController
  alias Guardian.Plug.EnsureAuthenticated

  action_fallback ErrorController

  plug :scrub_params, "team" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: ErrorController]
    when action in [:create, :update, :delete, :remove]

  def index(conn, _params) do
    render(conn, "index.json", teams: Teams.list_teams)
  end

  def create(conn, %{"team" => team_params}) do
    user = Accounts.current_user(conn)

    with {:ok, team} <- Teams.create_team(user, team_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", team_path(conn, :show, team))
      |> render("show.json", team: team)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: Teams.get_team(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    user = Accounts.current_user(conn)

    with {:ok, team} <- Teams.update_team(user, id, team_params) do
      render(conn, "show.json", team: team)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.current_user(conn)

    with {_} <- Teams.delete_team(user, id) do
      send_resp(conn, :no_content, "")
    end
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    user = Accounts.current_user(conn)

    with :ok <- Teams.remove_membership(user, id, user_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
