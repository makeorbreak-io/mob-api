defmodule Api.Admin.TeamController do
  use Api.Web, :controller

  alias Api.{TeamActions, Controller.Errors}
  alias Guardian.{Plug, Plug.EnsureAuthenticated, Plug.EnsurePermissions}

  plug :scrub_params, "team" when action in [:update]
  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", teams: TeamActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", team: TeamActions.get(id))
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    case TeamActions.update_any(id, team_params) do
      {:ok, team} -> render(conn, "show.json", team: team)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    TeamActions.delete_any(id)
    send_resp(conn, :no_content, "")
  end

  def remove(conn, %{"id" => id, "user_id" => user_id}) do
    case TeamActions.remove_any(id, user_id) do
      {:ok} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def disqualify(conn, %{"id" => id}) do
    TeamActions.disqualify(id, Plug.current_resource(conn))
    send_resp(conn, :no_content, "")
  end

  def create_repo(conn, %{"id" => id}) do
    case TeamActions.create_repo(id) do
      :ok -> send_resp(conn, :created, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def add_users_to_repo(conn, %{"id" => id}) do
    case TeamActions.add_users_to_repo(id) do
      :ok -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end
end
