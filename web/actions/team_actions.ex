defmodule Api.TeamActions do
  use Api.Web, :action

  alias Api.{Team, User, TeamMember}

  def all do
    Repo.all(Team)
  end

  def get(id) do
    Repo.get!(Team, id)
    |> Repo.preload([:owner, :members, :project, invites: [:host, :invitee, :team]])
  end

  def create(conn, team_params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Team.changeset(%Team{user_id: current_user.id}, team_params)

    Repo.insert(changeset)
  end

  def update(conn, id, team_params) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    team = Repo.get!(Team, id)
    |> Repo.preload(:owner)

    if team.owner.id == user_id do
      changeset = Team.changeset(team, team_params)

      Repo.update(changeset)
    else
      {:unauthorized}
    end
  end

  def delete(conn, id) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
 
    team = Repo.get!(Team, id)
    |> Repo.preload(:owner)

    if team.owner.id == user_id do
      Repo.delete!(team)
      {:ok}
    else
      {:error, "Unauthorized"}
    end
  end

  def remove(conn, team_id, user_id) do
    team = Repo.get(Team, team_id)
    |> Repo.preload([:owner, :members])

    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}
      user ->
        current_user = Guardian.Plug.current_resource(conn)

        if current_user.id == team.owner.id || Enum.member?(team.members, current_user) do
          case from(t in TeamMember, where: t.user_id == ^user.id and t.team_id == ^team.id) |> Repo.delete_all do
            {1, nil} ->
              {:ok}
            {0, nil} ->
              {:error, "User isn't a member of team"}
          end
        else
          {:error, "Unauthorized"}
        end
    end
  end
end
