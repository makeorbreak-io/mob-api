defmodule Api.VotingController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, CompetitionActions, VotingView, Repo, User, PaperVote, Team}

  def info_begin(conn, _params) do
    case CompetitionActions.voting_status do
      :not_started ->
        Errors.build(conn, :not_found, "Voting hasn't started yet")
      _ ->
        at = CompetitionActions.voting_started_at()
        render(conn, VotingView, "info_begin.json",
          participants: %{
            initial_count: Repo.aggregate(User.able_to_vote(at), :count, :id),
          },
          paper_votes: %{
            initial_count: Repo.aggregate(PaperVote.not_annuled(at), :count, :id),
          },
          teams: Team.votable(at) |> Repo.all
        )
    end
  end
end
