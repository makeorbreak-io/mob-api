defmodule Api.Competitions.Attendance do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Competitions.Competition
<<<<<<< HEAD
  alias ApiWeb.{EctoHelper, Crypto}
=======
  alias ApiWeb.Crypto
>>>>>>> Big changes

  @valid_attrs ~w(
    attendee
    competition_id
    checked_in
  )a

  @required_attrs ~w(
    attendee
<<<<<<< HEAD
    voter_identity
=======
>>>>>>> Big changes
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "competition_attendance" do
    field :attendee, :binary_id
    field :checked_in, :boolean, default: false
<<<<<<< HEAD
    field :voter_identity, :string
=======
>>>>>>> Big changes

    belongs_to :competition, Competition

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
<<<<<<< HEAD
    |> EctoHelper.if_missing(:voter_identity, Crypto.random_hmac())
    |> validate_required(@required_attrs)
    |> unique_constraint(:voter_identity)
=======
    |> validate_required(@required_attrs)
>>>>>>> Big changes
    |> unique_constraint(:attendee_competition_id)
  end
end
