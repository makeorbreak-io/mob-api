defmodule Api.TeamTest do
  use Api.ModelCase

  alias Api.Team

  @valid_attrs %{name: "awesome team"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Team.changeset(%Team{}, @valid_attrs, Repo)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Team.changeset(%Team{}, @invalid_attrs, Repo)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = Team.changeset(%Team{}, %{}, Repo)
    refute changeset.valid?
  end

  test "tie_breaker is sequential" do
    first = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))
    assert first.tie_breaker == 1

    second = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))
    assert second.tie_breaker == 2
  end
end
