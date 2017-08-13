defmodule Api.InviteView do
  use Api.Web, :view

  alias Api.{InviteView, UserView, TeamView}

  def render("index.json", %{invites: invites}) do
    %{data: render_many(invites, InviteView, "invite.json")}
  end

  def render("show.json", %{invite: invite}) do
    %{data: render_one(invite, InviteView, "invite.json")}
  end

  def render("invite.json", %{invite: invite}) do
    %{
      id: invite.id,
      open: invite.open,
      description: invite.description,
      email: invite.email,
      host: if invite.host do render_one(invite.host, UserView, "user_short.json") end,
      invitee: if invite.invitee do render_one(invite.invitee, UserView, "user_short.json") end,
      team: if invite.team do render_one(invite.team, TeamView, "team_short.json") end
    }
  end
end
