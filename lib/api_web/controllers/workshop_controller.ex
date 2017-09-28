defmodule ApiWeb.WorkshopController do
  use Api.Web, :controller

  alias Api.Accounts
  alias Api.Workshops
  alias ApiWeb.ErrorController
  alias Guardian.Plug.EnsureAuthenticated

  action_fallback ErrorController

  plug EnsureAuthenticated, [handler: ErrorController] when action in [:join, :leave]

  def index(conn, _params) do
    render(conn, "index.json", workshops: Workshops.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: Workshops.get(id))
  end

  def join(conn, %{"id" => id}) do
    user = Accounts.current_user(conn)

    with {:ok, _} <- Workshops.join(user, id), do: send_resp(conn, :created, "")
  end

  def leave(conn, %{"id" => id}) do
    user = Accounts.current_user(conn)

    with {:ok} <- Workshops.leave(user, id), do: send_resp(conn, :no_content, "")
  end
end
