defmodule Api.Competitions.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
  alias Api.Competitions.Team

  @primary_key false
  @foreign_key_type :binary_id
  schema "users_teams" do
    field :role, :string, default: "member"

    belongs_to :user, User
    belongs_to :team, Team
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
  end
end
