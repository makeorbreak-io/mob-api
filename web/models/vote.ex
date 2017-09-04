defmodule Api.Vote do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model

  alias Api.{Category}

  @attrs [
    :voter_identity,
    :category_id,
    :ballot,
  ]

  schema "votes" do
    field :voter_identity, :string
    belongs_to :category, Category
    field :ballot, {:array, :string}
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@attrs)
  end
end
