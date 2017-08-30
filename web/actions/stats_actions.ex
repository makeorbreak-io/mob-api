defmodule Api.StatsActions do
  use Api.Web, :action

  alias Api.{User, Team, Workshop, Project, Repo}

  def stats do
    participant_query = from u in "users", where: u.role == "participant"
    applied_teams_query = from t in "teams", where: t.applied == true

    workshops = Repo.all(Workshop)

    workshop_stats = Enum.map(workshops, fn(workshop) ->
      query = from w in "users_workshops", where: w.workshop_id == type(^workshop.id, Ecto.UUID)

      attendees_count = Repo.aggregate(query, :count, :workshop_id)

      %{
        name: workshop.name,
        slug: workshop.slug,
        participants: attendees_count,
        participant_limit: workshop.participant_limit
      }
    end)

    %{
      users: Repo.aggregate(User, :count, :id),
      participants: Repo.aggregate(participant_query, :count, :id),
      teams: %{
        total: Repo.aggregate(Team, :count, :id),
        applied: Repo.aggregate(applied_teams_query, :count, :id)
      },
      workshops: workshop_stats,
      projects: Repo.aggregate(Project, :count, :id)
    }
  end
end
