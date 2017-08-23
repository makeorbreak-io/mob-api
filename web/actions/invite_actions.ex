defmodule Api.InviteActions do
  use Api.Web, :action

  @slack_token Application.get_env(:api, :slack_token)
  @slack_error_codes %{
    already_invited: "was already invited",
    already_in_team: "is already in the team",
    missing_scope: "couldn't be invited at this time",
    invalid_email: "isn't valid",
    channel_not_found: "couldn't join inexistent channel",
    user_disabled: "account has been deactivated",
    sent_recently: "was invited recently"
  }

  alias Api.{Invite, Repo, Mailer, Email, TeamMember, UserActions}

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
    |> UserActions.add_current_team

    changeset = Invite.changeset(%Invite{
      host_id: user.id,
      team_id: if user.team do user.team.team_id end
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

  def invite_to_slack(email) do
    invite_url = "https://portosummerofcode.slack.com/api/users.admin.invite?token=#{@slack_token}&email=#{email}"
    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    {:ok, response} = HTTPoison.post(invite_url, "", headers)
    
    case Poison.decode! response.body do
      %{"ok" => true} -> {:ok, true}
      %{"ok" => false, "error" => error} ->
        error_message = Map.get(@slack_error_codes, String.to_atom(error))
        {:error, %{"email" => [error_message]}}
    end
  end
end
