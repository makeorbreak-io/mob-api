defmodule ApiWeb.TeamController do
  use Api.Web, :controller

  alias ApiWeb.{SessionActions, TeamActions, ErrorController}

  action_fallback ErrorController

  plug :scrub_params, "team" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: ErrorController] when action in [:create, :update, :delete, :remove]

  def index(conn, _params) do
    render(conn, "index.json", teams: TeamActions.all)
  end

  def create(conn, %{"team" => team_params}) do
    user = SessionActions.current_user(conn)

    with {:ok, team} <- TeamActions.create(user, team_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", team_path(conn, :show, team))
      |> render("show.json", team: team)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: TeamActions.get(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    user = SessionActions.current_user(conn)

    with {:ok, team} <- TeamActions.update(user, id, team_params) do
      render(conn, "show.json", team: team)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = SessionActions.current_user(conn)

    with {_} <- TeamActions.delete(user, id) do
      send_resp(conn, :no_content, "")
    end
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    user = SessionActions.current_user(conn)

    with :ok <- TeamActions.remove(user, id, user_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
