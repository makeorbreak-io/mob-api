defmodule Api.UserView do
  use Api.Web, :view

  alias Api.{UserView, TeamView, InviteView}

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      display_name: display_name(user),
      birthday: user.birthday,
      bio: user.bio,
      github_handle: user.github_handle,
      twitter_handle: user.twitter_handle,
      linkedin_url: user.linkedin_url,
      employment_status: user.employment_status,
      college: user.college,
      company: user.company,
      team: if user.team do render_one(user.team, TeamView, "team_summary.json") end
    }
  end

  def render("user_summary.json", %{user: user}) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      display_name: display_name(user)
    }
  end

  def render("me.json", %{user: user}) do
    %{
      data: %{
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        display_name: display_name(user),
        birthday: user.birthday,
        bio: user.bio,
        github_handle: user.github_handle,
        twitter_handle: user.twitter_handle,
        linkedin_url: user.linkedin_url,
        employment_status: user.employment_status,
        college: user.college,
        company: user.company,
        team: if user.team do render_one(user.team, TeamView, "team_summary.json") end,
        invitations: if user.invitations do render_many(user.invitations, InviteView, "invite.json") end,
      }
    }
  end

  def display_name(%{first_name: nil, last_name: nil, email: email}), do: List.first(String.split(email, "@", parts: 2))
  def display_name(%{first_name: first_name, last_name: nil}), do: "#{first_name}"
  def display_name(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"
end
