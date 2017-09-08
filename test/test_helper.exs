ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule Api.TestHelper do
  alias Api.{User, Team, Repo, TeamMember, Invite, Workshop, Category, StringHelper, UserActions}

  @valid_user_attrs %{
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }
  @valid_team_attrs %{
    name: "awesome team",
    repo: %{"name" => "awesome-team"}
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

    Repo.insert! %TeamMember{user_id: user.id, team_id: team.id, role: "owner"}

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
    %TeamMember{}
    |> TeamMember.changeset(%{
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

  def check_in_everyone do
    people = User |> Repo.all

    people
    |> Enum.map(&UserActions.toggle_checkin(&1.id, true))
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
end
