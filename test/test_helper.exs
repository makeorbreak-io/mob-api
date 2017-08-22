ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule Api.TestHelper do
  alias Api.{User, Team, Repo, TeamMember, Invite, Workshop}

  @valid_user_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @valid_team_attrs %{name: "awesome team"}
  @valid_workshop_attrs %{
    name: "awesome workshop",
    slug: "awesome-workshop",
    participant_limit: 1
  }

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert!
  end

  def create_admin(params \\ @valid_user_attrs) do
    user_params = Kernel.struct(User, Map.merge(params, %{role: "admin"}))
    
    user_params
    |> Repo.insert!
  end

  def create_team(user, params \\ @valid_team_attrs) do
    team = %Team{}
    |> Team.changeset(params)
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
end