defmodule Api.UserView do
  use Api.Web, :view

  alias Api.{UserView, TeamView}

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      birthday: user.birthday,
      bio: user.bio,
      github_handle: user.github_handle,
      twitter_handle: user.twitter_handle,
      employment_status: user.employment_status,
      college: user.college,
      company: user.company,
      team: if user.team do render_one(user.team, TeamView, "team_summary.json") end
    }
  end

  def render("user_summary.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end
end
