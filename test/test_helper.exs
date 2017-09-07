ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule Api.TestHelper do
  alias Api.{User, Team, Repo, TeamMember, Invite, Workshop, Category}

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

  def create_team(user, params \\ @valid_team_attrs) do
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

  def create_category(params \\ %{}) do
    %Category{}
    |> Category.changeset(
      %{
        name: "cool #{:rand.uniform()}",
      }
      |> Map.merge(params)
    )
    |> Repo.insert!
  end
end
