defmodule Api.UserView do
  use Api.Web, :view

  def render("index.json", %{users: users}) do
    %{data: render_many(users, Api.UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, Api.UserView, "user.json")}
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
      team: if user.project do render_one(user.project, Api.TeamView, "team.json") end
    }
  end
end
