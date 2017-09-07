defmodule Api.Team do
  use Api.Web, :model

  alias Api.{EctoHelper, Crypto, Project, Invite, TeamMember}

  @valid_attrs ~w(name applied prize_preference)
  @admin_attrs @valid_attrs ++ ~w(eligible)
  @required_attrs ~w(name prize_preference_hmac_secret tie_breaker)a

  schema "teams" do
    field :name, :string
    field :applied, :boolean, default: false
    field :eligible, :boolean, default: false
    field :disqualified_at, :utc_datetime, default: nil
    field :prize_preference, {:array, :string}
    field :prize_preference_hmac_secret, :string
    field :tie_breaker, :integer
    timestamps()

    # Associations
    has_one :project, Project, on_delete: :delete_all
    has_many :invites, Invite, on_delete: :delete_all
    has_many :members, TeamMember, foreign_key: :team_id, on_delete: :delete_all
    belongs_to :disqualified_by, User
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, repo), do: _cs(struct, params, repo, @valid_attrs)
  def admin_changeset(struct, params, repo), do: _cs(struct, params, repo, @admin_attrs)
  defp _cs(struct, params, repo, attrs) do
    struct
    |> cast(params, attrs)
    |> EctoHelper.if_missing(:tie_breaker, generate_tie_breaker(repo))
    |> EctoHelper.if_missing(:prize_preference_hmac_secret, Crypto.random_hmac())
    |> validate_required(@required_attrs)
    |> unique_constraint(:tie_breaker)
    |> unique_constraint(:prize_preference_hmac_secret)
    |> EctoHelper.on_any_present(
      [
        :disqualified_at,
        :disqualified_by_id,
      ],
      [
        &validate_required/2,
        &assoc_constraint(&1, :disqualified_by),
      ]
    )
  end

  defp generate_tie_breaker(repo) do
    repo.aggregate(Api.Team, :count, :id) + 1
  end
end
