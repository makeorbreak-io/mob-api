defmodule ApiWeb.InviteController do
  use Api.Web, :controller

  alias Api.Accounts
  alias Api.Teams
  alias ApiWeb.ErrorController
  alias Guardian.Plug.EnsureAuthenticated

  action_fallback ErrorController

  plug :scrub_params, "invite" when action in [:create]
  plug EnsureAuthenticated, [handler: ErrorController]
    when action in [:index, :create, :accept, :delete]

  def index(conn, _params) do
    user = Accounts.current_user(conn)

    render(conn, "index.json", invites: Teams.current_user_invites(user))
  end

  def create(conn, %{"invite" => invite_params}) do
    user = Accounts.current_user(conn)

    with {:ok, invite} <- Teams.create_invite(user, invite_params) do
      invite = Repo.preload(invite, [:host, :team, :invitee])

      conn
      |> put_status(:created)
      |> put_resp_header("location", invite_path(conn, :show, invite))
      |> render("show.json", invite: invite)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", invite: Teams.get_invite(id))
  end

  def accept(conn, %{"id" => id}) do
    with {:ok, _} <- Teams.accept_invite(id) do
      send_resp(conn, :no_content, "")
    end
  end

  def delete(conn, %{"id" => id}) do
    Teams.delete_invite(id)
    send_resp(conn, :no_content, "")
  end

  def invite_to_slack(conn, %{"email" => email}) do
    with {:ok, _} <- Teams.invite_to_slack(email) do
      send_resp(conn, :created, "")
    end
  end
end
