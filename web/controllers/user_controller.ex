defmodule Api.UserController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, SessionActions, SessionView, UserActions}

  plug :scrub_params, "user" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated, [handler: Errors] when action in [:update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def create(conn, %{"user" => user_params}) do
    case UserActions.create(user_params) do
      {:ok, jwt, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, user))
        |> render(SessionView, "show.json", data: %{jwt: jwt, user: user})
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserActions.update(SessionActions.current_user(conn), id, user_params) do
      {:ok, user} -> render(conn, "show.json", user: user)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case UserActions.delete(SessionActions.current_user(conn), id) do
      :unauthorized -> Errors.unauthorized(conn, nil)
      _ -> send_resp(conn, :no_content, "")
    end
  end
end
