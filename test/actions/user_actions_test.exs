defmodule ApiWeb.UserActionTest do
  use Api.DataCase

  alias Api.Accounts
  alias ApiWeb.CompetitionActions


  test "able_to_vote checked in" do
    u = create_user()

    CompetitionActions.start_voting()

    :already_started = Accounts.toggle_checkin(u.id, true)
  end
end
