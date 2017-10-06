defmodule Api.Competitions do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Competitions.Competition
  alias Api.Teams
  alias Api.Voting

  def start_voting do
    case voting_status() do
      :not_started ->
        Teams.shuffle_tie_breakers
        Teams.assign_missing_preferences
        _change_competition(%{voting_started_at: DateTime.utc_now})
      :started -> :already_started
      :ended -> :already_ended
    end
  end

  def end_voting do
    case voting_status() do
      :not_started -> :not_started
      :started ->
        at = DateTime.utc_now
        Voting.resolve_voting!(at)
        _change_competition(%{voting_ended_at: at})
      :ended -> :already_ended
    end
  end

  def voting_status do
    c = _get_competition()
    now = DateTime.utc_now

    cond do
      c.voting_ended_at && DateTime.compare(c.voting_ended_at, now) == :lt -> :ended
      c.voting_started_at && DateTime.compare(c.voting_started_at, now) == :lt -> :started
      true -> :not_started
    end
  end

  def voting_started_at do
    _get_competition().voting_started_at
  end

  def voting_ended_at do
    _get_competition().voting_ended_at
  end

  def status do
    %{
      voting_status: voting_status(),
      unredeemed_paper_votes: Voting.unredeemed_paper_votes(),
      missing_voters: Voting.missing_voters(),
    }
  end

  defp _get_competition do
    Repo.one(from(c in Competition)) || %Competition{}
  end

  defp _change_competition(params) do
    _get_competition()
    |> Competition.changeset(params)
    |> Repo.insert_or_update
  end
end
