defmodule Api.WorkshopController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, SessionActions, WorkshopActions}

  plug Guardian.Plug.EnsureAuthenticated, [handler: Errors] when action in [:join, :leave]

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end

  def join(conn, %{"id" => id}) do
    case WorkshopActions.join(SessionActions.current_user(conn), id) do
      {:ok, _} -> send_resp(conn, :created, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def leave(conn, %{"id" => id}) do
    case WorkshopActions.leave(SessionActions.current_user(conn), id) do
      {:ok} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end
end
