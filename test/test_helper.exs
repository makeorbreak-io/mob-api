ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule ApiWeb.TestHelper do
  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Workshops.{Workshop, Attendance}
  alias Api.Teams.{Team, Membership, Invite}
  alias Api.Competitions.{Category, Competition}
  alias Api.Competitions.Attendance, as: CompAttendance
  alias Api.{Voting, Voting.Vote}
  alias ApiWeb.StringHelper
  import Api.Accounts.User, only: [gravatar_hash: 1]

  @valid_user_attrs %{
    name: "john doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }

  @valid_workshop_attrs %{
    name: "awesome workshop",
    participant_limit: 1,
    short_date: "SUNDAY 10TH — 10:30"
  }

  @valid_competition_attrs %{
    name: "awesome competition"
  }

  defp add_email(params) do
    Map.merge(
      %{email: "#{to_string(:rand.uniform())}@email.com"},
      params
    )
  end

  defp add_slug(params) do
    Map.merge(%{slug: "workshop-#{to_string(:rand.uniform())}"}, params)
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

  def create_team(user, competition, params \\ nil) do
    params = params || %{name: "awesome team #{to_string(:rand.uniform())}"}
    team = %Team{competition_id: competition.id}
    |> Team.changeset(params, Repo)
    |> Repo.insert!

    Repo.insert! %Membership{user_id: user.id, team_id: team.id, role: "owner"}

    team
  end

  def create_competition(params \\ @valid_competition_attrs) do
    %Competition{}
    |> Competition.changeset(params)
    |> Repo.insert!
  end

  def create_competition_attendance(competition, user) do
    Repo.insert! %CompAttendance{competition_id: competition.id, attendee: user.id}
  end

  def create_workshop(params \\ @valid_workshop_attrs) do
    %Workshop{}
    |> Workshop.changeset(params |> add_slug)
    |> Repo.insert!
  end

  def create_workshop_attendance(workshop, user) do
    Repo.insert! %Attendance{workshop_id: workshop.id, user_id: user.id}
  end

  def create_id_invite(team, host, user) do
    %Invite{}
    |> Invite.changeset(%{
      invitee_id: user.id,
      team_id: team.id,
      host_id: host.id
    })
    |> Repo.insert!
  end

  def create_email_invite(team, host, email) do
    %Invite{}
    |> Invite.changeset(%{
      email: email,
      team_id: team.id,
      host_id: host.id
    })
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
      |> User.admin_changeset()
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
      "name" => u.name,
      "gravatar_hash" => gravatar_hash(u),
      "id" => u.id,
      "tshirt_size" => u.tshirt_size,
      "email" => u.email
    }
  end
end
