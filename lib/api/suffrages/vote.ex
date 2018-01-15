defmodule Api.Suffrages.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Suffrages.Suffrage

  @attrs ~w(
    voter_identity
    suffrage_id
    ballot
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to :suffrage, Suffrage
    field :voter_identity, :string

    field :ballot, {:array, :binary_id}
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@attrs)
    |> assoc_constraint(:suffrage)
  end
end
