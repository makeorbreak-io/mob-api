defmodule Api.WorkshopAttendanceView do
  use Api.Web, :view

  alias Api.{Admin.UserView}

  def render("attendance_user.json", %{attendance: attendance}) do
    Map.merge(
      render_one(attendance.user, UserView, "user_short.json"),
      %{checked_in: attendance.checked_in}
    )
  end
end
