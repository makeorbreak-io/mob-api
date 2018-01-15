defmodule Api.CategoryTest do
  use Api.DataCase

  alias Api.Suffrages.Category

  @valid_attrs %{
    name: "some name"
  }

  test "insertable" do
    Category.changeset(%Category{}, @valid_attrs) |> Repo.insert!
  end

  test "no name duplicates" do
    Category.changeset(%Category{}, @valid_attrs) |> Repo.insert!

    assert_raise Ecto.InvalidChangesetError, fn ->
      Category.changeset(%Category{}, @valid_attrs) |> Repo.insert!
    end
  end
end
