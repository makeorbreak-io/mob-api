defmodule Api.UserController do
  use Api.Web, :controller

  alias Api.{UserActions, SessionView, ErrorController}

  plug :scrub_params, "user" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.ErrorController] when action in [:update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def create(conn, %{"user" => user_params}) do
    case UserActions.create(user_params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, user))
        |> render(SessionView, "session.json", data: %{jwt: jwt, user: user})
      {:error, changeset} -> ErrorController.changeset_error(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserActions.update(conn, id, user_params) do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} -> ErrorController.changeset_error(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case UserActions.delete(conn, id) do
      {:unauthorized} -> ErrorController.unauthorized(conn, nil)
      _ -> send_resp(conn, :no_content, "")
    end
  end
end
