defmodule Api.Controller.Errors do
  use Api.Web, :controller

  alias Api.{ChangesetView, ErrorView}

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
  defp message(:user_without_team), do: "Couldn't make changes to your team"
  defp message(:wrong_credentials), do: "Wrong email or password"
  defp message(:unauthorized), do: "Unauthorized"
  defp message(:authentication_required), do: "Authentication required"
  defp message(:checkin), do: "Couldn't check-in user at this time"
  defp message(:remove_checkin), do: "Couldn't remove check-in at this time"
  defp message(:join_workshop), do: "Unable to create workshop attendance"
  defp message(:workshop_full), do: "Workshop is already full"
  defp message(:workshop_attendee), do: "User isn't an attendee of the workshop"
end
