defmodule Api.Project do
  @moduledoc """
    TODO: Write.
  """
  use Api.Web, :model

  @valid_attrs ~w(name team_name description technologies user_id)
  @required_attrs ~w(name)a

  schema "projects" do
    field :name, :string
    field :team_name, :string
    field :description, :string
    field :technologies, :string

    timestamps()

    # Relationships
    belongs_to :user, Api.User
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
