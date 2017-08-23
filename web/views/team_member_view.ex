defmodule Api.TeamMemberView do
  use Api.Web, :view

  alias Api.{ProjectView, InviteView, UserHelper}

  def render("member_user.json", %{membership: membership}) do
    %{
      id: membership.user.id,
      role: membership.role,
      display_name: UserHelper.display_name(membership.user),
      gravatar_hash: UserHelper.gravatar_hash(membership.user)
    }
  end

  def render("member_team_short.json", %{membership: membership}) do
    %{
      id: membership.team.id,
      role: membership.role,
      name: membership.team.name,
      applied: membership.team.applied
    }
  end

  def render("member_team_full.json", %{membership: membership}) do
    %{
      id: membership.team.id,
      role: membership.role,
      name: membership.team.name,
      applied: membership.team.applied,
      members: if Ecto.assoc_loaded?(membership.team.members) do
        render_many(membership.team.members, __MODULE__, "member_user.json", as: :membership) end,
      project: if Ecto.assoc_loaded?(membership.team.project) do
        render_one(membership.team.project, ProjectView, "project.json") end,
      invites: if Ecto.assoc_loaded?(membership.team.invites) do
        render_many(membership.team.invites, InviteView, "invite.json") end,
    }
  end
end
