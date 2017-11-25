defmodule ApiWeb.ErrorController do
  use Api.Web, :controller

  alias ApiWeb.{ChangesetView, ErrorView}

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {error, code}) when is_atom(error),
    do: call(conn, {message(error), code})
  def call(conn, {error, code}) do
    conn
    |> put_status(code)
    |> render(ErrorView, "error.json", error: error)
  end
  def call(conn, error), do: call(conn, {error, :unprocessable_entity})

  def unauthenticated(conn, _params) do
    call(conn, {:authentication_required, :unauthorized})
  end

  def unauthorized(conn, _params) do
    call(conn, {:unauthorized, :unauthorized})
  end

  defp message(:already_ended), do: "Competition already ended"
  defp message(:already_redeemed), do: "Paper vote has already been redeemed"
  defp message(:already_started), do: "Competition already started"
  defp message(:annulled), do: "Paper vote has annulled"
  defp message(:authentication_required), do: "Authentication required"
  defp message(:checkin), do: "Couldn't check-in user at this time"
  defp message(:expired_token), do: "Recover password token has expired"
  defp message(:invalid_token), do: "Recover password token is invalid"
  defp message(:invite_not_found), do: "Invite not found"
  defp message(:join_workshop), do: "Unable to create workshop attendance"
  defp message(:membership_not_found), do: "User isn't a member of team"
  defp message(:not_ended), do: "Competition hasn't ended yet"
  defp message(:not_started), do: "Competition hasn't started yet"
  defp message(:not_workshop_attendee), do: "User isn't an attendee of the workshop"
  defp message(:remove_checkin), do: "Couldn't remove check-in at this time"
  defp message(:team_disqualified), do: "Team has been disqualified"
  defp message(:team_locked), do: "Can't remove users after applying to the event"
  defp message(:team_not_eligible), do: "Team is not eligible"
  defp message(:team_user_limit), do: "Team user limit reached"
  defp message(:unauthorized), do: "Unauthorized"
  defp message(:user_not_found), do: "User not found"
  defp message(:user_without_team), do: "Couldn't make changes to your team"
  defp message(:workshop_full), do: "Workshop is already full"
  defp message(:wrong_credentials), do: "Wrong email or password"
end
