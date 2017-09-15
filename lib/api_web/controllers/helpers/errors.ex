defmodule ApiWeb.Controller.Errors do
  use Api.Web, :controller

  alias ApiWeb.{ChangesetView, ErrorView}

  def changeset(conn, data) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ChangesetView, "error.json", changeset: data)
  end

  def unauthenticated(conn, _params) do
    build(conn, :unauthorized, :authentication_required)
  end

  def unauthorized(conn, _params) do
    build(conn, :unauthorized, :unauthorized)
  end

  def build(conn, code, data) when is_atom(data), do: build(conn, code, message(data))
  def build(conn, code, data) do
    conn
    |> put_status(code)
    |> render(ErrorView, "error.json", error: data)
  end

  defp message(:team_user_limit), do: "Team user limit reached"
  defp message(:user_not_found), do: "User not found"
  defp message(:user_without_team), do: "Couldn't make changes to your team"
  defp message(:wrong_credentials), do: "Wrong email or password"
  defp message(:unauthorized), do: "Unauthorized"
  defp message(:authentication_required), do: "Authentication required"
  defp message(:checkin), do: "Couldn't check-in user at this time"
  defp message(:remove_checkin), do: "Couldn't remove check-in at this time"
  defp message(:join_workshop), do: "Unable to create workshop attendance"
  defp message(:workshop_full), do: "Workshop is already full"
  defp message(:workshop_attendee), do: "User isn't an attendee of the workshop"
  defp message(:already_started), do: "Competition already started"
  defp message(:already_ended), do: "Competition already ended"
  defp message(:not_started), do: "Competition hasn't started yet"
  defp message(:not_ended), do: "Competition hasn't ended yet"
  defp message(:team_disqualified), do: "Team has been disqualified"
  defp message(:team_not_eligible), do: "Team is not eligible"
  defp message(:already_redeemed), do: "Paper vote has already been redeemed"
  defp message(:annulled), do: "Paper vote has annulled"
  defp message(:invalid_token), do: "Recover password token is invalid"
  defp message(:expired_token), do: "Recover password token has expired"
end
