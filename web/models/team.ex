defmodule Api.Team do
  use Api.Web, :model

  alias Api.{User, Project, Invite}

  @valid_attrs ~w(name user_id)
  @required_attrs ~w(name)a

  schema "teams" do
    field :name, :string
    timestamps()

    # Associations
    belongs_to :owner, User, foreign_key: :user_id
    has_one :project, Project
    has_many :invites, Invite

    many_to_many :users, User, join_through: "users_teams"
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
  end
end
