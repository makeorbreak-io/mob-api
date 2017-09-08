defmodule Api.Competition do
  use Api.Web, :model

  @valid_attrs ~w(
    voting_started_at
    voting_ended_at
  )a

  schema "competition" do
    field :voting_started_at, :utc_datetime
    field :voting_ended_at, :utc_datetime
  end

  defp _cant_change(%Ecto.Changeset{changes: changes, data: data} = changeset, field) do
    with {:ok, old} <- Map.fetch(data, field),
         {:ok, new} <- Map.fetch(changes, field),
         true <- old != nil,
         true <- old != new
    do
      add_error(changeset, field, "can't be changed")
    else
      _ -> changeset
    end
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> _cant_change(:voting_started_at)
    |> _cant_change(:voting_ended_at)
  end
end
