defmodule Api.UserControllerTest do
  use Api.ConnCase

  alias Api.{User, Team, TeamMember}

  @valid_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all users on index", %{conn: conn} do
    conn = get conn, user_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows user with owner role in team", %{conn: conn} do
    %{id: id} = create_user
    team = create_team(%{user_id: id, name: "awesome team"})

    user = Repo.get!(User, id)

    conn = get conn, user_path(conn, :show, user)
    
    assert json_response(conn, 200)["data"] == %{
      "id" => user.id,
      "first_name" => user.first_name,
      "last_name" => user.last_name,
      "display_name" => "#{user.first_name} #{user.last_name}",
      "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
      "birthday" => user.birthday,
      "employment_status" => user.employment_status,
      "college" => user.college,
      "company" => user.company,
      "github_handle" => user.github_handle,
      "twitter_handle" => user.twitter_handle,
      "linkedin_url" => user.linkedin_url,
      "bio" => user.bio,
      "team" => %{
        "id" => team.id,
        "name" => team.name,
        "role" => "owner"
      },
      "tshirt_size" => nil,
    }
  end

  test "shows user with member role in team", %{conn: conn} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team_member = create_user(%{email: "johndoe@example.com", first_name: "john", last_name: "doe", password: "thisisapassword"})
    team = Repo.insert! %Team{user_id: owner.id, name: "awesome team"}
    Repo.insert! %TeamMember{user_id: team_member.id, team_id: team.id}

    conn = get conn, user_path(conn, :show, team_member)
    
    assert json_response(conn, 200)["data"] == %{
      "id" => team_member.id,
      "first_name" => team_member.first_name,
      "last_name" => team_member.last_name,
      "display_name" => "#{team_member.first_name} #{team_member.last_name}",
      "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
      "birthday" => team_member.birthday,
      "employment_status" => team_member.employment_status,
      "college" => team_member.college,
      "company" => team_member.company,
      "github_handle" => team_member.github_handle,
      "twitter_handle" => team_member.twitter_handle,
      "linkedin_url" => team_member.linkedin_url,
      "bio" => team_member.bio,
      "team" => %{
        "id" => team.id,
        "name" => team.name,
        "role" => "member"
      },
      "tshirt_size" => nil,
    }
  end

  test "display name from email if there's no first and last name", %{conn: conn} do
    user = create_user(%{first_name: nil, last_name: nil, email: "johndoe@example.com", password: "password"})

    conn = get conn, user_path(conn, :show, user)

    assert json_response(conn, 200)["data"]["display_name"] == "johndoe"
  end

  test "display_name from first name if there's no last name", %{conn: conn} do
    user = create_user(%{first_name: "john", last_name: nil, email: "johndoe@example.com", password: "password"})

    conn = get conn, user_path(conn, :show, user)

    assert json_response(conn, 200)["data"]["display_name"] == "john"
  end

  test "display_name from first and last name if they're present", %{conn: conn} do
    user = create_user(%{first_name: "john", last_name: "doe", email: "johndoe@example.com", password: "password"})

    conn = get conn, user_path(conn, :show, user)

    assert json_response(conn, 200)["data"]["display_name"] == "john doe"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, user_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates user when data is valid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @valid_attrs

    assert json_response(conn, 201)["data"]["user"]["id"]
    assert Repo.get_by(User, email: "johndoe@example.com")
  end

  test "doesn't create user when data is invalid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "associates invites with user on creation", %{conn: conn} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(%{user_id: owner.id, name: "awesome_team"})
    create_invite(%{host_id: owner.id, team_id: team.id, email: "johndoe@example.com"})
    post conn, user_path(conn, :create), user: @valid_attrs
    team_member = Repo.get_by(User, email: "johndoe@example.com") |> Repo.preload(:invitations)

    assert Enum.count(team_member.invitations) == 1
  end

  test "updates user when data is valid", %{conn: conn} do
    user = Repo.insert! %User{}
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(user_path(conn, :update, user), user: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(User, email: "johndoe@example.com")
  end

  test "doesn't update user when data is invalid", %{conn: conn} do
    user = Repo.insert! %User{}
    {:ok, jwt, _} = Guardian.encode_and_sign(user)
   
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(user_path(conn, :update, user), user: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "doesn't update user when user is unauthenticated", %{conn: conn} do
    user = Repo.insert! %User{}
   
    conn = put(conn, user_path(conn, :update, user), user: @invalid_attrs)

    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "deletes user", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = delete conn, user_path(conn, :delete, user)
    assert response(conn, 204)
    refute Repo.get(User, user.id)
  end
end
