defmodule Api.Project do
  @moduledoc """
    TODO: Write.
  """
  use Api.Web, :model

  @valid_attrs ~w(name team_name description technologies repo server
                  student_team applied_at completed_at user_id)
  @required_attrs ~w(team_name)a

  schema "projects" do
    field :name, :string
    field :team_name, :string
    field :description, :string
    field :technologies, :string
    field :repo, :string
    field :server, :string
    field :student_team, :boolean

    # Timestamps
    field :applied_at, Ecto.DateTime
    field :completed_at, Ecto.DateTime
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
