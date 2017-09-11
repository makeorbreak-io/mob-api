defmodule Api.VotingController do
  use Api.Web, :controller

  alias Api.{Controller.Errors, CompetitionActions, VotingView,
    Repo, User, PaperVote, Team, VoteActions, SessionActions, Category}

  plug Guardian.Plug.EnsureAuthenticated, [handler: Errors]
    when action in [:upsert_votes, :get_votes]

  def info_begin(conn, _params) do
    case CompetitionActions.voting_status do
      :not_started ->
        Errors.build(conn, :not_found, :not_started)
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

  def info_end(conn, _params) do
    case CompetitionActions.voting_status do
      :not_started ->
        Errors.build(conn, :not_found, :not_started)
      :started ->
        Errors.build(conn, :not_found, :not_ended)
      _ ->
        begun_at =
          CompetitionActions.voting_started_at()
        ended_at =
          CompetitionActions.voting_ended_at()
        categories =
          Repo.all(Category)
        map_team_id_name =
          Repo.all(Team)
          |> Map.new(&{&1.id, &1.name})

        render(conn, VotingView, "info_end.json",
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
          teams:
            Team.votable(begun_at)
            |> Repo.all,
          categories:
            categories,
          votes:
            categories
            |> Map.new(fn c ->
              {
                c.name,
                CompetitionActions.ballots(c, ended_at)
                |> Map.new(fn {id, ballot} ->
                  {
                    id,
                    ballot
                    |> Enum.map(&Map.get(map_team_id_name, &1)),
                  }
                end)
              }
            end)
        )
    end
  end

  def upsert_votes(conn, %{"votes" => votes}) do
    case VoteActions.upsert_votes(SessionActions.current_user(conn), votes) do
      {:ok, votes} -> render(conn, "upsert.json", votes: votes)
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end

  def get_votes(conn, _) do
    case VoteActions.get_votes(SessionActions.current_user(conn)) do
      {:ok, votes} -> render(conn, "index.json", votes: votes)
      {:error, error} -> Errors.build(conn, :unprocessable_entity, error)
    end
  end
end
