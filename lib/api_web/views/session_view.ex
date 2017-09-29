defmodule ApiWeb.SessionView do
  use Api.Web, :view

  alias Api.Competitions
  alias ApiWeb.{InviteView, MembershipView, WorkshopView}
  import Api.Accounts.User, only: [display_name: 1, gravatar_hash: 1]

  def render("show.json", %{data: %{jwt: jwt, user: user}}) do
    %{data: %{
        jwt: jwt,
        user: render_one(user, __MODULE__, "user.json", as: :user)
      }
    }
  end
  def render("show.json", %{data: data}), do: %{data: data}

  def render("me.json", %{user: user}) do
    %{data: render_one(user, __MODULE__, "user.json", as: :user)}
  end

  def render("user.json", %{user: user}) do
    result = %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      gravatar_hash: gravatar_hash(user),
      display_name: display_name(user),
      birthday: user.birthday,
      bio: user.bio,
      github_handle: user.github_handle,
      twitter_handle: user.twitter_handle,
      linkedin_url: user.linkedin_url,
      employment_status: user.employment_status,
      college: user.college,
      company: user.company,
      team: if user.team do
        render_one(user.team, MembershipView, "member_team_full.json", as: :membership)
      end,
      invitations: if Ecto.assoc_loaded?(user.invitations) do
        render_many(user.invitations, InviteView, "invite.json")
      end,
      tshirt_size: user.tshirt_size,
      workshops: if Ecto.assoc_loaded?(user.workshops) do
        render_many(user.workshops, WorkshopView, "workshop_short.json")
      end,
    }

    result = if Competitions.voting_status == :ended do
      result
      |> Map.put(:voter_identity, user.voter_identity)
    else
      result
    end

    result
  end
end
