defmodule Api.Suffrages.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Suffrages.Suffrage

  @valid_attrs ~w(
    name
  )a

  @required_attrs ~w(
    name
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "categories" do
    field :name, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:name)
  end
end
