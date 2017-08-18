defmodule Api.Admin.WorkshopController do
  use Api.Web, :controller

  alias Api.{WorkshopActions, SessionController, ChangesetView}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "workshop" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: SessionController]
  plug EnsurePermissions, [handler: SessionController, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all("admin"))
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id, "admin"))
  end

  def create(conn, %{"workshop" => workshop_params}) do
    case WorkshopActions.create(workshop_params) do
      {:ok, workshop} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", workshop_path(conn, :show, workshop))
        |> render("show.json", workshop: workshop)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "workshop" => workshop_params}) do
    case WorkshopActions.update(id, workshop_params) do
      {:ok, workshop} ->
        render(conn, "show.json", workshop: workshop)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    WorkshopActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end