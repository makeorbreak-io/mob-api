defmodule Api.SessionView do
  use Api.Web, :view

  def render("session.json", %{data: data}) do
	  %{data: data}
	end

  def render("error.json", %{error: error}), do: %{error: error}
  def render("error.json", %{}), do: %{}
end