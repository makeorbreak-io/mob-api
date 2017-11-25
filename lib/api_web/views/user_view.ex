defmodule ApiWeb.UserView do
  use Api.Web, :view

  alias ApiWeb.MembershipView
  import Api.Accounts.User, only: [gravatar_hash: 1]

  def render("index.json", %{users: users}) do
    %{data: render_many(users, __MODULE__, "user_short.json")}
  end

  def render("user_short.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      gravatar_hash: gravatar_hash(user),
      tshirt_size: user.tshirt_size,
    }
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, __MODULE__, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      first_name: user.name,
      gravatar_hash: gravatar_hash(user),
      birthday: user.birthday,
      bio: user.bio,
      github_handle: user.github_handle,
      twitter_handle: user.twitter_handle,
      linkedin_url: user.linkedin_url,
      employment_status: user.employment_status,
      college: user.college,
      company: user.company,
      team: if user.team do
        render_one(user.team, MembershipView, "member_team_short.json", as: :membership)
      end,
      tshirt_size: user.tshirt_size,
    }
  end
end
