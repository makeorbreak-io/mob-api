defmodule Api.Admin.StatsView do
  use Api.Web, :view

  def render("users_teams.json", %{stats: stats}) do
    IO.puts inspect stats
    %{data: %{
        users: %{
          total: stats.users,
          participants: stats.participants
        },
        teams: %{
          total: stats.teams
        }
      }
    }
  end
end
