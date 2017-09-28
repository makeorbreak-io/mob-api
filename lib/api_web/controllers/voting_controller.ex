defmodule ApiWeb.VotingController do
  use Api.Web, :controller

  alias Api.Accounts
  alias ApiWeb.{ErrorController, CompetitionActions, VotingView,
    VoteActions}

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController]
    when action in [:upsert_votes, :get_votes]

  def info_begin(conn, _params) do
    case CompetitionActions.voting_status do
      :not_started ->
        ErrorController.call(conn, {:not_started, :not_found})
      _ ->
        render(conn, VotingView, "info_begin.json", VoteActions.build_info_start())
    end
  end

  def info_end(conn, _params) do
    case CompetitionActions.voting_status do
      :not_started ->
        ErrorController.call(conn, {:not_started, :not_found})
      :started ->
        ErrorController.call(conn, {:not_ended, :not_found})
      :ended ->
        render(conn, VotingView, "info_end.json", VoteActions.build_info_end())
    end
  end

  def upsert_votes(conn, %{"votes" => votes}) do
    case VoteActions.upsert_votes(Accounts.current_user(conn), votes) do
      {:ok, votes} -> render(conn, "upsert.json", votes: votes)
      {:error, error} -> ErrorController.call(conn, error)
    end
  end

  def get_votes(conn, _) do
    case VoteActions.get_votes(Accounts.current_user(conn)) do
      {:ok, votes} -> render(conn, "index.json", votes: votes)
      {:error, error} -> ErrorController.call(conn, error)
    end
  end
end
