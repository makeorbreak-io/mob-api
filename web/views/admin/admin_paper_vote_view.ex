defmodule Api.Admin.PaperVoteView do
  use Api.Web, :view

  def render("paper_vote.json", %{paper_vote: pv}) do
    Map.take(pv, [
      :id,
      :annulled_at,
      :annulled_by_id,
      :category_id,
      :created_by_id,
      :redeemed_at,
      :redeeming_admin_id,
      :redeeming_member_id,
      :team_id,
    ])
    |> Map.merge(%{category_name: pv.category.name})
  end
end
