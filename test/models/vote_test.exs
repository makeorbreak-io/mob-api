defmodule ApiWeb.VoteTest do
  use Api.DataCase

  alias Api.Voting.Vote

  setup %{} do
    {:ok, %{
      category: create_category(),
      team: create_team(create_user()),
    }}
  end

  test "changeset", %{category: category, team: team} do
    assert Vote.changeset(%Vote{}, %{
      voter_identity: "derp",
      category_id: category.id,
      ballot: [team.id],
    }).valid?
  end
end
