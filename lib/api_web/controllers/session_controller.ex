defmodule ApiWeb.SessionController do
  use Api.Web, :controller

  alias Api.Accounts
  alias ApiWeb.{SessionView, ErrorController}

  action_fallback ErrorController

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController] when action in [:me]

  def me(conn, _params) do
    render(conn, SessionView, "me.json", user: Accounts.current_user(conn))
  end

  def create(conn, %{"email" => email, "password" => password}) do
    with {:ok, jwt, user} <- Accounts.create_session(email, password) do
      conn
      |> put_status(:created)
      |> render(SessionView, "show.json", data: %{jwt: jwt, user: user})
    end
  end

  def delete(conn, _) do
    Accounts.delete_session(conn)
    |> render(SessionView, "show.json", data: %{})
  end
end
