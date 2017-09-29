defmodule ApiWeb.TeamActions do
  use Api.Web, :action

  alias ApiWeb.{Team, User, TeamMember, Email, Mailer, GithubActions, CompetitionActions, Category}
  alias Ecto.{Changeset, Multi}

  def all do
    Repo.all(Team)
    |> Repo.preload([members: [:user], invites: [:host, :invitee, :team]])
  end

  def get(id) do
    Repo.get!(Team, id)
    |> Repo.preload([members: [:user], invites: [:host, :invitee, :team]])
  end

  def create(current_user, team_params) do
    changeset = Team.changeset(%Team{}, team_params, Repo)

    case Repo.insert(changeset) do
      {:ok, team} ->
        Repo.insert! %TeamMember{user_id: current_user.id, team_id: team.id, role: "owner"}

        team = team
        |> Repo.preload([:invites, members: [:user]])

        {:ok, team}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(current_user, id, team_params) do
    team = get(id)

    if is_team_member?(team, current_user) do
      Team.changeset(team, team_params, Repo)
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
    if CompetitionActions.voting_status == :started do
      throw {:error, :already_started}
    end

    team = Repo.get!(Team, team_id)
    user = Repo.get(User, user_id) || throw {:error, "User not found"}

    if !is_team_member?(team, current_user) do
      throw {:unauthorized}
    end

    if team.applied do
      throw {:error, "Can't remove users after applying to the event"}
    end

    case Repo.delete_all(from(
        t in TeamMember,
        where: t.user_id == ^user.id and t.team_id == ^team.id
    )) do
      {1, _} ->
        {:ok}
      {0, _} ->
        {:error, "User isn't a member of team"}
    end
  catch
    e -> e
  end

  def update_any(id, team_params) do
    team = get(id)

    team_params = case CompetitionActions.voting_status do
      :started ->
        {_, team_params} = Map.pop(team_params, :eligible)
        {_, team_params} = Map.pop(team_params, "eligible")
        team_params
      _ ->
        team_params
    end

    Team.admin_changeset(team, team_params, Repo)
    |> email_if_applying(team)
    |> Repo.update
  end

  def delete_any(id) do
    Repo.get!(Team, id) |> Repo.delete!
  end

  def remove_any(team_id, user_id) do
    if CompetitionActions.voting_status == :started do
        throw {:error, :already_started}
    end
    user = Repo.get(User, user_id) || throw {:error, "User not found"}
    case Repo.delete_all(from(
        t in TeamMember,
        where: t.user_id == ^user.id and t.team_id == ^team_id
    )) do
      {1, _} ->
        {:ok}
      {0, _} ->
        {:error, "User isn't a member of team"}
    end
  catch
    e -> e
  end

  def shuffle_tie_breakers do
    teams = Repo.all(from t in Team)

    multi = Multi.new

    # I can't update the tie breakers to their intended value on just one pass.
    # Consider the case where you have two teams, A and B, with tie breakers 1
    # and 2, respectively. If we decide that team A gets the tie breaker 2,
    # on the fisrt update, the BD will complain that both A and B have the tie
    # breaker 1. In order to get around that, we make them all negative first,
    # and only assign the new tie breakers after that. Since we know the new
    # tie breakers won't ever be negative, this gets rid of all conflicts.
    multi =
      Enum.reduce(
        teams,
        multi,
        fn team, multi ->
          Multi.update(
            multi,
            "#{team.id} to negative",
            Changeset.change(team, tie_breaker: -1 * team.tie_breaker)
          )
        end
      )

    multi =
      Enum.reduce(
        Enum.zip([
          teams,
          (1..Enum.count(teams)) |> Enum.shuffle
        ]),
        multi,
        fn {team, new_tb}, multi ->
          Multi.update(
            multi,
            "#{team.id} to shuffled",
            team
            |> Changeset.change()
            |> Changeset.force_change(:tie_breaker, new_tb)
          )
        end
      )

    Repo.transaction(multi)
  end

  def create_repo(id) do
    team = Repo.get!(Team, id)

    case GithubActions.create_repo(team) do
      {:ok, repo} ->
        __MODULE__.update_any(id, %{repo: repo})
        :ok
      {:error, error} -> {:error, error}
    end
  end

  def add_users_to_repo(id) do
     team = Repo.get!(Team, id)
     |> Repo.preload(members: :user)

    Enum.each(team.members, fn(membership) ->
      GithubActions.add_collaborator(team.repo, membership.user.github_handle)
    end)
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

  def disqualify(team_id, admin) do
    from(
      t in Team,
      where: t.id == ^team_id,
      where: is_nil(t.disqualified_at),
      update: [set: [
        disqualified_at: ^(DateTime.utc_now),
        disqualified_by_id: ^(admin.id)
      ]]
    )
    |> Repo.update_all([])
  end

  def assign_missing_preferences do
    cats = Repo.all(Category) |> Enum.map(&(&1.name))

    Repo.all(from(t in Team, where: is_nil(t.prize_preference)))
    |> Enum.map(fn t ->
      t
      |> Changeset.change(prize_preference: cats |> Enum.shuffle)
      |> Repo.update!
    end)
  end
end
