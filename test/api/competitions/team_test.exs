defmodule Api.TeamTest do
  use Api.DataCase

  alias Api.Competitions.Team
  alias Ecto.Changeset

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

  test "changeset with private attributes" do
    changeset = Team.changeset(%Team{}, %{"eligible" => true}, Repo)
    :error = Changeset.fetch_change(changeset, :eligible)
  end

  test "admin_changeset with private attributes" do
    changeset = Team.admin_changeset(%Team{}, %{"eligible" => true}, Repo)
    {:ok, _} = Changeset.fetch_change(changeset, :eligible)
  end

  test "tie_breaker is sequential" do
    first = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))
    assert first.tie_breaker == 1

    second = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))
    assert second.tie_breaker == 2
  end

  test "tie_breaker doesn't break if team is deleted" do
    first = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))
    Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))

    Repo.delete(first)

    third = Repo.insert!(Team.changeset(%Team{}, @valid_attrs, Repo))

    assert third.tie_breaker == 3
  end
end
