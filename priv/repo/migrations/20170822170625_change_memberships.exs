defmodule Api.Repo.Migrations.ChangeMemberships do
  use Ecto.Migration

  alias Api.{Repo, Team, TeamMember}

  def change do
    alter table(:users_teams) do
      add :role, :string, default: "member"
    end

    # Commented out since this script only needed to be ran once and it causes
    # a sync problem between the DB and the Team Model when running all the migrations
    # at the same time
    # flush()

    # owners = Enum.map(Repo.all(Team), fn(team) -> [team.id, team.user_id] end)

    # Enum.each(owners, fn([team_id, user_id]) -> 
    #   Repo.insert!(%TeamMember{team_id: team_id, user_id: user_id, role: "owner"})
    # end)
  end
end
