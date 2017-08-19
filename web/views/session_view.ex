defmodule Api.SessionView do
  use Api.Web, :view

  alias Api.{UserView}

  def render("session.json", %{data: %{jwt: jwt, user: user}}) do
    %{data: %{
        jwt: jwt,
        user: render_one(user, UserView, "user_complete.json")
      }
    }
  end

  def render("session.json", %{data: data}), do: %{data: data}
end
