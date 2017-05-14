defmodule Api.TeamView do
  use Api.Web, :view

  def render("index.json", %{teams: teams}) do
    %{data: render_many(teams, Api.TeamView, "team.json")}
  end

  def render("show.json", %{team: team}) do
    %{data: render_one(team, Api.TeamView, "team.json")}
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      team_name: team.team_name
    }
  end
end
