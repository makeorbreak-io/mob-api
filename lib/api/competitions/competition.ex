defmodule Api.Competitions.Competition do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Suffrages.Suffrage

  @valid_attrs ~w(
    name
    status
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "competitions" do
    field :name, :string
    # Enum - "created", "started", "ended"
    field :status, :string, default: "created"

    has_many :suffrages, Suffrage
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
  end
end
