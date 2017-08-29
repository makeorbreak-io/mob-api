defmodule Api.WorkshopController do
  use Api.Web, :controller

  alias Api.{WorkshopActions, ErrorController}

  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.ErrorController] when action in [:join, :leave]

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end

  def join(conn, %{"id" => id}) do
    case WorkshopActions.join(conn, id) do
      {:ok, _} -> send_resp(conn, :created, "")
      {:error, error} -> ErrorController.handle_error(conn, :unprocessable_entity, error)
    end
  end

  def leave(conn, %{"id" => id}) do
    case WorkshopActions.leave(conn, id) do
      {:ok} -> send_resp(conn, :no_content, "")
      {:error, error} -> ErrorController.handle_error(conn, :unprocessable_entity, error)
    end
  end
end
