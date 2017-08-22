defmodule Api.Team do
  use Api.Web, :model

  alias Api.{User, Project, Invite, TeamMember}

  @valid_attrs ~w(name user_id applied)
  @required_attrs ~w(name)a

  schema "teams" do
    field :name, :string
    field :applied, :boolean, default: false
    timestamps()

    # Associations
    belongs_to :owner, User, foreign_key: :user_id
    has_one :project, Project
    has_many :invites, Invite

    many_to_many :members, User, join_through: TeamMember
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
