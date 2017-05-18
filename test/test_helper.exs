ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule Api.TestHelper do
  alias Api.{User, Project, Repo, SessionController}

  @valid_user_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @valid_team_attrs %{team_name: "awesome team"}

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert!
  end

  def create_session(conn, email, password) do
    SessionController.create(conn, %{"email" => email, "password" => password})
    |> Phoenix.ConnTest.json_response(201)
  end

  def create_team(params \\ @valid_team_attrs) do
    %Project{}
    |> Project.changeset(params)
    |> Repo.insert!
  end
end