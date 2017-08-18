defmodule Api.WorkshopController do
  use Api.Web, :controller

  alias Api.{WorkshopActions, ErrorView}

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end

  def join(conn, %{"id" => id}) do
    case WorkshopActions.join(conn, id) do
      {:ok, _} ->
        send_resp(conn, :created, "")
      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ErrorView, "error.json", error: error)
    end
  end

  def leave(conn, %{"id" => id}) do
    case WorkshopActions.leave(conn, id) do
      {:ok} ->
        send_resp(conn, :no_content, "")
      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", error: error)
    end
  end
end