defmodule Api.PaperVote do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model

  alias Api.{Crypto, Team, Category, User}
  alias Api.EctoHelper

  @required_attrs [
    :hmac_secret,
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
    field :hmac_secret, :string
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

  def hmac(paper_vote) do
    Crypto.hmac(paper_vote.hmac_secret, paper_vote.id)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> EctoHelper.if_missing(:hmac_secret, Crypto.random_hmac())
    |> validate_required(@required_attrs)
    |> EctoHelper.validate_xor_change([
      :redeemed_at,
      :redeeming_admin_id,
      :redeeming_member_id,
      :team_id,
    ])
    |> EctoHelper.validate_xor_change([
      :annulled_by_id,
      :annulled_at,
    ])
  end
end