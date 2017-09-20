defmodule ApiWeb.BlogPost do
  use Api.Web, :model

  alias ApiWeb.{User}

  @valid_attrs ~w(title slug content category published_at banner_image)
  @required_attrs ~w(title slug)a

  @derive {Phoenix.Param, key: :slug}

  schema "blogposts" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :category, :string
    field :banner_image, :string
    field :published_at, :utc_datetime

    timestamps()

    belongs_to :user, User
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
