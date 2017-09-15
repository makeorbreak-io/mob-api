defmodule ApiWeb.TeamMemberTest do
  use ApiWeb.ModelCase

  alias ApiWeb.{TeamMember}

  @valid_attrs %{user_id: Ecto.UUID.generate(), team_id: Ecto.UUID.generate()}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = TeamMember.changeset(%TeamMember{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = TeamMember.changeset(%TeamMember{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = TeamMember.changeset(%TeamMember{})
    refute changeset.valid?
  end
end
