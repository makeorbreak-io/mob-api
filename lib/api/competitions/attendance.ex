defmodule Api.Competitions.Attendance do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Competitions.Competition
  alias ApiWeb.Crypto

  @valid_attrs ~w(
    attendee
    competition_id
    checked_in
  )a

  @required_attrs ~w(
    attendee
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "competition_attendance" do
    field :attendee, :binary_id
    field :checked_in, :boolean, default: false

    belongs_to :competition, Competition

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:attendee_competition_id)
  end
end
