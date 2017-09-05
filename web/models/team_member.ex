defmodule Api.TeamMember do
  use Api.Web, :model

  alias Api.{User, Team}

  @primary_key false

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
