defmodule Api.TeamActions do
  use Api.Web, :action

  alias Api.Team

  def all do
    Repo.all(Team)
  end

  def get(id) do
    Repo.get!(Team, id)
    |> Repo.preload([:owner, :users, :project, invites: [:host, :invitee, :team]])
  end

  def create(conn, team_params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Team.changeset(%Team{user_id: current_user.id}, team_params)

    Repo.insert(changeset)
  end

  def update(conn, id, team_params) do
    case Guardian.Plug.current_resource(conn) do
      %{id: user_id} ->

        team = Repo.get!(Team, id)
        |> Repo.preload(:owner)

        if team.owner.id == user_id do
          changeset = Team.changeset(team, team_params)

          Repo.update(changeset)
        else
          {:unauthorized}
        end
      nil ->
        {:unauthenticated}
    end
  end

  def delete(conn, id) do
    case Guardian.Plug.current_resource(conn) do
      %{id: user_id} ->
        team = Repo.get!(Team, id)
        |> Repo.preload(:owner)

        if team.owner.id == user_id do
          Repo.delete!(team)
          {:ok}
        else
          {:error, "Unauthorized"}
        end
      nil ->
        {:error, "Authentication required"}
    end
  end
end
