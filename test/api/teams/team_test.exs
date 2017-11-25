defmodule Api.TeamTest do
  use Api.DataCase

  alias Api.Teams.Team
  alias Ecto.Changeset

  @valid_attrs %{name: "awesome team"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    c = create_competition()
    changeset = Team.changeset(
      %Team{},
      Map.merge(@valid_attrs, %{competition_id: c.id}),
      Repo
    )
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
    changeset = Team.changeset(%Team{}, %{"accepted" => true}, Repo)
    :error = Changeset.fetch_change(changeset, :accepted)
  end

  test "admin_changeset with private attributes" do
    changeset = Team.admin_changeset(%Team{}, %{"accepted" => true}, Repo)
    {:ok, _} = Changeset.fetch_change(changeset, :accepted)
  end

  # test "tie_breaker is sequential" do
  #   c = create_competition()
  #   first = Repo.insert!(Team.changeset(
  #     %Team{},
  #     Map.merge(@valid_attrs, %{competition_id: c.id}),
  #     Repo)
  #   )
  #   assert first.tie_breaker == 1

  #   second = Repo.insert!(Team.changeset(
  #     %Team{},
  #     Map.merge(@valid_attrs, %{competition_id: c.id}),
  #     Repo)
  #   )
  #   assert second.tie_breaker == 2
  # end
end
