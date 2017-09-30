defmodule ApiWeb.Admin.StatsView do
  use Api.Web, :view

  def render("stats.json", %{stats: stats}) do
    %{data: %{
        users: %{
          hackathon: stats.users.hackathon,
          checked_in: stats.users.checked_in,
          total: stats.users.total,
        },
        roles: stats.roles,
        teams: %{
          total: stats.teams.total,
          applied: stats.teams.applied,
        },
        workshops: stats.workshops,
      }
    }
  end
end
