defmodule Api.PaperVoteActions do
  use Api.Web, :action

  alias Api.{PaperVote, User}

  def create(category, admin) do
    %PaperVote{}
    |> PaperVote.changeset(%{
      category_id: category.id,
      created_by_id: admin.id,
    })
    |> Repo.insert!
  end

  def annul(paper_vote, admin, at \\ nil) do
    at = at || DateTime.utc_now

    %User{role: "admin"} = admin = Repo.get!(User, admin.id)

    paper_vote
    |> PaperVote.changeset(%{
      annulled_at: at,
      annulled_by_id: admin.id,
    })
    |> Repo.update!
  end
end
