defmodule Api.Voting.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
  alias Api.Competitions.Category

  @attrs ~w(
    voter_identity
    category_id
    ballot
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to(
      :voter,
      User,
      foreign_key: :voter_identity,
      references: :voter_identity,
      type: :string,
    )
    belongs_to :category, Category
    field :ballot, {:array, :binary_id}
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@attrs)
    |> unique_constraint(:voter_identity_category_id)
    |> assoc_constraint(:voter)
    |> assoc_constraint(:category)
  end
end
