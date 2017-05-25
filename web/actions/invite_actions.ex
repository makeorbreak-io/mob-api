defmodule Api.InviteActions do
  use Api.Web, :action

  alias Api.{Invite, Repo}

  def all do
    Repo.all(Invite)
  end

  def get(id) do
    Repo.get!(Invite, id)
    |> Repo.preload([:host, :team, :invitee])
  end

  def create(conn, invite_params) do
    current_user = Guardian.Plug.current_resource(conn)
    |> Repo.preload(:team)

    changeset = Invite.changeset(%Invite{
      host_id: current_user.id,
      team_id: current_user.team.id
    }, invite_params)

    Repo.insert(changeset)
  end

  def change(id, invite_params) do
    invite = Repo.get!(Invite, id)
    changeset = Invite.changeset(invite, invite_params)

    Repo.update(changeset)
  end

  def accept(id) do
    case change(id, %{accepted: true}) do
      {:ok, invite} ->
        invite = Repo.preload(invite, [:team, :invitee])
        
        team = invite.team
        |> Repo.preload(:users)

        changeset = Ecto.Changeset.change(team)
        |> Ecto.Changeset.put_assoc(:users, invite.invitee)

        Repo.update(changeset)

        {:ok, invite}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    invite = Repo.get!(Invite, id)
    Repo.delete!(invite)
  end
end