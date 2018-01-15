defmodule Api.Competitions.Competition do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_attrs ~w(
    name
    status
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "competitions" do
    field :name, :string
    field :status, :string, default: "created"
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
  end
end
