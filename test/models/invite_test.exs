defmodule Api.InviteTest do
  use Api.ModelCase

  alias Api.Invite

  @valid_attrs %{accepted: false, description: "some content", open: false}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Invite.changeset(%Invite{}, @valid_attrs)
    assert changeset.valid?
  end
end
