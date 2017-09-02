defmodule Api.PaperVoteTest do
  use Api.ModelCase

  alias Api.PaperVote

  setup %{} do
    user = create_user()
    admin = create_admin()
    category = create_category()
    team = create_team(user)
    {:ok, %{
      user: user,
      admin: admin,
      category: category,
      team: team,
      base_attrs: %{
        hmac_secret: "you'll never guess me",
        category: category,
        created_by: admin,
      }
    }}
  end

  test "changeset create", %{base_attrs: base_attrs} do
    assert PaperVote.creation_changeset(%PaperVote{}, base_attrs).valid?
  end

  test "changeset redeem", %{base_attrs: base_attrs, user: user, team: team, admin: admin} do
    assert PaperVote.redemption_changeset(%PaperVote{}, Map.merge(base_attrs, %{
      redeemed_at: DateTime.utc_now(),
      redeeming_admin: admin,
      redeeming_member: user,
      team: team,
    })).valid?
  end

  test "changeset annul", %{base_attrs: base_attrs, admin: admin} do
    assert PaperVote.annulment_changeset(%PaperVote{}, Map.merge(base_attrs, %{
      annulled_at: DateTime.utc_now(),
      annulled_by: admin,
    })).valid?
  end
end
