defmodule ApiWeb.TeamControllerTest do
  use ApiWeb.ConnCase
  use Bamboo.Test, shared: true

  alias Api.Competitions
  alias Api.{Competitions.Team, Competitions.Membership}
  alias Api.Notifications.Emails
  import Api.Accounts.User, only: [display_name: 1, gravatar_hash: 1]

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = create_user()
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)

    {:ok, %{
      user: user,
      jwt: jwt,
      claims: full_claims,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "lists all teams on index", %{conn: conn, user: user} do
    team = create_team(user)

    conn = get conn, team_path(conn, :index)
    assert json_response(conn, 200)["data"] == [%{
      "id" => team.id,
      "name" => team.name,
      "applied" => team.applied,
      "eligible" => team.eligible,
      "prize_preference" => team.prize_preference
    }]
  end

  test "shows chosen team", %{conn: conn, user: user} do
    team = create_team(user)
    |> Repo.preload([:members, :invites])

    conn = get conn, team_path(conn, :show, team)
    assert json_response(conn, 200)["data"] == %{
      "id" => team.id,
      "name" => team.name,
      "applied" => team.applied,
      "eligible" => team.eligible,
      "prize_preference" => team.prize_preference,
      "members" => [%{
        "id" => user.id,
        "role" => "owner",
        "display_name" => display_name(user),
        "gravatar_hash" => gravatar_hash(user),
      }],
      "invites" => team.invites,
      "disqualified_at" => nil,
      "project_name" => nil,
      "project_desc" => nil,
      "technologies" => nil
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, team_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates team when data and request are valid", %{conn: conn, jwt: jwt, user: user} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @valid_attrs)

    team = Repo.get(Team, json_response(conn, 201)["data"]["id"])
    |> Repo.preload([members: [:user]])

    assert Enum.any?(team.members, fn(member) -> member.user_id == user.id end)
  end

  test "doesn't create team when request is invalid", %{conn: conn} do
    conn = post(conn, team_path(conn, :create), team: @valid_attrs)

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "doesn't create team when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(team_path(conn, :create), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates team when data and request are valid", %{conn: conn, jwt: jwt, user: user} do
    team = create_team(user, %{name: "regular team"})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Team, @valid_attrs)
  end

  test "sends emails to team members when team applies", %{conn: conn, jwt: jwt, user: user} do
    member1 = create_user(%{email: "user1@example.com", password: "thisisapassword"})
    member2 = create_user(%{email: "user2@example.com", password: "thisisapassword"})
    team = create_team(user)
    Repo.insert! %Membership{user_id: member1.id, team_id: team.id}
    Repo.insert! %Membership{user_id: member2.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: %{applied: true, name: "team"})

    assert json_response(conn, 200)["data"]["id"]
    assert_delivered_email Emails.joined_hackathon_email(user, team)
    assert_delivered_email Emails.joined_hackathon_email(member1, team)
    assert_delivered_email Emails.joined_hackathon_email(member2, team)
  end

  test "doesn't update team when request is invalid", %{conn: conn, user: user} do
    team = create_team(user)

    conn = conn
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "doesn't update team when data is invalid", %{conn: conn, jwt: jwt, user: user} do
    team = create_team(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "doesn't update team if user isn't a member", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(team_path(conn, :update, team), team: @valid_attrs)

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Unauthorized"
  end

  test "deletes team if user is a member", %{conn: conn, jwt: jwt, user: user} do
    invitee = create_user(%{
      email: "example@email.com",
      first_name: "Jane",
      last_name: "doe",
      password: "thisisapassword"
    })
    team = create_team(user)
    create_invite(%{host_id: user.id, team_id: team.id, invitee_id: invitee.id})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))

    assert response(conn, 204)
    refute Repo.get(Team, team.id)
  end

  test "doesn't delete team if user isn't a member", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :delete, team))

    assert json_response(conn, 401)
    assert Repo.get(Team, team.id)
  end

  test "remove membership works if triggered by team owner", %{conn: conn, jwt: jwt, user: user} do
    team_member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(user)
    Repo.insert! %Membership{user_id: team_member.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, team_member.id))

    assert response(conn, 204)
  end

  test "remove membership works if triggered by team member", %{conn: conn, jwt: jwt, user: user} do
    owner = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %Membership{user_id: user.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, user.id))

    assert response(conn, 204)
  end

  test "can't remove membership if you're not part of the team", %{conn: conn, jwt: jwt} do
    owner = create_user(%{email: "host@example.com", password: "thisisapassword"})
    member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %Membership{user_id: member.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, member.id))

    assert response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Unauthorized"
  end

  test "can't remove membership if user isn't in the DB", %{conn: conn, jwt: jwt, user: user} do
    team = create_team(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, Ecto.UUID.generate()))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "User not found"
  end

  test "can't remove membership if request isn't valid", %{conn: conn} do
    owner = create_user(%{email: "host@example.com", password: "thisisapassword"})
    member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(owner)
    Repo.insert! %Membership{user_id: member.id, team_id: team.id}

    conn = conn
    |> delete(team_path(conn, :remove, team, member.id))

    assert response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "can't remove membership if user isn't in the team", %{conn: conn, jwt: jwt, user: user} do
    random_user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, random_user.id))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "User isn't a member of team"
  end


  test "remove membership doesn't work if team is applied", %{conn: conn, jwt: jwt, user: user} do
    member = create_user(%{email: "user@example.com", password: "thisisapassword"})
    team = create_team(user, %{name: "awesome team", applied: true})
    Repo.insert! %Membership{user_id: member.id, team_id: team.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, member.id))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "Can't remove users after applying to the event"
  end

  test "remove membership doesn't work if voting has started", %{conn: conn, jwt: jwt, user: user} do
    member = create_user()
    team = create_team(user, %{name: "awesome team", applied: true})
    Repo.insert! %Membership{user_id: member.id, team_id: team.id}
    Competitions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(team_path(conn, :remove, team, member.id))

    assert response(conn, 422)
    assert json_response(conn, 422)["errors"] == "Competition already started"
  end
end
