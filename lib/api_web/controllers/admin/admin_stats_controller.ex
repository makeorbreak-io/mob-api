defmodule ApiWeb.Admin.StatsController do
  use Api.Web, :controller

  alias ApiWeb.{StatsActions, Controller.Errors}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def stats(conn, _params) do
    render(conn, "stats.json", stats: StatsActions.stats)
  end
end
