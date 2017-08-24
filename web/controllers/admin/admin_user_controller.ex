defmodule Api.Admin.UserController do
  use Api.Web, :controller

  alias Api.{UserActions, SessionController, ChangesetView}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "user" when action in [:update]
  plug EnsureAuthenticated, [handler: SessionController]
  plug EnsurePermissions, [handler: SessionController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserActions.update(conn, id, user_params) do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case UserActions.delete_any(id) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end
end
