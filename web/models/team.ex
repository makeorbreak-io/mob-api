defmodule Api.Team do
  use Api.Web, :model

  @valid_attrs ~w(name user_id)
  @required_attrs ~w(name)a

  schema "teams" do
    field :name, :string
    timestamps()

    # Associations
    belongs_to :user, Api.User
    has_one :project, Api.Project
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
