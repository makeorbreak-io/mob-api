defmodule ApiWeb.Admin.CompetitionController do
  use Api.Web, :controller

  alias ApiWeb.{CompetitionActions, ErrorController}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  action_fallback ErrorController

  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def start_voting(conn, _) do
    with {:ok, _} <- CompetitionActions.start_voting(),
      do: send_resp(conn, :no_content, "")
  end

  def end_voting(conn, _) do
    with {:ok, _} <- CompetitionActions.end_voting(),
      do: send_resp(conn, :no_content, "")
  end

  def status(conn, _) do
    render(conn, "status.json", status: CompetitionActions.status())
  end
end
