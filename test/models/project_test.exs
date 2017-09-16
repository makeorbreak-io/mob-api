defmodule ApiWeb.ProjectTest do
  use ApiWeb.ModelCase

  alias ApiWeb.Project

  @valid_attrs %{
    description: "some content",
    name: "some content",
    technologies: ["elixir", "ruby"]
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Project.changeset(%Project{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = Project.changeset(%Project{})
    refute changeset.valid?
  end
end
