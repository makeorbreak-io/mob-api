defmodule Api.Admin.CompetitionController do
  use Api.Web, :controller

  alias Api.{CompetitionActions, Controller.Errors}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def start_voting(conn, _) do
    case CompetitionActions.start_voting do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def end_voting(conn, _) do
    case CompetitionActions.end_voting do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end
end
