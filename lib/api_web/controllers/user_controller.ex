defmodule ApiWeb.UserController do
  use Api.Web, :controller

  alias ApiWeb.{ErrorController, SessionActions, SessionView, UserActions}

  action_fallback ErrorController

  plug :scrub_params, "user" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController]
    when action in [:update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, jwt, user} <- UserActions.create(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render(SessionView, "show.json", data: %{jwt: jwt, user: user})
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = SessionActions.current_user(conn)

    with {:ok, user} <- UserActions.update(user, id, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = SessionActions.current_user(conn)

    with {_} <- UserActions.delete(user, id),
      do: send_resp(conn, :no_content, "")
  end

  def get_token(conn, %{"email" => email}) do
    with {:ok, _} <- UserActions.get_token(email),
      do: send_resp(conn, :no_content, "")
  end

  def recover_password(conn, %{"token" => t, "password" => p}) do
    with {:ok, _} <- UserActions.recover_password(t, p),
      do: send_resp(conn, :no_content, "")
  end
end
