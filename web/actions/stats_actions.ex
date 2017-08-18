defmodule Api.StatsActions do
  use Api.Web, :action

  alias Api.{User, Team, Workshop, Repo}

  def stats do
    participant_query = from u in "users", where: u.role == "participant"

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
      teams: Repo.aggregate(Team, :count, :id),
      workshops: workshop_stats
    }
  end
end