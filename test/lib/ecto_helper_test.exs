defmodule Api.EctoHelperTests do
  use ExUnit.Case, async: true

  alias Api.EctoHelper
  alias Api.{Team}
  alias Ecto.{Changeset}



  defp changeset(o, opts \\ []) do
    Changeset.change(o, opts)
    |> EctoHelper.on_any_present(
      [
        :disqualified_at,
        :disqualified_by_id,
      ],
      [
        &Changeset.validate_required/2,
      ]
    )
  end

  test "on_any_present none" do
    assert changeset(%Team{}).valid?
  end

  test "on_any_present not all" do
    refute changeset(%Team{}, disqualified_at: 1).valid?
  end

  test "on_any_present all" do
    assert changeset(%Team{}, disqualified_at: 1, disqualified_by_id: 1).valid?
  end
end
