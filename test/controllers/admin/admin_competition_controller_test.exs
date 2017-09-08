defmodule Api.Admin.CompetitionControllerTest do
  use Api.ConnCase

  alias Api.{CompetitionActions}
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

  test "admin can start voting period", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :start_voting))

    assert response(conn, 204)
  end

  test "admin can't start voting period if it's already started", %{conn: conn, jwt: jwt} do
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :start_voting))

    assert json_response(conn, 422)["errors"] == "Competition already started"
  end

  test "admin can end voting period", %{conn: conn, jwt: jwt} do
    CompetitionActions.start_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert response(conn, 204)
  end

  test "admin can't end voting period if it's already ended", %{conn: conn, jwt: jwt} do
    CompetitionActions.start_voting()
    CompetitionActions.end_voting()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert json_response(conn, 422)["errors"] == "Competition already ended"
  end

  test "admin can't end voting period if it hasn't started", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_competition_path(conn, :end_voting))

    assert json_response(conn, 422)["errors"] == "Competition hasn't started yet"
  end
end
