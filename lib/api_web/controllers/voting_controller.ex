defmodule ApiWeb.VotingController do
  use Api.Web, :controller

  alias Api.Accounts
  alias Api.Competitions
  alias Api.Voting
  alias ApiWeb.{ErrorController, VotingView}

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorController]
    when action in [:upsert_votes, :get_votes]

  def info_begin(conn, _params) do
    case Competitions.voting_status do
      :not_started ->
        ErrorController.call(conn, {:not_started, :not_found})
      _ ->
        render(conn, VotingView, "info_begin.json", Voting.build_info_start())
    end
  end

  def info_end(conn, _params) do
    case Competitions.voting_status do
      :not_started ->
        ErrorController.call(conn, {:not_started, :not_found})
      :started ->
        ErrorController.call(conn, {:not_ended, :not_found})
      :ended ->
        render(conn, VotingView, "info_end.json", Voting.build_info_end())
    end
  end

  def upsert_votes(conn, %{"votes" => votes}) do
    case Voting.upsert_votes(Plug.current_resource(conn), votes) do
      {:ok, votes} -> render(conn, "upsert.json", votes: votes)
      {:error, error} -> ErrorController.call(conn, error)
    end
  end

  def get_votes(conn, _) do
    case Voting.get_votes(Plug.current_resource(conn)) do
      {:ok, votes} -> render(conn, "index.json", votes: votes)
      {:error, error} -> ErrorController.call(conn, error)
    end
  end
end
