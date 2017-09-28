defmodule ApiWeb.StatsActions do
  use Api.Web, :action

  alias Api.Accounts.User
  alias ApiWeb.{Team, TeamMember, Workshop, WorkshopAttendance}

  def stats do
    roles = from(
      u in User,
      group_by: :role,
      order_by: :role,
      select: %{role: u.role, total: count(u.id)},
    )
    applied_teams = from t in Team, where: t.applied == true
    applied_users = from u in TeamMember,
      join: t in assoc(u, :team),
      where: t.applied == true,
      preload: [team: t]
    checked_in_users = from u in User, where: u.checked_in == true

    %{
      users: %{
        total: Repo.aggregate(User, :count, :id),
        hackathon: Repo.aggregate(applied_users, :count, :user_id),
        checked_in: Repo.aggregate(checked_in_users, :count, :id),
      },
      roles: Repo.all(roles),
      teams: %{
        total: Repo.aggregate(Team, :count, :id),
        applied: Repo.aggregate(applied_teams, :count, :id),
      },
      workshops: workshop_stats(),
    }
  end

  defp workshop_stats do
    workshops = Repo.all(Workshop)

    Enum.map(workshops, fn(workshop) ->
      query = from w in WorkshopAttendance,
        where: w.workshop_id == type(^workshop.id, Ecto.UUID)

      attendees_count = Repo.aggregate(query, :count, :workshop_id)

      %{
        name: workshop.name,
        slug: workshop.slug,
        participants: attendees_count,
        participant_limit: workshop.participant_limit,
      }
    end)
  end
end
