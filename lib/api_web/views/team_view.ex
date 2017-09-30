defmodule ApiWeb.TeamView do
  use Api.Web, :view

  alias ApiWeb.{InviteView, TeamMemberView}

  def render("index.json", %{teams: teams}) do
    %{data: render_many(teams, __MODULE__, "team_short.json")}
  end

  def render("show.json", %{team: team}) do
    %{data: render_one(team, __MODULE__, "team.json")}
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name,
      applied: team.applied,
      prize_preference: team.prize_preference,
      eligible: team.eligible,
      members: if Ecto.assoc_loaded?(team.members) do
        render_many(team.members, TeamMemberView, "member_user.json", as: :membership)
      end,
      invites: if Ecto.assoc_loaded?(team.invites) do
        render_many(team.invites, InviteView, "invite.json")
      end,
      disqualified_at: team.disqualified_at,
      project_name: team.project_name,
      project_desc: team.project_desc,
      technologies: team.technologies,
    }
  end

  def render("team_short.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name,
      applied: team.applied,
      eligible: team.eligible,
      prize_preference: team.prize_preference,
    }
  end
end
