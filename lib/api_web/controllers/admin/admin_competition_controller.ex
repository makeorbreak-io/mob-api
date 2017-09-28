defmodule ApiWeb.Admin.CompetitionController do
  use Api.Web, :controller

  alias Api.Competitions
  alias ApiWeb.ErrorController
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  action_fallback ErrorController

  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def start_voting(conn, _) do
    with {:ok, _} <- Competitions.start_voting(),
      do: send_resp(conn, :no_content, "")
  end

  def end_voting(conn, _) do
    with {:ok, _} <- Competitions.end_voting(),
      do: send_resp(conn, :no_content, "")
  end

  def status(conn, _) do
    render(conn, "status.json", status: Competitions.status())
  end
end
