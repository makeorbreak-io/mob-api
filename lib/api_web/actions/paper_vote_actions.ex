defmodule ApiWeb.PaperVoteActions do
  use Api.Web, :action

  alias ApiWeb.{CompetitionActions, PaperVote}

  def create(category, admin) do
    case CompetitionActions.voting_status do
      :ended -> {:error, :already_ended}
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

  def redeem(paper_vote, team, member, admin, at \\ nil) do
    at = at || DateTime.utc_now

    cond do
      !team.eligible -> {:error, :team_not_eligible}
      team.disqualified_at -> {:error, :team_disqualified}
      paper_vote.redeemed_at -> {:error, :already_redeemed}
      paper_vote.annulled_at -> {:error, :annulled}
      CompetitionActions.voting_status == :not_started -> {:error, :not_started}
      CompetitionActions.voting_status == :ended -> {:error, :already_ended}
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

  def annul(paper_vote, admin, at \\ nil) do
    at = at || DateTime.utc_now

    case CompetitionActions.voting_status do
      :ended -> {:error, :already_ended}
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
