defmodule ApiWeb.ChangesetView do
  use Api.Web, :view

  alias Ecto.Changeset

  def render("error.json", %{changeset: changeset}) do
    %{
      errors: Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    }
  end
end
