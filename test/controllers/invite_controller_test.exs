defmodule Api.InviteControllerTest do
  use Api.ConnCase

  alias Api.Invite

  @valid_attrs %{description: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    user = create_user
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)

    {:ok, %{
      user: user,
      jwt: jwt,
      claims: full_claims,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "lists all entries on index", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(invite_path(conn, :index))
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn, user: user} do
    team = create_team(%{user_id: user.id, name: "awesome_team"})
    invite = create_invite(%{host_id: user.id, team_id: team.id})

    conn = get conn, invite_path(conn, :show, invite)
    assert json_response(conn, 200)["data"] == %{
      "id" => invite.id,
      "description" => invite.description,
      "accepted" => invite.accepted,
      "team" => %{
        "id" => team.id,
        "name" => team.name
      },
      "host" => %{
        "id" => user.id,
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "display_name" => "#{user.first_name} #{user.last_name}"
      },
      "invitee" => nil,
      "open" => false
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, invite_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    end
  end

  test "creates resource when data and request are valid", %{conn: conn, jwt: jwt, user: user} do
    create_team(%{user_id: user.id, name: "awesome_team"})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(invite_path(conn, :create), invite: @valid_attrs)

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get(Invite, json_response(conn, 201)["data"]["id"])
  end

  test "doesn't create resource when request is invalid", %{conn: conn} do
    conn = post(conn, invite_path(conn, :create), invite: @valid_attrs)

    assert json_response(conn, 401)["error"] == "Authentication required"
  end

  test "updates resource when data and request are valid", %{conn: conn, jwt: jwt} do
    invite = Repo.insert! %Invite{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(invite_path(conn, :update, invite), invite: @valid_attrs)

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get(Invite, json_response(conn, 200)["data"]["id"])
  end

  test "membership is created when invitation is accepted", %{conn: conn, jwt: jwt, user: user} do
    invitee = create_user(%{
      email: "example@email.com",
      first_name: "Jane",
      last_name: "doe",
      password: "thisisapassword"
    })
    team = create_team(%{user_id: user.id, name: "awesome_team"})
    invite = create_invite(%{host_id: user.id, team_id: team.id, invitee_id: invitee.id})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(invite_path(conn, :accept, invite))

    assert json_response(conn, 200)["data"]["accepted"] == true
  end

  test "deletes chosen resource", %{conn: conn, jwt: jwt} do
    invite = Repo.insert! %Invite{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(invite_path(conn, :delete, invite))
    
    assert response(conn, 204)
    refute Repo.get(Invite, invite.id)
  end
end