defmodule Api.SessionControllerTest do
  use Api.ConnCase

  alias Api.{User, Repo}

  @valid_attrs %{ email: "email@example.com", password: "thisisapassword" }

  test "creates a session", %{conn: conn} do
    create_user

    response = create_session(conn, "email@example.com", "thisisapassword")

    data = response["data"]
    
    assert data["jwt"]
    assert data["user"]["id"]
    assert data["user"]["email"]
  end

  test "deletes a session", %{conn: conn} do
    create_user
    session_response = create_session(conn, "email@example.com", "thisisapassword")

    conn
    |> put_req_header("authorization", "Bearer #{session_response["data"]["jwt"]}")
    |> delete("/api/logout")
    |> json_response(200)
  end

  test "jwt checking works", %{conn: conn} do
    user = create_user

    session_response = create_session(conn, "email@example.com", "thisisapassword")
    
    response = conn    
    |> put_req_header("authorization", "Bearer #{session_response["data"]["jwt"]}")
    |> get("api/me")
    |> json_response(200)

    assert response["data"]["id"] == user.id
  end

  test "fails authorization", %{conn: conn} do
    create_user

    conn = post conn, "/api/login", email: "email@example.com", password: "wrong"
    response = json_response(conn, 422)
   
    assert response == %{"error" => "Unable to authenticate"} 
  end

  defp create_user(params \\ @valid_attrs) do
    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert!
  end

  defp create_session(conn, email, password) do
    post(conn, "/api/login", email: email, password: password)
    |> json_response(201)
  end
end