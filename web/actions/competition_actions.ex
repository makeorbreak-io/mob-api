defmodule Api.CompetitionActions do
  use Api.Web, :action

  alias Api.{Competition, TeamActions, Vote, PaperVote, Team, Category, User}
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
    voters = from(v in Vote,
      join: u in assoc(v, :voter),
      select: u.id) |> Repo.all()

    missing_voters = from u in User,
      join: tm in assoc(u, :teams),
      join: t in assoc(tm, :team),
      where: u.id not in ^voters,
      select: {t, u}

    Repo.all(missing_voters)
    |> Enum.group_by(fn {team, _} -> team end, fn {_, user} -> user end)
    |> Enum.map(fn {k, v} -> %{team: k, users: v} end)

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
        resolve_voting!()
        _change(%{voting_ended_at: DateTime.utc_now})
      :ended -> {:error, :already_ended}
    end
  end

  def voting_status do
    c = _get()
    now = DateTime.utc_now

    cond do
      c.voting_ended_at && c.voting_ended_at <= now -> :ended
      c.voting_started_at && c.voting_started_at <= now -> :started
      true -> :not_started
    end
  end

  def voting_started_at do
    _get().voting_started_at
  end

  def voting_ended_at do
    _get().voting_ended_at
  end

  def ballots(category) do
    votes =
      Repo.all(from(
        v in Vote,
        where: v.category_id == ^(category.id)
      ))
      |> Enum.map(&({&1.voter_identity, &1.ballot}))

    paper_votes =
      Repo.all(from(
        pv in PaperVote.countable(),
        where: pv.category_id == ^(category.id)
      ))
      |> Enum.map(&({&1.id, [&1.team_id]}))

    (paper_votes ++ votes)
  end

  def resolve_voting! do
    Enum.map(
      Repo.all(Category),
      fn c ->
        c
        |> Changeset.change(podium: calculate_podium(c))
        |> Repo.update!
      end
    )
  end

  def calculate_podium(category) do
    valid_team_ids =
      Repo.all(Team.votable(), select: :id)
      |> Enum.map(&Map.get(&1, :id))

    votes =
      ballots(category)
      |> Enum.map(fn {_id, ballot} ->
        Enum.filter(ballot, &Enum.member?(valid_team_ids, &1))
      end)
      |> Enum.reject(&Enum.empty?/1)

    votes
    |> Enum.flat_map(&Markus.ballot_to_pairs(&1, valid_team_ids))
    |> Markus.pairs_to_preferences(valid_team_ids)
    |> Markus.normalize_margins(valid_team_ids)
    |> Markus.widen_paths(valid_team_ids)
    |> Markus.rank_candidates(valid_team_ids)
    |> Enum.map(&elem(&1, 1))
    |> Enum.flat_map(fn level ->
      Enum.map(
        level,
        fn team_id ->
          t = Repo.get!(Team, team_id)
          {t.tie_breaker, t.id}
        end
      )
      |> Enum.sort
      |> Enum.map(&elem(&1, 1))
    end)
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
