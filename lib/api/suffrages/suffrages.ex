defmodule Api.Suffrages do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Teams.Team
  alias Api.Competitions
  alias Api.Suffrages.{Suffrage, Vote, PaperVote, Candidate, Category}
  alias Ecto.{Multi, Changeset}

  def all_suffrages do
    Repo.all(Suffrage)
  end

  def create_suffrage(params) do
    changeset = Suffrage.changeset(
      %Suffrage{competition_id: Competitions.default_competition.id},
      params
    )

    Repo.insert(changeset)
  end

  def get_suffrage(id) do
    Repo.get(Suffrage, id)
  end

  def update_suffrage(id, params) do
    suffrage = get_suffrage(id)

    Suffrage.changeset(suffrage, params)
    |> Repo.update
  end

  def delete_suffrage(id) do
    suffrage = get_suffrage(id)

    suffrage
    |> Repo.delete
  end

  def suffrage_status(id) do
    s = get_suffrage(id)
    now = DateTime.utc_now

    cond do
      s.voting_ended_at && DateTime.compare(s.voting_ended_at, now) == :lt -> :ended
      s.voting_started_at && DateTime.compare(s.voting_started_at, now) == :lt -> :started
      true -> :not_started
    end
  end

  def suffrage_voting_started_at(id) do
    get_suffrage(id).voting_started_at
  end

  def suffrage_voting_ended_at(id) do
    get_suffrage(id).voting_ended_at
  end

  def suffrage_summary(id) do
    %{
      status: suffrage_status(id),
      unredeemed_paper_votes: unredeemed_paper_votes(id),
      missing_voters: missing_voters(),
    }
  end

  def start_suffrage(suffrage_id) do
    case suffrage_status(suffrage_id) do
      :not_started ->
        create_candidates(suffrage_id)
        assign_tie_breakers(suffrage_id)
        update_suffrage(suffrage_id, %{voting_started_at: DateTime.utc_now})
      :started -> :already_started
      :ended -> :already_ended
    end
  end

  def candidates(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      c in Candidate,
      left_join: t in assoc(c, :team),
      where: c.suffrage_id == ^suffrage_id,
      where: is_nil(c.disqualified_at) or c.disqualified_at > ^at,
      select: c
    )
  end

  def create_candidate(params) do
    changeset = Candidate.changeset(%Candidate{}, params)

    Repo.insert(changeset)
  end

  def update_candidate(candidate, params) do
    Candidate.changeset(candidate, params) |> Repo.update()
  end

  def create_candidates(suffrage_id) do
    suffrage = Repo.get(Suffrage, suffrage_id)
    from(t in Team, where: t.competition_id == ^suffrage.competition_id and t.eligible == true)
    |> Repo.all()
    |> Enum.each(fn team ->
      create_candidate(%{team_id: team.id, suffrage_id: suffrage_id})
    end)
  end

  def end_suffrage(suffrage_id) do
    case suffrage_status(suffrage_id) do
      :not_started -> :not_started
      :started ->
        at = DateTime.utc_now
        resolve_suffrage!(suffrage_id, at)
        update_suffrage(suffrage_id, %{voting_ended_at: at})
      :ended -> :already_ended
    end
  end

  def upsert_votes(user, votes, suffrage_id) do
    multi = Multi.new()

    votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc -> acc + length(ballot) end)

    valid_votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc ->
      if validate_ballot(ballot, user), do: acc + length(ballot), else: acc
    end)

    if votes_length != valid_votes_length do
      throw {:error, "Invalid vote"}
    end

    case suffrage_status(suffrage_id) do
      :not_started -> throw {:error, :not_started}
      :ended -> throw {:error, :already_ended}
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

  def get_votes(user, suffrage_id) do
    votes = from(
      v in Vote,
      where: v.voter_identity == ^user.voter_identity,
      where: v.suffrage_id == ^suffrage_id
    )
    |> Repo.all

    {:ok, votes}
  end

  def build_info_start(suffrage_id) do
    at = suffrage_voting_started_at(suffrage_id)

    %{
      participants: %{
        initial_count: Repo.aggregate(voters(suffrage_id, at), :count, :id),
      },
      paper_votes: %{
        initial_count: Repo.aggregate(valid_paper_votes(suffrage_id, at), :count, :id),
      },
      teams: candidates(suffrage_id, at) |> Repo.all(),
    }
  end

  def voters(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      c in Candidate,
      left_join: t in assoc(c, :team),
      left_join: m in assoc(t, :members),
      where: t.suffrage_id == ^suffrage_id,
      where: is_nil(c.disqualified_at) or c.disqualified_at > ^at,
      select: m
    )
  end

  # def build_info_end(suffrage_id) do
  #   begun_at = suffrage_voting_started_at(suffrage_id)
  #   ended_at = suffrage_voting_ended_at(suffrage_id)
  #   suffrage = get_suffrage(suffrage_id) |> Repo.preload(:category)

  #   %{
  #     participants: %{
  #       initial_count:§
  #         Repo.aggregate(voters(suffrage_id, begun_at), :count, :id),
  #       final_count:
  #         Repo.aggregate(voters(suffrage_id, ended_at), :count, :id),
  #     },
  #     paper_votes: %{
  #       initial_count:
  #         Repo.aggregate(valid_paper_votes(suffrage_id, begun_at), :count, :id),
  #       final_count:
  #         Repo.aggregate(redeemed_paper_votes(suffrage_id, ended_at), :count, :id),
  #     },
  #     teams: candidates(suffrage_id, begun_at) |> Repo.all,
  #     category: suffrage.category,
  #     all_teams: Repo.all(Team),
  #     categories_to_votes: categories |> Map.new(fn c ->
  #       {
  #         c,
  #         ballots(suffrage, ended_at),
  #       }
  #     end),
  #   }
  # end

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
    |> on_votable_team(vote.suffrage_id)
    |> not_on_own_team(user)
  end

  defp on_valid_team(vote) do
    Repo.get(Team, vote)
  end

  defp on_votable_team(nil, _), do: nil
  defp on_votable_team(team, suffrage_id) do
    teams = candidates(suffrage_id) |> Repo.all()

    case team in teams do
      true -> team
      false -> nil
    end
  end

  defp not_on_own_team(nil, _), do: false
  defp not_on_own_team(team, user), do: user.team.team_id != team.id

  defp get_struct(user, suffrage_id) do
    query = from v in Vote,
      where: v.voter_identity == ^user.voter_identity,
      where: v.suffrage_id == ^suffrage_id

    case Repo.one(query) do
      nil -> %Vote{}
      vote -> vote
    end
  end

  def ballots(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    votes =
      Repo.all(from(
        v in Vote,
        where: v.suffrage_id == ^suffrage_id,
      ))
      |> Enum.map(&({&1.voter_identity, &1.ballot}))

    paper_votes =
      Repo.all(from(
        pv in redeemed_paper_votes(suffrage_id, at),
        where: pv.suffrage_id == ^(suffrage_id)
      ))
      |> Enum.map(&({&1.id, [&1.team_id]}))

    (paper_votes ++ votes)
  end

  def resolve_suffrage!(suffrage_id, at \\ nil) do
    get_suffrage(suffrage_id)
    |> Changeset.change(podium: calculate_podium(suffrage_id, at))
    |> Repo.update!
  end

  def calculate_podium(suffrage_id, at \\ nil) do
    candidates = candidates(suffrage_id, at)
    |> Repo.all()

    valid_team_ids =
      candidates
      |> Enum.map(&(&1.team_id))

    votes =
      ballots(suffrage_id, at)
      |> clean_votes_into_ballots(valid_team_ids)

    tie_breakers =
      candidates
      |> Map.new(fn t ->
        {
          t.team_id,
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

  def missing_voters do
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
      select: {t, u},
    )

    Repo.all(missing_voters)
    |> Enum.group_by(fn {team, _} -> team end, fn {_, user} -> user end)
    |> Enum.map(fn {k, v} -> %{
      team: k,
      users: v,
    } end)
  end

  def valid_paper_votes(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      pv in PaperVote,
      where: pv.suffrage_id == ^suffrage_id,
      where: is_nil(pv.annulled_at) or pv.annulled_at > ^at
    )
  end

  def redeemed_paper_votes(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from pv in valid_paper_votes(suffrage_id, at),
      where: not is_nil(pv.team_id)
  end

  def unredeemed_paper_votes(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from pv in valid_paper_votes(suffrage_id, at),
      where: is_nil(pv.redeemed_at)
  end

  def get_paper_vote(id) do
    Repo.get!(PaperVote, id)
    |> Repo.preload(:suffrage)
  end

  def create_paper_vote(suffrage, admin) do
    case suffrage_status(suffrage.id) do
      :ended -> :already_ended
      _ ->
        {
          :ok,
          %PaperVote{}
          |> PaperVote.changeset(%{
            created_by_id: admin.id,
            suffrage_id: suffrage.id
          })
          |> Repo.insert!
        }
    end
  end

  def redeem_paper_vote(paper_vote, team, member, suffrage, admin, at \\ nil) do
    at = at || DateTime.utc_now

    candidate = from(
      c in Candidate,
      where: c.team_id == ^team.id,
      where: c.suffrage_id == ^suffrage.id,
      where: is_nil(c.disqualified_at)
    ) |> Repo.one()

    cond do
      candidate.disqualified_at -> :team_disqualified
      paper_vote.redeemed_at -> :already_redeemed
      paper_vote.annulled_at -> :annulled
      suffrage_status(paper_vote.suffrage_id) == :not_started -> :not_started
      suffrage_status(paper_vote.suffrage_id) == :ended -> :already_ended
      true ->
        {
          :ok,
          paper_vote
          |> PaperVote.changeset(%{
            redeemed_at: at,
            redeeming_admin_id: admin.id,
            redeeming_member_id: member.id,
            team_id: team.id,
          })
          |> Repo.update!
        }
    end
  end

  def annul_paper_vote(paper_vote, admin, suffrage, at \\ nil) do
    at = at || DateTime.utc_now

    case suffrage_status(suffrage.id) do
      :ended -> :already_ended
      _ ->
        {
          :ok,
          paper_vote
          |> PaperVote.changeset(%{
            annulled_at: at,
            annulled_by_id: admin.id,
          })
          |> Repo.update!
          |> Repo.preload(:suffrage)
        }
    end
  end

  def disqualify_team(team, suffrage, admin) do
    from(
      c in Candidate,
      where: c.team_id == ^team.id,
      where: c.suffrage_id == ^suffrage.id,
      where: is_nil(c.disqualified_at),
      update: [set: [
        disqualified_at: ^(DateTime.utc_now),
        disqualified_by_id: ^(admin.id),
      ]]
    )
    |> Repo.update_all([])
  end

  def assign_tie_breakers(suffrage_id) do
    candidates = candidates(suffrage_id) |> Repo.all()

    tie_breakers = 1..Enum.count(candidates) |> Enum.shuffle()

    Enum.each(candidates, fn candidate ->
      {number, tie_breakers} = List.pop_at(tie_breakers, 0)
      update_candidate(candidate, %{tie_breaker: number})
    end)
  end
end
