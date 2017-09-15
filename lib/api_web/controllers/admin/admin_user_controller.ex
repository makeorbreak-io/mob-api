defmodule ApiWeb.Admin.UserController do
  use Api.Web, :controller

  alias ApiWeb.{Controller.Errors, SessionActions, UserActions}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "user" when action in [:update]
  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserActions.update(SessionActions.current_user(conn), id, user_params) do
      {:ok, user} -> render(conn, "show.json", user: user)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    UserActions.delete_any(id)
    send_resp(conn, :no_content, "")
  end

  def checkin(conn, %{"id" => id}) do
    case UserActions.toggle_checkin(id, true) do
      {:ok, user} -> render(conn, "show.json", user: user)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def remove_checkin(conn, %{"id" => id}) do
    case UserActions.toggle_checkin(id, false) do
      {:ok, user} -> render(conn, "show.json", user: user)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end
end
