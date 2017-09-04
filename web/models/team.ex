defmodule Api.Team do
  use Api.Web, :model

  alias Api.{EctoHelper, Crypto, Project, Invite, TeamMember}

  @valid_attrs ~w(name applied prize_preference)
  @required_attrs ~w(name prize_preference_hmac_secret tie_breaker)a

  schema "teams" do
    field :name, :string
    field :applied, :boolean, default: false
    field :prize_preference, {:array, :string}
    field :prize_preference_hmac_secret, :string
    field :tie_breaker, :integer
    timestamps()

    # Associations
    has_one :project, Project, on_delete: :delete_all
    has_many :invites, Invite, on_delete: :delete_all
    has_many :members, TeamMember, foreign_key: :team_id, on_delete: :delete_all
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> EctoHelper.if_missing(:tie_breaker, round(:rand.uniform() * 100))
    |> EctoHelper.if_missing(:prize_preference_hmac_secret, Crypto.random_hmac())
    |> validate_required(@required_attrs)
  end
end
