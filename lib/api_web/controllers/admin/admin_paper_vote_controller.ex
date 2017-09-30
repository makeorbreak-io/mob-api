defmodule ApiWeb.Admin.PaperVoteController do
  use Api.Web, :controller

  alias Api.{Accounts, Accounts.User}
  alias Api.{Competitions.Category, Competitions.Team}
  alias Api.{Voting, Voting.PaperVote}
  alias ApiWeb.ErrorController
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  action_fallback ErrorController

  plug EnsureAuthenticated, [handler: ErrorController]
  plug EnsurePermissions, [handler: ErrorController, admin: ~w(full)]

  def create(conn, %{"category_name" => c_name}) do
    category = Repo.get_by!(Category, name: c_name)
    user = Accounts.current_user(conn)

    with {:ok, pv} <- Voting.create_paper_vote(category, user),
      do: render(conn, "paper_vote.json", paper_vote: pv)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "paper_vote.json", paper_vote: Voting.get_paper_vote(id))
  end

  def redeem(conn, %{"id" => pv_id, "team_id" => t_id, "member_id" => m_id}) do
    pv = Repo.get!(PaperVote, pv_id)
    team = Repo.get!(Team, t_id)
    member = Repo.get!(User, m_id)
    user = Accounts.current_user(conn)

    with {:ok, pv} <- Voting.redeem_paper_vote(pv, team, member, user),
      do: render(conn, "paper_vote.json", paper_vote: pv)
  end

  def annul(conn, %{"id" => pv_id}) do
    pv = Repo.get!(PaperVote, pv_id)
    user = Accounts.current_user(conn)

    with {:ok, pv} <- Voting.annul_paper_vote(pv, user),
      do: render(conn, "paper_vote.json", paper_vote: pv)
  end
end
