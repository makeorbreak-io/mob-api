defmodule Api.Admin.StatsView do
  use Api.Web, :view

  def render("stats.json", %{stats: stats}) do
    %{data: %{
        users: %{
          total: stats.users,
          participants: stats.participants
        },
        teams: %{
          total: stats.teams
        },
        workshops: stats.workshops
      }
    }
  end
end
