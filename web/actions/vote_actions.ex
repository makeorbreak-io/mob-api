defmodule Api.VoteActions do
  use Api.Web, :action

  alias Api.{Vote, Category, Team}
  alias Ecto.{Multi}

  def upsert_votes(user, votes) do
    multi = Multi.new()

    votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc -> acc + length(ballot) end)

    valid_votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc ->
      if validate_ballot(ballot, user), do: acc + length(ballot), else: acc
    end)

    if votes_length == valid_votes_length do
      multi = Enum.reduce(votes, multi, fn {key, ballot}, multi ->
        category = Repo.get_by(Category, name: key)

        Multi.insert_or_update(multi, key, Vote.changeset(%Vote{}, %{
          voter_identity: user.voter_identity,
          category_id: category.id,
          ballot: ballot
        }))
      end)

      Repo.transaction(multi)
    else
      {:error, "Invalid vote"}
    end
  end

  def get_votes(user) do
    votes = from(v in Vote, where: v.voter_identity == ^user.voter_identity)
    |> Repo.all
    |> Repo.preload(:category)

    {:ok, votes}
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
end
