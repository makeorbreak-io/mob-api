defmodule Api.Admin.TeamView do
  use Api.Web, :view

  alias Api.{ProjectView, InviteView, TeamMemberView}

  def render("index.json", %{teams: teams}) do
    %{data: render_many(teams, __MODULE__, "team.json")}
  end

  def render("show.json", %{team: team}) do
    %{data: render_one(team, __MODULE__, "team.json")}
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name,
      applied: team.applied,
      members: if Ecto.assoc_loaded?(team.members) do
        render_many(team.members, TeamMemberView, "member_user.json", as: :membership) end,
      project: if Ecto.assoc_loaded?(team.project) do
        render_one(team.project, ProjectView, "project.json") end,
      invites: if Ecto.assoc_loaded?(team.invites) do
        render_many(team.invites, InviteView, "invite.json") end,
    }
  end
end