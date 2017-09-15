defmodule ApiWeb.Admin.InviteControllerTest do
  use ApiWeb.ConnCase

  alias ApiWeb.{Invite, Repo}
  alias Guardian.{Permissions}

  setup %{conn: conn} do
    admin = create_admin()
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "sync invites work", %{conn: conn, jwt: jwt, admin: admin} do
    owner = create_user()
    team = create_team(owner)
    user = create_user()


    %{id: id1} = create_invite(%{host_id: owner.id, team_id: team.id, email: user.email})
    %{id: id2} = create_invite(%{host_id: owner.id, team_id: team.id, email: admin.email})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_invite_path(conn, :sync))

    invite1 = Repo.get(Invite, id1)
    invite2 = Repo.get(Invite, id2)

    assert response(conn, 204)
    assert invite1.invitee_id == user.id
    assert invite2.invitee_id == admin.id
  end
end
