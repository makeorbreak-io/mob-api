defmodule Api.Admin.WorkshopController do
  use Api.Web, :controller

  alias Api.{WorkshopActions, Controller.Errors}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "workshop" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end

  def create(conn, %{"workshop" => workshop_params}) do
    case WorkshopActions.create(workshop_params) do
      {:ok, workshop} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", workshop_path(conn, :show, workshop))
        |> render("show.json", workshop: workshop)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "workshop" => workshop_params}) do
    case WorkshopActions.update(id, workshop_params) do
      {:ok, workshop} ->
        render(conn, "show.json", workshop: workshop)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    WorkshopActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end
