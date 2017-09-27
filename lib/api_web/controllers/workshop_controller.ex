defmodule ApiWeb.WorkshopController do
  use Api.Web, :controller

  alias ApiWeb.{ErrorController, SessionActions, WorkshopActions}

  action_fallback ErrorController

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController] when action in [:join, :leave]

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end

  def join(conn, %{"id" => id}) do
    user = SessionActions.current_user(conn)

    with {:ok, _} <- WorkshopActions.join(user, id), do: send_resp(conn, :created, "")
  end

  def leave(conn, %{"id" => id}) do
    user = SessionActions.current_user(conn)

    with {:ok} <- WorkshopActions.leave(user, id), do: send_resp(conn, :no_content, "")
  end
end
