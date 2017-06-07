defmodule Api.TeamView do
  use Api.Web, :view

  alias Api.{TeamView, UserView, ProjectView, InviteView}

  def render("index.json", %{teams: teams}) do
    %{data: render_many(teams, TeamView, "team.json")}
  end

  def render("show.json", %{team: team}) do
    %{data: render_one(team, TeamView, "team.json")}
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name,
      owner: if team.owner do render_one(team.owner, UserView, "user_short.json") end,
      members: if team.users do render_many(team.users, UserView, "user_short.json") end,
      project: if team.project do render_one(team.project, ProjectView, "project.json") end,
      invites: if team.invites do render_many(team.invites, InviteView, "invite.json") end,
    }
  end

  def render("team_short.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name
    }
  end
end
