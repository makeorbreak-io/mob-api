defmodule Api.Vote do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model

  alias Api.{Category}

  @required_attrs [
    :voter_identity,
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
    |> cast(params, @required_attrs)
    |> put_assoc(:category, params.category)
    |> validate_required(@required_attrs)
  end
end
