defmodule ApiWeb.Invite do
  use Api.Web, :model

  alias ApiWeb.{User, Team}

  @valid_attrs ~w(
    invitee_id
    team_id
    host_id
    description
    open
    email
  )a

  @required_attrs ~w(
    host_id
    team_id
  )a

  schema "invites" do
    field :open, :boolean, default: false
    field :description, :string
    field :email, :string

    belongs_to :invitee, User, foreign_key: :invitee_id
    belongs_to :host, User, foreign_key: :host_id
    belongs_to :team, Team

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:team_id_invitee_id)
  end
end
