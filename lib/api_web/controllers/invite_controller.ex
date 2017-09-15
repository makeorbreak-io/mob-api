defmodule ApiWeb.InviteController do
  use Api.Web, :controller

  alias ApiWeb.{Controller.Errors, InviteActions, SessionActions}

  plug :scrub_params, "invite" when action in [:create]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Errors] when action in [:index, :create, :accept, :delete]

  def index(conn, _params) do
    render(conn, "index.json",
      invites: InviteActions.for_current_user(SessionActions.current_user(conn)))
  end

  def create(conn, %{"invite" => invite_params}) do
    case InviteActions.create(SessionActions.current_user(conn), invite_params) do
      {:ok, invite} ->
        invite = Repo.preload(invite, [:host, :team, :invitee])

        conn
        |> put_status(:created)
        |> put_resp_header("location", invite_path(conn, :show, invite))
        |> render("show.json", invite: invite)
      {:error, changeset} -> Errors.changeset(conn, changeset)
      error_code -> Errors.build(conn, :unprocessable_entity, error_code)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", invite: InviteActions.get(id))
  end

  def accept(conn, %{"id" => id}) do
    case InviteActions.accept(id) do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def delete(conn, %{"id" => id}) do
    InviteActions.delete(id)
    send_resp(conn, :no_content, "")
  end

  def invite_to_slack(conn, %{"email" => email}) do
    case InviteActions.invite_to_slack(email) do
      {:ok, _} -> send_resp(conn, :created, "")
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end
end
