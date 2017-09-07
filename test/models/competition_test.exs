defmodule Api.CompetitionTest do
  use Api.ModelCase

  alias Api.Competition

  @valid_attrs %{
  }

  test "changeset with valid attributes" do
    changeset = Competition.changeset(%Competition{}, @valid_attrs)
    assert changeset.valid?
  end
end
