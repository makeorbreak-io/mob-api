defmodule ApiWeb.Team do
  use Api.Web, :model

  alias ApiWeb.{EctoHelper, Crypto, Invite, TeamMember, User, Team}

  @valid_attrs ~w(
    name
    applied
    prize_preference
    project_name
    project_desc
    technologies
  )a

  @admin_attrs @valid_attrs ++ ~w(eligible repo)a

  @required_attrs ~w(
    name
    prize_preference_hmac_secret
    tie_breaker
  )a

  schema "teams" do
    field :name, :string
    field :repo, :map
    field :applied, :boolean, default: false
    field :eligible, :boolean, default: false
    field :disqualified_at, :utc_datetime, default: nil
    field :prize_preference, {:array, :string}
    field :prize_preference_hmac_secret, :string
    field :tie_breaker, :integer
    field :project_name, :string
    field :project_desc, :string
    field :technologies, {:array, :string}

    timestamps()

    # Associations
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
    repo.aggregate(Team, :count, :id) + 1
  end

  def preference_hmac(team) do
    Crypto.hmac(
      team.prize_preference_hmac_secret,
      Enum.join(team.prize_preference || [], ",")
    )
  end

  def votable(at \\ nil) do
    at = at || DateTime.utc_now

    from(
      t in __MODULE__,
      where: t.eligible == true,
      where: is_nil(t.disqualified_at) or t.disqualified_at > ^at,
    )
  end
end