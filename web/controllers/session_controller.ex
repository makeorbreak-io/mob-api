defmodule Api.SessionController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, SessionActions, SessionView}

  plug Guardian.Plug.EnsureAuthenticated, [handler: Errors] when action in [:me]

  def me(conn, _params) do
    render(conn, SessionView, "me.json", user: SessionActions.current_user(conn))
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case SessionActions.create(email, password) do
      {:ok, jwt, user} ->
        conn
        |> put_status(:created)
        |> render(SessionView, "show.json", data: %{jwt: jwt, user: user})
      error_code -> Errors.build(conn, :unprocessable_entity, error_code)
    end
  end

  def delete(conn, _) do
    SessionActions.delete(conn)
    |> render(SessionView, "show.json", data: %{})
  end
end
