defmodule Api.Admin.UserController do
  use Api.Web, :controller

  alias Api.{UserActions, SessionController}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "user" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: SessionController]
  plug EnsurePermissions, [handler: SessionController, admin: ~w(full)]  when action in [:index]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end
end
