defmodule ApiWeb.InviteView do
  use Api.Web, :view

  alias ApiWeb.{UserView, TeamView}

  def render("index.json", %{invites: invites}) do
    %{data: render_many(invites, __MODULE__, "invite.json")}
  end

  def render("show.json", %{invite: invite}) do
    %{data: render_one(invite, __MODULE__, "invite.json")}
  end

  def render("invite.json", %{invite: invite}) do
    %{
      id: invite.id,
      open: invite.open,
      description: invite.description,
      email: invite.email,
      host: if Ecto.assoc_loaded?(invite.host) do
        render_one(invite.host, UserView, "user_short.json")
      end,
      invitee: if Ecto.assoc_loaded?(invite.invitee) do
        render_one(invite.invitee, UserView, "user_short.json")
      end,
      team: if Ecto.assoc_loaded?(invite.team) do
        render_one(invite.team, TeamView, "team_short.json")
      end,
    }
  end
end
