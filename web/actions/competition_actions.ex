defmodule Api.CompetitionActions do
  use Api.Web, :action

  alias Api.{Competition, TeamActions}

  defp _get do
    Repo.one(from(c in Competition)) || %Competition{}
  end

  defp _change(params) do
    _get()
    |> Competition.changeset(params)
    |> Repo.insert_or_update
  end

  def start_voting do
    case voting_status() do
      :not_started ->
        TeamActions.shuffle_tie_breakers
        _change(%{voting_started_at: DateTime.utc_now})
      :started -> {:error, :already_started}
      :ended -> {:error, :already_ended}
    end
  end

  def end_voting do
    case voting_status() do
      :not_started -> {:error, :not_started}
      :started ->
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
end
