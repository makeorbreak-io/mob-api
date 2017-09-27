defmodule ApiWeb.VoteActions do
  use Api.Web, :action

  alias ApiWeb.{Repo, Vote, Category, Team, CompetitionActions, User, PaperVote}
  alias Ecto.{Multi}

  def upsert_votes(user, votes) do
    multi = Multi.new()

    votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc -> acc + length(ballot) end)

    valid_votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc ->
      if validate_ballot(ballot, user), do: acc + length(ballot), else: acc
    end)

    if votes_length != valid_votes_length do
      throw {:error, "Invalid vote"}
    end

    if CompetitionActions.voting_status == :not_started do
      throw {:error, :not_started}
    end
    if CompetitionActions.voting_status == :ended do
      throw {:error, :already_ended}
    end

    multi = Enum.reduce(votes, multi, fn {key, ballot}, multi ->
      category = Repo.get_by(Category, name: key)

      Multi.insert_or_update(multi,
        key,
        Vote.changeset(
          get_struct(user, category),
          %{
            voter_identity: user.voter_identity,
            category_id: category.id,
            ballot: ballot,
          }
        )
      )
    end)

    Repo.transaction(multi)
  catch
    e -> e
  end

  def get_votes(user) do
    votes = from(v in Vote, where: v.voter_identity == ^user.voter_identity)
    |> Repo.all
    |> Repo.preload(:category)

    {:ok, votes}
  end

  def build_info_start do
    at = CompetitionActions.voting_started_at()

    %{
      participants: %{
        initial_count: Repo.aggregate(User.able_to_vote(at), :count, :id),
      },
      paper_votes: %{
        initial_count: Repo.aggregate(PaperVote.not_annuled(at), :count, :id),
      },
      teams: Team.votable(at) |> Repo.all(),
    }
  end

  def build_info_end do
    begun_at = CompetitionActions.voting_started_at()
    ended_at = CompetitionActions.voting_ended_at()
    categories = Repo.all(Category)

    %{
      participants: %{
        initial_count:
          Repo.aggregate(User.able_to_vote(begun_at), :count, :id),
        final_count:
          Repo.aggregate(User.able_to_vote(ended_at), :count, :id),
      },
      paper_votes: %{
        initial_count:
          Repo.aggregate(PaperVote.not_annuled(begun_at), :count, :id),
        final_count:
          Repo.aggregate(PaperVote.countable(ended_at), :count, :id),
      },
      teams: Team.votable(begun_at) |> Repo.all,
      categories: categories,
      all_teams: Repo.all(Team),
      categories_to_votes: categories |> Map.new(fn c ->
        {
          c,
          CompetitionActions.ballots(c, ended_at),
        }
      end),
    }
  end

  defp validate_ballot(votes, user), do: validate_ballot(votes, user, [])
  defp validate_ballot([], _, acc), do: Enum.all?(acc)
  defp validate_ballot([vote|rest], user, acc), do: validate_ballot(
    rest,
    user,
    acc ++ [validate_vote(vote, user)]
  )

  defp validate_vote(vote, user) do
    vote
    |> on_valid_team()
    |> on_votable_team()
    |> not_on_own_team(user)
  end

  defp on_valid_team(vote) do
    Repo.get(Team, vote)
  end

  defp on_votable_team(nil), do: nil
  defp on_votable_team(team) do
    teams = Team.votable() |> Repo.all()

    case team in teams do
      true -> team
      false -> nil
    end
  end

  defp not_on_own_team(nil, _), do: false
  defp not_on_own_team(team, user), do: user.team.team_id != team.id

  defp get_struct(user, category) do
    query = from v in Vote,
      where: v.voter_identity == ^user.voter_identity,
      where: v.category_id == ^category.id

    case Repo.one(query) do
      nil -> %Vote{}
      vote -> vote
    end
  end
end
