defmodule Api.UserControllerTest do
  use Api.ConnCase
  use Bamboo.Test, shared: true

  alias Api.{User, TeamMember, Email}
  alias Comeonin.Bcrypt

  @valid_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @invalid_attrs %{email: "no at sign"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all users on index", %{conn: conn} do
    user = create_user()
    conn = get conn, user_path(conn, :index)
    assert json_response(conn, 200)["data"] == [%{
      "display_name" => "#{user.first_name} #{user.last_name}",
      "gravatar_hash" => UserHelper.gravatar_hash(user),
      "first_name" => user.first_name,
      "last_name" => user.last_name,
      "id" => user.id,
      "tshirt_size" => user.tshirt_size
    }]
  end

  test "shows user with owner role in team", %{conn: conn} do
    user = create_user()
    team = create_team(user)

    conn = get conn, user_path(conn, :show, user)

    assert json_response(conn, 200)["data"] == %{
      "id" => user.id,
      "first_name" => user.first_name,
      "last_name" => user.last_name,
      "display_name" => "#{user.first_name} #{user.last_name}",
      "gravatar_hash" => UserHelper.gravatar_hash(user),
      "birthday" => user.birthday,
      "employment_status" => user.employment_status,
      "college" => user.college,
      "company" => user.company,
      "github_handle" => user.github_handle,
      "twitter_handle" => user.twitter_handle,
      "linkedin_url" => user.linkedin_url,
      "bio" => user.bio,
      "tshirt_size" => nil,
      "team" => %{
        "id" => team.id,
        "name" => team.name,
        "applied" => team.applied,
        "role" => "owner"
      }
    }
  end

  test "shows user with member role in team", %{conn: conn} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team_member = create_user(%{email: "johndoe@example.com", first_name: "john", last_name: "doe", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %TeamMember{user_id: team_member.id, team_id: team.id}

    conn = get conn, user_path(conn, :show, team_member)

    assert json_response(conn, 200)["data"] == %{
      "id" => team_member.id,
      "first_name" => team_member.first_name,
      "last_name" => team_member.last_name,
      "display_name" => "#{team_member.first_name} #{team_member.last_name}",
      "gravatar_hash" => UserHelper.gravatar_hash(team_member),
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
        "applied" => team.applied,
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
    user = Repo.get_by(User, email: "johndoe@example.com")

    assert user
    assert_delivered_email Email.registration_email(user)
  end

  test "doesn't create user when data is invalid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "associates invites with user on creation", %{conn: conn} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    create_invite(%{host_id: owner.id, team_id: team.id, email: "johndoe@example.com"})
    post conn, user_path(conn, :create), user: @valid_attrs
    team_member = Repo.get_by(User, email: "johndoe@example.com") |> Repo.preload(:invitations)

    assert Enum.count(team_member.invitations) == 1
  end

  test "updates user when data is valid", %{conn: conn} do
    user = create_user()
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(user_path(conn, :update, user), user: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(User, email: "johndoe@example.com")
  end

  test "doesn't update user when data is invalid", %{conn: conn} do
    user = create_user()
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(user_path(conn, :update, user), user: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "doesn't update user when user is unauthenticated", %{conn: conn} do
    user = create_user()

    conn = put(conn, user_path(conn, :update, user), user: @invalid_attrs)

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "deletes user if the request is made by that user", %{conn: conn} do
    user = create_user()
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    create_team(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(user_path(conn, :delete, user))

    assert response(conn, 204)
    refute Repo.get(User, user.id)
  end

  test "doesnt' delete user if the request is made by other user", %{conn: conn} do
    user = create_user()
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    random_user = create_user()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(user_path(conn, :delete, random_user))

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Unauthorized"
  end

  test "doesn't delete when request is unauthenticated", %{conn: conn} do
    user = create_user()

    conn = delete(conn, user_path(conn, :delete, user))

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "get token adds correct data to user and sends email", %{conn: conn} do
    user = create_user()

    conn = get(conn, user_path(conn, :get_token), email: user.email)

    assert response(conn, 204)

    updated_user = Repo.get(User, user.id)

    assert_delivered_email Email.recover_password_email(updated_user)
    assert not is_nil updated_user.pwd_recovery_token
    assert not is_nil updated_user.pwd_recovery_token_expiration
  end

  test "recover password works if token exists and it hasn't expired", %{conn: conn} do
    user = create_user()

    conn1 = get(conn, user_path(conn, :get_token), email: user.email)

    assert response(conn1, 204)

    user1 = Repo.get(User, user.id)

    conn2 = post(conn1, user_path(conn, :recover_password),
      token: user1.pwd_recovery_token,
      password: "thisisanewpassword")

    assert response(conn2, 204)

    user2 = Repo.get(User, user.id)

    assert Bcrypt.checkpw("thisisanewpassword", user2.password_hash)
  end

  test "recover password fails if token doesn't exist", %{conn: conn} do
    conn = post(conn, user_path(conn, :recover_password),
      token: UserHelper.generate_token(),
      password: "thisisanewpassword")

    assert json_response(conn, 422)
    assert json_response(conn, 422)["errors"] == "Recover password token is invalid"
  end

  test "recover password fails if token is expired", %{conn: conn} do
    user = create_user(%{
      pwd_recovery_token: UserHelper.generate_token(),
      pwd_recovery_token_expiration: Ecto.DateTime.to_iso8601(%Ecto.DateTime{
        year: 2017,
        month: 5,
        day: 10,
        hour: 10,
        min: 14,
        sec: 15}),
      password: "thisisapassword"
    })

    conn = post(conn, user_path(conn, :recover_password),
      token: user.pwd_recovery_token,
      password: "thisisanewpassword")

    assert json_response(conn, 422)
    assert json_response(conn, 422)["errors"] == "Recover password token has expired"
  end
end
