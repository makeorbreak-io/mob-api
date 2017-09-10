defmodule Api.PaperVote do
  use Api.Web, :model

  alias Api.{Team, Category, User}
  alias Api.EctoHelper

  @required_attrs [
    :category_id,
    :created_by_id,
  ]

  @valid_attrs [
    :category_id,
    :created_by_id,
    :redeemed_at,
    :redeeming_admin_id,
    :redeeming_member_id,
    :team_id,
    :annulled_at,
    :annulled_by_id,
  ]

  schema "paper_votes" do
    belongs_to :category, Category
    belongs_to :created_by, User

    field :redeemed_at, :utc_datetime
    belongs_to :redeeming_admin, User
    belongs_to :redeeming_member, User
    belongs_to :team, Team

    field :annulled_at, :utc_datetime
    belongs_to :annulled_by, User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> assoc_constraint(:category)
    |> assoc_constraint(:created_by)
    |> EctoHelper.on_any_present(
      [
        :redeemed_at,
        :redeeming_admin_id,
        :redeeming_member_id,
        :team_id,
      ],
      [
        &validate_required/2,
        &assoc_constraint(&1, :redeeming_admin),
        &assoc_constraint(&1, :redeeming_member),
        &assoc_constraint(&1, :team)
      ]
    )
    |> EctoHelper.on_any_present(
      [
        :annulled_by_id,
        :annulled_at,
      ],
      [
        &validate_required/2,
        &assoc_constraint(&1, :annulled_by)
      ]
    )
  end

  def not_annuled(at \\ nil) do
    at = at || DateTime.utc_now

    from(
      p in Api.PaperVote,
      where: is_nil(p.annulled_at) or p.annulled_at > ^at,
    )
  end

  def countable(at \\ nil) do
    at = at || DateTime.utc_now

    from(
      pv in not_annuled(at),
      where: not is_nil(pv.team_id)
    )
  end
end
