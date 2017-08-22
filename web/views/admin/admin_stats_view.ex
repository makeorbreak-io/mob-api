defmodule Api.Admin.StatsView do
  use Api.Web, :view

  def render("stats.json", %{stats: stats}) do
    %{data: %{
        users: %{
          total: stats.users,
          participants: stats.participants
        },
        teams: %{
          total: stats.teams.total,
          applied: stats.teams.applied
        },
        workshops: stats.workshops
      }
    }
  end
end
