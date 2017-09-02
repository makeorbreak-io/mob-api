defmodule Api.TeamActions do
  use Api.Web, :action

  alias Api.{Team, User, TeamMember, Email, Mailer}

  def all do
    Repo.all(Team)
    |> Repo.preload([:project, members: [:user], invites: [:host, :invitee, :team]])
  end

  def get(id) do
    Repo.get!(Team, id)
    |> Repo.preload([:project, members: [:user], invites: [:host, :invitee, :team]])
  end

  def create(current_user, team_params) do
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

  def update(current_user, id, team_params) do
    team = get(id)

    if is_team_member?(team, current_user) do
      Team.changeset(team, team_params)
      |> email_if_applying(team)
      |> Repo.update
    else
      {:unauthorized}
    end
  end

  def delete(current_user, id) do
    team = Repo.get!(Team, id)

    case is_team_member?(team, current_user) do
      true -> Repo.delete!(team)
      false -> {:unauthorized}
    end
  end

  def remove(current_user, team_id, user_id) do
    team = Repo.get!(Team, team_id)

    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}
      user ->
        query = from(t in TeamMember, where:
          t.user_id == ^user.id and t.team_id == ^team.id)

        if is_team_member?(team, current_user) do
          if team.applied do
            {:error, "Can't remove users after applying to the event"}
          else
            case Repo.delete_all(query) do
              {1, _} ->
                {:ok}
              {0, _} ->
                {:error, "User isn't a member of team"}
            end
          end
        else
          {:unauthorized}
        end
    end
  end

  def update_any(id, team_params) do
    team = get(id)

    Team.changeset(team, team_params)
    |> email_if_applying(team)
    |> Repo.update
  end

  def delete_any(id) do
    Repo.get!(Team, id) |> Repo.delete!
  end

  def remove_any(team_id, user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, "User not found"}
      user ->
        query = from(t in TeamMember, where:
          t.user_id == ^user.id and t.team_id == ^team_id)

        case Repo.delete_all(query) do
          {1, _} ->
            {:ok}
          {0, _} ->
            {:error, "User isn't a member of team"}
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

  defp email_if_applying(changeset, team) do
    applied_change = Map.has_key?(changeset.changes, :applied)
    applied_true = Map.get(changeset.changes, :applied) == true

    if applied_change and applied_true do
      Enum.map(team.members, fn(member) ->
        Email.joined_hackathon_email(member.user, team) |> Mailer.deliver_later
      end)
    end

    changeset
  end
end
