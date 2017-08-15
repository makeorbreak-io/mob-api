defmodule Api.StatsActions do
  use Api.Web, :action

  alias Api.{User, Team, Repo}

  def users_and_teams do
    participant_query = from u in "users", where: u.role == "participant"

    %{
      users: Repo.aggregate(User, :count, :id),
      participants: Repo.aggregate(participant_query, :count, :id),
      teams: Repo.aggregate(Team, :count, :id)
    }
  end
end