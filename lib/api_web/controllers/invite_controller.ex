defmodule ApiWeb.InviteController do
  use Api.Web, :controller

  alias Api.Teams

  def invite_to_slack(conn, %{"email" => email}) do
    with {:ok, _} <- Teams.invite_to_slack(email) do
      send_resp(conn, :created, "")
    end
  end
end
