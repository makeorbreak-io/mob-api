defmodule Api.Admin.StatsController do
  use Api.Web, :controller

  alias Api.{StatsActions, SessionController}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: SessionController]
  plug EnsurePermissions, [handler: SessionController, admin: ~w(full)]

  def stats(conn, _params) do
    render(conn, "users_teams.json", stats: StatsActions.users_and_teams)
  end
end
