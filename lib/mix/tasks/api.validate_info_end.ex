defmodule Mix.Tasks.Api.ValidateInfoEnd do
    use Mix.Task

    @shortdoc "Validates an info_end.json locally"

    @moduledoc """
      You can get an info_end.json on your User Dashboard after the voting ends.
    """

  alias Api.CompetitionActions

  def run(file_path) do
    file = if file_path == "-", do: :stdio, else: File.open!(file_path)
    doc = Poison.decode!(IO.read(file, :all))

    expected_podiums = doc["podiums"]
    votes_in_categories = doc["votes"]

    if Map.keys(expected_podiums) != Map.keys(votes_in_categories) do
      raise "Invalid file. podiums and votes have different categories!"
    end

    valid_teams =
      doc["teams"]
      |> Map.to_list
      |> Enum.reject(&(elem(&1, 1)["disqualified"]))

    valid_team_ids =
      valid_teams
      |> Enum.map(&(elem(&1, 0)))

    tie_breakers =
      valid_teams
      |> Map.new(fn {team_slug, attrs} ->
        {
          team_slug,
          attrs["tie_breaker"],
        }
      end)

    differences =
      Enum.map(votes_in_categories, fn {category, votes} ->
        expected_podium = expected_podiums[category]

        calculated_podium = CompetitionActions.calculate_podium(
          CompetitionActions.clean_votes_into_ballots(votes, valid_team_ids),
          valid_team_ids,
          tie_breakers
        )

        if expected_podium != calculated_podium do
          {category, expected_podium, calculated_podium}
        else
          nil
        end
      end)
      |> Enum.reject(&(&1 == nil))

    if Enum.count(differences) == 0 do
      Mix.shell.info "It looks valid! Calculated the voting locally and came to the same results."
    else
      Mix.shell.error "Things look funny."
      Enum.each(differences, fn {category, expected, calculated} ->
          Mix.shell.info Enum.join([
            "",
            "Podium for #{category} differs.",
            "Expected podium: #{inspect(expected)}",
            "Calculated podium: #{inspect(calculated)}",
          ], "\n")
      end)
    end
  end
end
