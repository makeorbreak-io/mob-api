defmodule Api.EctoHelper do
  alias Ecto.{Changeset}

  def if_missing(changeset, field, value) do
    if Changeset.get_field(changeset, field) do
      changeset
    else
      Changeset.put_change(changeset, field, value)
    end
  end
end
