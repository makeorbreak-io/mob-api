defmodule Api.VotingView do
  use Api.Web, :view

  alias Api.{Team}
  import Api.StringHelper, only: [slugify: 1]

  def render("info_begin.json", %{
    participants: %{
      initial_count: participant_initial_count
    },
    paper_votes: %{
      initial_count: paper_votes_initial_count
    },
    teams: teams,
  }) do
    %{
      participants: %{
        initial_count: participant_initial_count
      },
      paper_votes: %{
        initial_count: paper_votes_initial_count
      },
      teams:
        teams
        |> Enum.map(fn team ->
          {
            slugify(team.name),
            %{
              tie_breaker: team.tie_breaker,
              prize_preference: %{
                hmac: Team.preference_hmac(team),
              }
            }
          }
        end)
        |> Map.new
    }
  end

  def render("upsert.json", %{votes: votes}) do
    Enum.reduce(votes, %{}, fn {category, vote}, acc ->
      Map.put(acc, String.to_atom(category), vote.ballot)
    end)
  end

  def render("index.json", %{votes: votes}) do
    Enum.reduce(votes, %{}, fn vote, acc ->
      Map.put(acc, String.to_atom(vote.category.name), vote.ballot)
    end)
  end
end
