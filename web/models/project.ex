defmodule Api.Project do
  @moduledoc """
    TODO: Write.
  """
  use Api.Web, :model

  @valid_attrs ~w(name description technologies repo server completed_at team_id)
  @required_attrs ~w(name)a

  schema "projects" do
    field :name, :string
    field :description, :string
    field :technologies, {:array, :string}
    field :repo, :string
    field :server, :string
    field :completed_at, Ecto.DateTime
    timestamps()

    # Associations
    belongs_to :team, Api.Team
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
