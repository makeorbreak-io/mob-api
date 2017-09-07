defmodule Api.Workshop do
  use Api.Web, :model

  alias Api.{WorkshopAttendance}

  @valid_attrs ~w(name slug summary description speaker participant_limit
    year speaker_image banner_image short_date short_speaker)
  @required_attrs ~w(name slug)a

  @derive {Phoenix.Param, key: :slug}

  schema "workshops" do
    field :name, :string
    field :slug, :string
    field :summary, :string
    field :description, :string
    field :speaker, :string
    field :participant_limit, :integer
    field :year, :integer
    field :speaker_image, :string
    field :banner_image, :string
    field :short_speaker, :string
    field :short_date, :string
    timestamps()

    has_many :attendances, WorkshopAttendance, foreign_key: :workshop_id, on_delete: :delete_all
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
