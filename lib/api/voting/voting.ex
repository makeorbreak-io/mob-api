defmodule Api.Voting do
  use Api.Web, :action

  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Competitions.Category
  alias Api.Teams.Team
  alias Api.Voting
  alias Api.Voting.{Vote, PaperVote}
  alias Ecto.{Multi, Changeset}

  def upsert_votes(user, votes) do
    multi = Multi.new()

    votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc -> acc + length(ballot) end)

    valid_votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc ->
      if validate_ballot(ballot, user), do: acc + length(ballot), else: acc
    end)

    if votes_length != valid_votes_length do
      throw {:error, "Invalid vote"}
    end

    if Competitions.voting_status == :not_started do
      throw {:error, :not_started}
    end
    if Competitions.voting_status == :ended do
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
    at = Competitions.voting_started_at()

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
    begun_at = Competitions.voting_started_at()
    ended_at = Competitions.voting_ended_at()
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
          Voting.ballots(c, ended_at),
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

  def ballots(category, at \\ nil) do
    at = at || DateTime.utc_now

    votes =
      Repo.all(from(
        u in User.able_to_vote(at),
        join: v in assoc(u, :votes),
        where: v.category_id == ^(category.id),
        select: v,
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

  def unredeemed_paper_votes do
    paper_votes = from pv in PaperVote,
      where: is_nil(pv.redeemed_at) and is_nil(pv.annulled_at),
      preload: [:category]

      Repo.all(paper_votes)
  end

  def get_paper_vote(id) do
    Repo.get!(PaperVote, id)
    |> Repo.preload(:category)
  end

  def create_paper_vote(category, admin) do
    case Competitions.voting_status do
      :ended -> :already_ended
      _ ->
        {
          :ok,
          %PaperVote{}
          |> PaperVote.changeset(%{
            category_id: category.id,
            created_by_id: admin.id,
          })
          |> Repo.insert!
          |> Repo.preload(:category)
        }
    end
  end

  def redeem_paper_vote(paper_vote, team, member, admin, at \\ nil) do
    at = at || DateTime.utc_now

    cond do
      !team.eligible -> :team_not_eligible
      team.disqualified_at -> :team_disqualified
      paper_vote.redeemed_at -> :already_redeemed
      paper_vote.annulled_at -> :annulled
      Competitions.voting_status == :not_started -> :not_started
      Competitions.voting_status == :ended -> :already_ended
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
          |> Repo.preload(:category)
        }
    end
  end

  def annul_paper_vote(paper_vote, admin, at \\ nil) do
    at = at || DateTime.utc_now

    case Competitions.voting_status do
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
          |> Repo.preload(:category)
        }
    end
  end
end
