defmodule ApiWeb.Admin.WorkshopController do
  use Api.Web, :controller

  alias Api.Workshops
  alias ApiWeb.ErrorController
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  action_fallback ErrorController

  plug :scrub_params, "workshop" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", workshops: Workshops.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: Workshops.get(id))
  end

  def create(conn, %{"workshop" => workshop_params}) do
    with {:ok, workshop} <- Workshops.create(workshop_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", workshop_path(conn, :show, workshop))
      |> render("show.json", workshop: workshop)
    end
  end

  def update(conn, %{"id" => id, "workshop" => workshop_params}) do
    with {:ok, workshop} <- Workshops.update(id, workshop_params),
      do: render(conn, "show.json", workshop: workshop)
  end

  def delete(conn, %{"id" => id}) do
    Workshops.delete(id)
    send_resp(conn, :no_content, "")
  end

  def checkin(conn, %{"id" => id, "user_id" => user_id}) do
    with {:ok, workshop} <- Workshops.toggle_checkin(id, user_id, true),
      do: render(conn, "show.json", workshop: workshop)
  end

  def remove_checkin(conn, %{"id" => id, "user_id" => user_id}) do
    with {:ok, workshop} <- Workshops.toggle_checkin(id, user_id, false),
      do: render(conn, "show.json", workshop: workshop)
  end
end
