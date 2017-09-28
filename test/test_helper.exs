ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule ApiWeb.TestHelper do
  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Workshops.Workshop
  alias Api.{Competitions.Team, Competitions.Membership, Competitions.Invite,
    Competitions.Category}
  alias Api.{Voting, Voting.Vote}
  alias ApiWeb.{StringHelper, UserHelper}

  @valid_user_attrs %{
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }

  @valid_workshop_attrs %{
    name: "awesome workshop",
    slug: "awesome-workshop",
    participant_limit: 1,
    short_date: "SUNDAY 10TH — 10:30"
  }

  defp add_email(params) do
    Map.merge(
      %{email: "#{to_string(:rand.uniform())}@email.com"},
      params
    )
  end

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(
      params
      |> add_email
    )
    |> Repo.insert!
  end

  def create_admin(params \\ @valid_user_attrs) do
    %User{}
    |> User.admin_changeset(
      params
      |> add_email
      |> Map.merge(%{role: "admin"})
    )
    |> Repo.insert!
  end

  def create_team(user, params \\ nil) do
    params = params || %{name: "awesome team #{to_string(:rand.uniform())}"}
    team = %Team{}
    |> Team.changeset(params, Repo)
    |> Repo.insert!

    Repo.insert! %Membership{user_id: user.id, team_id: team.id, role: "owner"}

    team
  end

  def create_workshop(params \\ @valid_workshop_attrs) do
    %Workshop{}
    |> Workshop.changeset(params)
    |> Repo.insert!
  end

  def create_invite(params) do
    %Invite{}
    |> Invite.changeset(params)
    |> Repo.insert!
  end

  def create_membership(team, user) do
    %Membership{}
    |> Membership.changeset(%{
      user_id: user.id,
      team_id: team.id,
    })
    |> Repo.insert!
  end

  def create_category(params \\ %{}) do
    %Category{}
    |> Category.changeset(
      %{
        name: StringHelper.slugify("cool #{:rand.uniform()}"),
      }
      |> Map.merge(params)
    )
    |> Repo.insert!
  end

  def check_in_everyone(people \\ nil) do
    people = people || Repo.all(User)

    people
    |> Enum.map(fn user ->
      user
      |> User.admin_changeset(%{checked_in: true})
      |> Repo.update!
    end)
  end

  def make_teams_eligible(teams \\ nil) do
    teams = teams || Repo.all(Team)

    teams
    |> Enum.map(fn team ->
      team
      |> Team.admin_changeset(%{eligible: true}, Repo)
      |> Repo.update!
    end)
  end

  def create_vote(user, category_name, ballot) do
    category = Repo.get_by(Category, name: category_name)

    Repo.insert! %Vote{
      voter_identity: user.voter_identity,
      category_id: category.id,
      ballot: ballot
    }
  end

  def create_paper_vote(category, admin) do
    {:ok, pv} = Voting.create_paper_vote(category, admin)
    pv
  end

  def annul_paper_vote(paper_vote, admin) do
    {:ok, pv} = Voting.annul_paper_vote(paper_vote, admin)
    pv
  end

  def redeem_paper_vote(paper_vote, team, member, admin) do
    {:ok, pv} = Voting.redeem_paper_vote(paper_vote, team, member, admin)
    pv
  end

  def team_short_view(t) do
    %{"id" => t.id, "name" => t.name}
  end

  def team_view(t) do
    %{
      "applied" => t.applied,
      "disqualified_at" => t.disqualified_at,
      "eligible" => t.eligible,
      "id" => t.id,
      "invites" => nil,
      "members" => nil,
      "name" => t.name,
      "prize_preference" => t.prize_preference,
      "project_name" => t.project_name,
      "project_desc" => t.project_desc,
      "technologies" => t.technologies,
    }
  end

  def admin_user_short_view(u) do
    %{
      "display_name" => UserHelper.display_name(u),
      "first_name" => u.first_name,
      "last_name" => u.last_name,
      "gravatar_hash" => UserHelper.gravatar_hash(u),
      "id" => u.id,
      "tshirt_size" => u.tshirt_size,
      "email" => u.email
    }
  end
end
