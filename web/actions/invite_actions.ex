defmodule Api.InviteActions do
  use Api.Web, :action

  alias Api.{Invite, Repo, Mailer, Email, TeamMember}

  def all do
    Repo.all(Invite)
    |> Repo.preload([ :host, :team, :invitee ])
  end

  def get(id) do
    Repo.get!(Invite, id)
    |> Repo.preload([ :host, :team, :invitee ])
  end

  def create(conn, invite_params) do
    case Guardian.Plug.current_resource(conn) do
      nil -> {:error, "Authentication required"}
      user ->
        user = Repo.preload(user, :team)

        changeset = Invite.changeset(%Invite{
          host_id: user.id,
          team_id: user.team.id
        }, invite_params)

        result = Repo.insert(changeset)

        if invite_params["email"] do
          Email.invite_email(invite_params["email"], user) |> Mailer.deliver_later
        end

        result
    end
  end

  def change(id, invite_params) do
    invite = Repo.get!(Invite, id)
    changeset = Invite.changeset(invite, invite_params)

    Repo.update(changeset)
  end

  def accept(id) do
    case Repo.get(Invite, id) do
      nil -> {:error, "Unable to accept invite"}
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

  def for_current_user(conn) do
    current_user = Guardian.Plug.current_resource(conn)

    Invite
    |> where(invitee_id: ^current_user.id)
    |> Repo.all
    |> Repo.preload([ :host, :invitee, :team ])
  end
end
