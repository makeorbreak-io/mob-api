defmodule ApiWeb.InviteActions do
  use Api.Web, :action

  @slack_token Application.get_env(:api, :slack_token)
  @team_user_limit Application.get_env(:api, :team_user_limit)
  @http Application.get_env(:api, :http_lib)

  alias ApiWeb.{Email, Invite, Mailer, Repo, TeamMember, User, UserActions, CompetitionActions}
  alias Ecto.Changeset

  def for_current_user(current_user) do
    Invite
    |> where(invitee_id: ^current_user.id)
    |> Repo.all
    |> Repo.preload([:host, :invitee, :team])
  end

  def get(id) do
    Repo.get!(Invite, id)
    |> Repo.preload([:host, :team, :invitee])
  end

  def create(current_user, invite_params) do
    user = UserActions.preload_user_data(current_user)

    if user.team do
      create_if_vacant(user, invite_params)
    else
      :user_without_team
    end
  end

  def accept(id) do
    case Repo.get(Invite, id) do
      nil -> :invite_not_found
      invite -> create_membership(invite)
    end
  end

  def delete(id) do
    invite = Repo.get!(Invite, id)
    Repo.delete!(invite)
  end

  def invite_to_slack(email) do
    base_url = "https://portosummerofcode.slack.com/api/users.admin.invite"
    params = URI.encode_query(%{token: @slack_token, email: email})
    url = base_url <> "?" <> params
    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    with {:ok, response} <- @http.post(url, "", headers), do: process_slack_invite(response)
  end

  defp create_if_vacant(user, invite_params) do
    # Since user.team returns a membership instead of the actual team,
    # we need to send user.team.team
    invites_count = Enum.count(user.team.team.invites)
    members_count = Enum.count(user.team.team.members)
    team_users = invites_count + members_count

    if team_users < @team_user_limit do
      changeset = Invite.changeset(%Invite{
        host_id: user.id,
        team_id: user.team.team_id,
      }, invite_params)
      |> maybe_associate_user()
      |> process_email(user)

      Repo.insert(changeset)
    else
      :team_user_limit
    end
  end

  def update(invite, params) do
    Invite.changeset(invite, params) |> Repo.update
  end

  defp maybe_associate_user(changeset) do
    if Map.has_key?(changeset.changes, :email) do
      case Repo.get_by(User, email: Map.get(changeset.changes, :email)) do
        nil -> changeset
        user ->
          Changeset.delete_change(changeset, :email)
          |> Changeset.put_change(:invitee_id, user.id)
      end
    else
      changeset
    end
  end

  defp process_email(changeset, host) do
    cond do
      Map.has_key?(changeset.changes, :email) -> send_invite_email(changeset, host)
      Map.has_key?(changeset.changes, :invitee_id) -> send_notification_email(changeset, host)
      true -> nil
    end
  end

  defp create_membership(invite) do
    case CompetitionActions.voting_status do
      :started -> :already_started
      _ ->
        changeset = TeamMember.changeset(
          %TeamMember{},
          %{user_id: invite.invitee_id, team_id: invite.team_id}
        )
        case Repo.insert(changeset) do
          {:ok, _} -> Repo.delete(invite)
          {:error, _} -> {:error, "Unable to create membership"}
        end
    end
  end

  defp send_invite_email(changeset, host) do
    Map.get(changeset.changes, :email)
    |> Email.invite_email(host)
    |> Mailer.deliver_later

    changeset
  end

  defp send_notification_email(changeset, host) do
    Repo.get(User, Map.get(changeset.changes, :invitee_id))
    |> Email.invite_notification_email(host)
    |> Mailer.deliver_later

    changeset
  end

  defp process_slack_invite(response) do
    case Poison.decode! response.body do
      %{"ok" => true} -> {:ok, true}
      %{"ok" => false, "error" => error} ->
        message = message(String.to_atom(error))
        {:error, %Ecto.Changeset{
          valid?: false,
          types: %{email: :string},
          errors: [email: {message, []}],
        }}
    end
  end

  defp message(:already_invited), do: "was already invited"
  defp message(:already_in_team), do: "is already in the team"
  defp message(:missing_scope), do: "couldn't be invited at this time"
  defp message(:invalid_email), do: "isn't valid"
  defp message(:channel_not_found), do: "couldn't join inexistent channel"
  defp message(:user_disabled), do: "account has been deactivated"
  defp message(:sent_recently), do: "was invited recently"
end
