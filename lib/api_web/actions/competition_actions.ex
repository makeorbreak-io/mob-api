defmodule ApiWeb.CompetitionActions do
  use Api.Web, :action

  alias ApiWeb.{Competition, TeamActions, Vote, PaperVote, Team, Category, User}
  alias Ecto.{Changeset}

  defp _get do
    Repo.one(from(c in Competition)) || %Competition{}
  end

  defp _change(params) do
    _get()
    |> Competition.changeset(params)
    |> Repo.insert_or_update
  end

  defp missing_voters do
    voters =
      from(
        v in Vote,
        join: u in assoc(v, :voter),
        select: u.id
      )
      |> Repo.all()

    missing_voters = from(
      u in User,
      join: tm in assoc(u, :teams),
      join: t in assoc(tm, :team),
      where: not (u.id in ^voters),
      order_by: [asc: u.id],
      select: {t, u}
    )

    Repo.all(missing_voters)
    |> Enum.group_by(fn {team, _} -> team end, fn {_, user} -> user end)
    |> Enum.map(fn {k, v} -> %{
      team: k,
      users: v
    } end)

  end

  defp unredeemed_paper_votes do
    paper_votes = from pv in PaperVote,
      where: is_nil(pv.redeemed_at) and is_nil(pv.annulled_at),
      preload: [:category]

      Repo.all(paper_votes)
  end

  def start_voting do
    case voting_status() do
      :not_started ->
        TeamActions.shuffle_tie_breakers
        TeamActions.assign_missing_preferences
        _change(%{voting_started_at: DateTime.utc_now})
      :started -> {:error, :already_started}
      :ended -> {:error, :already_ended}
    end
  end

  def end_voting do
    case voting_status() do
      :not_started -> {:error, :not_started}
      :started ->
        at = DateTime.utc_now
        resolve_voting!(at)
        _change(%{voting_ended_at: at})
      :ended -> {:error, :already_ended}
    end
  end

  def voting_status do
    c = _get()
    now = DateTime.utc_now

    cond do
      c.voting_ended_at && DateTime.compare(c.voting_ended_at, now) == :lt -> :ended
      c.voting_started_at && DateTime.compare(c.voting_started_at, now) == :lt -> :started
      true -> :not_started
    end
  end

  def voting_started_at do
    _get().voting_started_at
  end

  def voting_ended_at do
    _get().voting_ended_at
  end

  def ballots(category, at \\ nil) do
    at = at || DateTime.utc_now

    votes =
      Repo.all(from(
        u in User.able_to_vote(at),
        join: v in assoc(u, :votes),
        where: v.category_id == ^(category.id),
        select: v
      ))
      |> Enum.map(&({&1.voter_identity, &1.ballot}))

    paper_votes =
      Repo.all(from(
        pv in PaperVote.countable(at),
        where: pv.category_id == ^(category.id)
      ))
      |> Enum.map(&({&1.id, [&1.team_id]}))

    (paper_votes ++ votes)
  end

  def resolve_voting!(at \\ nil) do
    Enum.map(
      Repo.all(Category),
      fn c ->
        c
        |> Changeset.change(podium: calculate_podium(c, at))
        |> Repo.update!
      end
    )
  end

  def calculate_podium(category, at \\ nil) do
    votable_teams =
      Team.votable(at)
      |> Repo.all()

    valid_team_ids =
      votable_teams
      |> Enum.map(&(&1.id))

    votes =
      ballots(category, at)
      |> clean_votes_into_ballots(valid_team_ids)

    tie_breakers =
      votable_teams
      |> Map.new(fn t ->
        {
          t.id,
          t.tie_breaker,
        }
      end)

    calculate_podium(votes, valid_team_ids, tie_breakers)
  end

  def clean_votes_into_ballots(votes, valid_team_ids) do
    votes
    |> Enum.map(fn {_id, ballot} ->
      ballot
      |> Enum.filter(&Enum.member?(valid_team_ids, &1))
    end)
    |> Enum.reject(&Enum.empty?/1)
  end

  def calculate_podium(votes, team_ids, tie_breakers) do
    votes
    |> Enum.flat_map(&Markus.ballot_to_pairs(&1, team_ids))
    |> Markus.pairs_to_preferences(team_ids)
    |> Markus.normalize_margins(team_ids)
    |> Markus.widen_paths(team_ids)
    |> Markus.sort_candidates_with_tie_breakers(team_ids, tie_breakers)
    |> Enum.take(3)
  end

  def status do
    %{
      voting_status: voting_status(),
      unredeemed_paper_votes: unredeemed_paper_votes(),
      missing_voters: missing_voters()
    }
  end
end
