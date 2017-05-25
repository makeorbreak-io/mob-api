defmodule Api.Invite do
  use Api.Web, :model

  alias Api.{User, Team}

  @valid_attrs ~w(invitee_id team_id host_id description accepted open)

  schema "invites" do
    field :open, :boolean, default: false
    field :accepted, :boolean, default: false
    field :description, :string
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
  end
end
