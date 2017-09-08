defmodule Api.Vote do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model

  alias Api.{Category, User}

  @attrs [
    :voter_identity,
    :category_id,
    :ballot,
  ]

  schema "votes" do
    belongs_to(
      :voter,
      User,
      foreign_key: :voter_identity,
      references: :voter_identity,
      type: :string,
    )
    belongs_to :category, Category
    field :ballot, {:array, :string}
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@attrs)
    |> unique_constraint(:voter_identity)
    |> assoc_constraint(:voter)
    |> assoc_constraint(:category)
  end
end
