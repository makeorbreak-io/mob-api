defmodule Api.StatsActions do
  use Api.Web, :action

  alias Api.{Project, Repo, Team, User, Workshop}

  def stats do
    participants = from u in "users", where: u.role == "participant"
    applied_teams = from t in "teams", where: t.applied == true

    %{
      users: Repo.aggregate(User, :count, :id),
      participants: Repo.aggregate(participants, :count, :id),
      teams: %{
        total: Repo.aggregate(Team, :count, :id),
        applied: Repo.aggregate(applied_teams, :count, :id)
      },
      workshops: workshop_stats(),
      projects: Repo.aggregate(Project, :count, :id)
    }
  end

  defp workshop_stats do
    workshops = Repo.all(Workshop)

    Enum.map(workshops, fn(workshop) ->
      query = from w in "users_workshops", where: w.workshop_id == type(^workshop.id, Ecto.UUID)

      attendees_count = Repo.aggregate(query, :count, :workshop_id)

      %{
        name: workshop.name,
        slug: workshop.slug,
        participants: attendees_count,
        participant_limit: workshop.participant_limit
      }
    end)
  end
end
