defmodule Api.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Api.Teams.{Team, Membership, Invite}
  alias Api.Competitions.Competition

  @valid_attrs ~w(
    name
    applied
    project_name
    project_desc
    technologies
    competition_id
  )a

  @admin_attrs @valid_attrs ++ ~w(repo accepted)a

  @required_attrs ~w(
    name
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams" do
    field :name, :string
    field :repo, :map
    field :applied, :boolean, default: false
    field :accepted, :boolean, default: false
    field :project_name, :string
    field :project_desc, :string
    field :technologies, {:array, :string}

    timestamps()

    # Associations
    has_many :invites, Invite, on_delete: :delete_all
    has_many :memberships, Membership, foreign_key: :team_id, on_delete: :delete_all
    has_many :members, through: [:memberships, :user]
    belongs_to :competition, Competition
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, repo), do: _cs(struct, params, repo, @valid_attrs)
  def admin_changeset(struct, params, repo), do: _cs(struct, params, repo, @admin_attrs)
  defp _cs(struct, params, repo, attrs) do
    struct
    |> cast(params, attrs)
    |> validate_required(@required_attrs)
  end
end
