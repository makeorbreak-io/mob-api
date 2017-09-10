defmodule Api.Admin.CompetitionView do
  use Api.Web, :view

  alias Api.{Admin.PaperVoteView, TeamView, UserView}

  def render("status.json", %{status: status}) do
    %{
      voting_status: status.voting_status,
      unredeemed_paper_votes: render_many(
        status.unredeemed_paper_votes,
        PaperVoteView,
        "paper_vote.json"),
      missing_voters: Enum.map(status.missing_voters, fn(team_users) ->
        %{
          team: render_one(team_users.team, TeamView, "team_short.json"),
          users: render_many(team_users.users, UserView, "user_short.json")
        }
      end)
    }
  end
end
