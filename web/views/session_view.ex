defmodule Api.SessionView do
  use Api.Web, :view

  def render("session.json", %{data: data}) do
    %{data: data}
  end
end
