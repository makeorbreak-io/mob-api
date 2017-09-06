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

  test "make tie_breaker use the whole number space" do
    (1..100)
    |> Enum.map(fn _ ->
      Team.changeset(%Team{}, @valid_attrs, Repo)
      |> Repo.insert!
    end)
  end

  test "make tie_breaker exhaust the number space" do
    assert_raise RuntimeError, "No tie_breaker options left available", fn ->
      (1..101)
      |> Enum.map(fn _ ->
        Team.changeset(%Team{}, @valid_attrs, Repo)
        |> Repo.insert!
      end)
    end
  end
end
