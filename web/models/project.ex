defmodule Api.Project do
  use Api.Web, :model

  schema "projects" do
    field :name, :string
    field :description, :string
    field :technologies, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description, :technologies])
    |> validate_required([:name, :description, :technologies])
  end
end
