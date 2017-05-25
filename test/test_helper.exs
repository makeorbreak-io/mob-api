ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule Api.TestHelper do
  alias Api.{User, Team, Repo, Invite, SessionController}

  @valid_user_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @valid_team_attrs %{name: "awesome team"}

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert!
  end

  def create_team(params \\ @valid_team_attrs) do
    %Team{}
    |> Team.changeset(params)
    |> Repo.insert!
  end

  def create_invite(params) do
    %Invite{}
    |> Invite.changeset(params)
    |> Repo.insert!
  end

  def create_session(conn, email, password) do
    SessionController.create(conn, %{"email" => email, "password" => password})
    |> Phoenix.ConnTest.json_response(201)
  end
end