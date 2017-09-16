defmodule ApiWeb.CompetitionTest do
  use ApiWeb.ModelCase

  alias ApiWeb.Competition

  @valid_attrs %{
  }

  test "changeset with valid attributes" do
    changeset = Competition.changeset(%Competition{}, @valid_attrs)
    assert changeset.valid?
  end
end
