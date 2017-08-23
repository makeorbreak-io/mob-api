defmodule Api.Team do
  use Api.Web, :model

  alias Api.{Project, Invite, TeamMember}

  @valid_attrs ~w(name applied)
  @required_attrs ~w(name)a

  schema "teams" do
    field :name, :string
    field :applied, :boolean, default: false
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
    |> validate_required(@required_attrs)
  end
end
