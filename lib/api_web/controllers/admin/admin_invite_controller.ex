defmodule ApiWeb.Admin.InviteController do
  use Api.Web, :controller

  alias ApiWeb.{InviteActions, Controller.Errors}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def sync(conn, _params) do
    InviteActions.sync()
    send_resp(conn, :no_content, "")
  end
end
