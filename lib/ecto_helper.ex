defmodule Api.EctoHelper do
  alias Ecto.{Changeset}

  def if_missing(changeset, field, value) do
    if Changeset.get_field(changeset, field) do
      changeset
    else
      Changeset.put_change(changeset, field, value)
    end
  end

  def validate_xor_change(changeset, fields) do
    presence_count =
      fields
      |> Enum.map(&Changeset.fetch_change(changeset, &1))
      |> Enum.reject(&(&1 == :error))
      |> Enum.count

    case presence_count do
      0 -> changeset
      _ -> Changeset.validate_required(changeset, fields)
    end
  end
end
