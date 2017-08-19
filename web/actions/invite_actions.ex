defmodule Api.InviteActions do
  use Api.Web, :action

  alias Api.{Invite, Repo, Mailer, Email, TeamMember}

  def for_current_user(conn) do
    current_user = Guardian.Plug.current_resource(conn)

    Invite
    |> where(invitee_id: ^current_user.id)
    |> Repo.all
    |> Repo.preload([:host, :invitee, :team])
  end

  def get(id) do
    Repo.get!(Invite, id)
    |> Repo.preload([:host, :team, :invitee])
  end

  def create(conn, invite_params) do
    user = Guardian.Plug.current_resource(conn)
    |> Repo.preload(:team)

    changeset = Invite.changeset(%Invite{
      host_id: user.id,
      team_id: if user.team do user.team.id end
    }, invite_params)

    result = Repo.insert(changeset)

    if invite_params["email"] do
      Email.invite_email(invite_params["email"], user) |> Mailer.deliver_later
    end

    result
  end

  def accept(id) do
    case Repo.get(Invite, id) do
      nil -> {:error, "Invite not found"}
      invite ->
        changeset = TeamMember.changeset(%TeamMember{},
          %{user_id: invite.invitee_id, team_id: invite.team_id})

        case Repo.insert(changeset) do
          {:ok, _} -> Repo.delete(invite)
          {:error, _} -> {:error, "Unable to create membership"}
        end
    end
  end

  def delete(id) do
    invite = Repo.get!(Invite, id)
    Repo.delete!(invite)
  end
end
