defmodule ApiWeb.Admin.UserController do
  use Api.Web, :controller

  alias Api.Accounts
  alias ApiWeb.ErrorController
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  action_fallback ErrorController

  plug :scrub_params, "user" when action in [:update]
  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", users: Accounts.list_users)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: Accounts.get_user(id))
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.current_user(conn)

    with {:ok, user} <- Accounts.update_user(user, id, user_params),
      do: render(conn, "show.json", user: user)
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_any_user(id)
    send_resp(conn, :no_content, "")
  end

  def checkin(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.toggle_checkin(id, true),
      do: render(conn, "show.json", user: user)
  end

  def remove_checkin(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.toggle_checkin(id, false),
      do: render(conn, "show.json", user: user)
  end
end
