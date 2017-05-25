defmodule Api.InviteController do
  use Api.Web, :controller

  alias Api.InviteActions

  plug :scrub_params, "invite" when action in [:create]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.SessionController] when action in [:create, :accept, :delete]

  def index(conn, _params) do
    render(conn, "index.json", invites: InviteActions.all)
  end

  def create(conn, %{"invite" => invite_params}) do
    case InviteActions.create(conn, invite_params) do
      {:ok, invite} ->
        invite = Repo.preload(invite, [:host, :team, :invitee])

        conn
        |> put_status(:created)
        |> put_resp_header("location", invite_path(conn, :show, invite))
        |> render("show.json", invite: invite)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", invite: InviteActions.get(id))
  end

  def update(conn, %{"id" => id, "invite" => invite_params}) do
    case InviteActions.change(id, invite_params) do
      {:ok, invite} ->
        invite = Repo.preload(invite, [:host, :team, :invitee])
        render(conn, "show.json", invite: invite)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def accept(conn, %{"id" => id}) do
    case InviteActions.accept(id) do
      {:ok, invite} ->
        invite = Repo.preload(invite, [:host, :team, :invitee])
        render(conn, "show.json", invite: invite)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    InviteActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end