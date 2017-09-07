defmodule Api.Competition do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model

  @valid_attrs ~w(
    voting_started_at
    voting_ended_at
  )a

  schema "competition" do
    field :voting_started_at, :utc_datetime
    field :voting_ended_at, :utc_datetime
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
  end
end
