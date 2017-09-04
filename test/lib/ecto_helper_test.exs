defmodule Api.EctoHelperTests do
  use ExUnit.Case, async: true

  alias Api.EctoHelper
  alias Api.{Team}
  alias Ecto.{Changeset}

  test "validate_xor_change none" do
    assert (
      Changeset.change(%Team{})
      |> EctoHelper.validate_xor_change([
        :disqualified_at,
        :disqualified_by_id,
      ])
    ).valid?
  end

  test "validate_xor_change not all" do
    refute (
      Changeset.change(%Team{}, disqualified_at: 1)
      |> EctoHelper.validate_xor_change([
        :disqualified_at,
        :disqualified_by_id,
      ])
    ).valid?
  end

  test "validate_xor_change all" do
    assert (
      Changeset.change(%Team{}, disqualified_at: 1, disqualified_by_id: 1)
      |> EctoHelper.validate_xor_change([
        :disqualified_at,
        :disqualified_by_id,
      ])
    ).valid?
  end
end
