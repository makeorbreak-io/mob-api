defmodule ApiWeb.SessionController do
  use Api.Web, :controller

  alias ApiWeb.{SessionActions, SessionView, ErrorController}

  action_fallback ErrorController

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController] when action in [:me]

  def me(conn, _params) do
    render(conn, SessionView, "me.json", user: SessionActions.current_user(conn))
  end

  def create(conn, %{"email" => email, "password" => password}) do
    with {:ok, jwt, user} <- SessionActions.create(email, password) do
      conn
      |> put_status(:created)
      |> render(SessionView, "show.json", data: %{jwt: jwt, user: user})
    end
  end

  def delete(conn, _) do
    SessionActions.delete(conn)
    |> render(SessionView, "show.json", data: %{})
  end
end