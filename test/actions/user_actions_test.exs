defmodule Api.UserActionTest do
  use Api.ModelCase

  alias Api.{UserActions, CompetitionActions}


  test "able_to_vote checked in" do
    u = create_user()

    CompetitionActions.start_voting()

    {:error, :already_started} = UserActions.toggle_checkin(u.id, true)
  end
end
