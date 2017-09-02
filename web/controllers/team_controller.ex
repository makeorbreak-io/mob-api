defmodule Api.TeamController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, SessionActions, TeamActions}

  plug :scrub_params, "team" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Errors] when action in [:create, :update, :delete, :remove]

  def index(conn, _params) do
    render(conn, "index.json", teams: TeamActions.all)
  end

  def create(conn, %{"team" => team_params}) do
    case TeamActions.create(SessionActions.current_user(conn), team_params) do
      {:ok, team} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", team_path(conn, :show, team))
        |> render("show.json", team: team)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: TeamActions.get(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    case TeamActions.update(SessionActions.current_user(conn), id, team_params) do
      {:ok, team} ->
        render(conn, "show.json", team: team)
      {:error, changeset} -> Errors.changeset(conn, changeset)
      {:unauthorized} -> Errors.unauthorized(conn, nil)
    end
  end

  def delete(conn, %{"id" => id}) do
    case TeamActions.delete(SessionActions.current_user(conn), id) do
      {:unauthorized} -> Errors.unauthorized(conn, nil)
      _ -> send_resp(conn, :no_content, "")
    end
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    case TeamActions.remove(SessionActions.current_user(conn), id, user_id) do
      {:ok} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
      {:unauthorized} -> Errors.unauthorized(conn, nil)
    end
  end
end
