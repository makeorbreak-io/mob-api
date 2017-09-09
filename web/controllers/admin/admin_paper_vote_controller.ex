defmodule Api.Admin.PaperVoteController do
  use Api.Web, :controller

  alias Api.{PaperVoteActions, Controller.Errors, Category, PaperVote, User, Team, SessionActions}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  defp _respond(conn, {:ok, pv}) do
    render(conn, "paper_vote.json", paper_vote: pv)
  end
  defp _respond(conn, {:error, cause}) do
    Errors.build(conn, :unprocessable_entity, cause)
  end

  def create(conn, %{"category_name" => c_name}) do
    _respond(conn, PaperVoteActions.create(
      Repo.get_by!(Category, name: c_name),
      SessionActions.current_user(conn)
    ))
  end

  def show(conn, %{"id" => pv_id}) do
    _respond(conn, {:ok,
      Repo.get!(PaperVote, pv_id)
      |> Repo.preload(:category)
    })
  end

  def redeem(conn, %{"id" => pv_id, "team_id" => t_id, "member_id" => m_id}) do
    _respond(conn, PaperVoteActions.redeem(
      Repo.get!(PaperVote, pv_id),
      Repo.get!(Team, t_id),
      Repo.get!(User, m_id),
      SessionActions.current_user(conn)
    ))
  end

  def annul(conn, %{"id" => pv_id}) do
    _respond(conn, PaperVoteActions.annul(
      Repo.get!(PaperVote, pv_id),
      SessionActions.current_user(conn)
    ))
  end
end
