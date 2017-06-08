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

  def update(id, team_params) do
    team = Repo.get!(Team, id)
    changeset = Team.changeset(team, team_params)

    Repo.update(changeset)
  end

  def delete(conn, id) do
    case Guardian.Plug.current_resource(conn) do
      %{id: id} ->
        team = Repo.get!(Team, id)
        |> Repo.preload(:owner)

        if team.owner.id == id do
          Repo.delete!(team)
        else
          conn
          |> put_status(401)
          |> render(ErrorView, "error.json", error: "Unauthorized")
        end
      nil ->
        conn
        |> put_status(401)
        |> render(ErrorView, "error.json", error: "Authentication required")
    end
  end
end
