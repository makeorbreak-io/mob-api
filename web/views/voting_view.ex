defmodule Api.VotingView do
  use Api.Web, :view

  alias Api.{Team, Repo}
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

  def render("info_end.json", %{
    participants: %{
      initial_count: participant_initial_count,
      final_count: participant_final_count
    },
    paper_votes: %{
      initial_count: paper_votes_initial_count,
      final_count: paper_votes_final_count
    },
    teams: teams,
    categories: categories,
  }) do
    winning_ids = Enum.flat_map(categories, fn c -> c.podium end)
    team_name_map = Repo.all(Team) |> Enum.map(&({&1.id, slugify(&1.name)})) |> Map.new
    %{
      participants: %{
        initial_count: participant_initial_count,
        final_count: participant_final_count,
      },
      paper_votes: %{
        initial_count: paper_votes_initial_count,
        final_count: paper_votes_final_count,
      },
      teams:
        teams
        |> Enum.map(fn team ->
          {
            slugify(team.name),
            %{
              tie_breaker: team.tie_breaker,
              prize_preference: Map.merge(
                %{
                  hmac: Team.preference_hmac(team),
                },
                if Enum.member?(winning_ids, team.id) do
                  %{
                    key: team.prize_preference_hmac_secret,
                    contents: Enum.join(team.prize_preference || [], ","),
                  }
                else
                  %{}
                end
              ),
              disqualified: team.disqualified_at && true || false,
            }
          }
        end)
        |> Map.new,
      podiums:
        categories
        |> Enum.map(fn category ->
          {
            category.name,
            category.podium |> Enum.map(fn tid -> team_name_map[tid] end),
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
