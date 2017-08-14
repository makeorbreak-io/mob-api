defmodule Api.AdminUserControllerTest do
  use Api.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "endpoints are availale for admin users", %{conn: conn} do
    admin = create_admin

    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Guardian.Permissions.max})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_user_path(conn, :index))

    assert json_response(conn, 200)
    result = List.first(json_response(conn, 200)["data"])

    assert result["id"]== admin.id
  end

  test "endpoints are locked for non admin users", %{conn: conn} do
    user = create_user

    {:ok, jwt, _} =
      Guardian.encode_and_sign(user, :token, perms: %{participant: Guardian.Permissions.max})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_user_path(conn, :index))

    assert json_response(conn, 401)
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end
end
