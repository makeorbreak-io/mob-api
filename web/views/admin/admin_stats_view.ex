defmodule Api.Admin.StatsView do
  use Api.Web, :view

  def render("stats.json", %{stats: stats}) do
    %{data: %{
        users: %{
          hackathon: stats.users.hackathon,
          total: stats.users.total
        },
        roles: stats.roles,
        teams: %{
          total: stats.teams.total,
          applied: stats.teams.applied
        },
        workshops: stats.workshops,
        projects: %{
          total: stats.projects
        }
      }
    }
  end
end
