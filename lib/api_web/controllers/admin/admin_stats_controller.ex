defmodule ApiWeb.Admin.StatsController do
  use Api.Web, :controller

  alias ApiWeb.{StatsActions, ErrorController}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def stats(conn, _params) do
    render(conn, "stats.json", stats: StatsActions.stats)
  end
end
