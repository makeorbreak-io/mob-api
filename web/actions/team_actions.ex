defmodule Api.TeamActions do
  use Api.Web, :action

  alias Api.{Team, User, TeamMember}

  def all do
    Repo.all(Team)
  end

  def get(id) do
    Repo.get!(Team, id)
    |> Repo.preload([:project, members: [:user], invites: [:host, :invitee, :team]])
  end

  def create(conn, team_params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Team.changeset(%Team{}, team_params)

    case Repo.insert(changeset) do
      {:ok, team} ->
        Repo.insert! %TeamMember{user_id: current_user.id, team_id: team.id, role: "owner"}

        team = team
        |> Repo.preload([:project, :invites, members: [:user]])

        {:ok, team}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(conn, id, team_params) do
    user = Guardian.Plug.current_resource(conn)

    team = Repo.get!(Team, id)

    if is_team_member?(team, user) do
      changeset = Team.changeset(team, team_params)

      case Repo.update(changeset) do
        {:ok, team} ->
          team = team
          |> Repo.preload([:project, :invites, members: [:user]])

          {:ok, team}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:unauthorized}
    end
  end

  def delete(conn, id) do
    user = Guardian.Plug.current_resource(conn)
 
    team = Repo.get!(Team, id)

    if is_team_member?(team, user) do
      Repo.delete!(team)
      {:ok}
    else
      {:error, "Unauthorized"}
    end
  end

  def remove(conn, team_id, user_id) do
    team = Repo.get!(Team, team_id)

    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}
      user ->
        current_user = Guardian.Plug.current_resource(conn)

        query = from(t in TeamMember, where:
          t.user_id == ^user.id and t.team_id == ^team.id)

        if is_team_member?(team, current_user) do
          if !team.applied do
            case Repo.delete_all(query) do
              {1, nil} ->
                {:ok}
              {0, _} ->
                {:error, "User isn't a member of team"}
            end
          else
            {:error, "Can't remove users after applying to the event"}       
          end
        else
          {:error, "Unauthorized"}
        end
    end
  end

  defp is_team_member?(team, user) do
    team = team
    |> Repo.preload([:members])

    Enum.any?(team.members, fn(member) ->
      member.user_id == user.id
    end)
  end
end
