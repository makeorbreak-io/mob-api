defmodule Api.TeamActions do
  use Api.Web, :action

  alias Api.Team

  def all do
    Repo.all(Team)
  end

  def get(id) do
    Repo.get!(Team, id)
  end

  def create(conn, team_params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Team.changeset(%Team{user_id: current_user.id}, team_params)

    Repo.insert(changeset)
  end

  def update(id, team_params) do
    team = Repo.get!(Team, id)
    changeset = Team.changeset(team, team_params)

    Repo.update(changeset)
  end

  def delete(id) do
    team = Repo.get!(Team, id)
    Repo.delete!(team)
  end
end