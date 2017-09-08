defmodule Api.VotingView do
  use Api.Web, :view

  alias Api.{StringHelper, Team}

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
            StringHelper.slugify(team.name),
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
end
