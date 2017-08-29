defmodule Api.ErrorController do
  use Api.Web, :controller

  alias Api.{ChangesetView, ErrorView}

  def changeset_error(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ChangesetView, "error.json", changeset: changeset)
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> render(ErrorView, "error.json", error: "Authentication required")
  end

  def unauthorized(conn, _params) do
    conn
    |> put_status(401)
    |> render(ErrorView, "error.json", error: "Unauthorized")
  end

  def handle_error(conn, code, message) do
    conn
    |> put_status(code)
    |> render(Api.ErrorView, "error.json", error: message)
  end
end
