defmodule Api.SessionControllerTest do
  use Api.ConnCase

  alias Api.{User, Repo}

  @valid_attrs %{ email: "email@example.com", password: "thisisapassword" }

  test "creates a session", %{conn: conn} do
    create_user

    response = create_session(conn, "email@example.com", "thisisapassword")
    
    assert response["data"]["jwt"]
    assert response["data"]["user"]["id"]
    assert response["data"]["user"]["email"]
  end

  test "deletes a session", %{conn: conn} do
    create_user
    session_response = create_session(conn, "email@example.com", "thisisapassword")

    conn
    |> put_req_header("authorization", session_response["data"]["jwt"])
    |> delete("/api/logout")
    |> json_response(200)
  end

  test "fails authorization", %{conn: conn} do
    create_user

    conn = post conn, "/api/login", email: "email@example.com", password: "wrong"
    response = json_response(conn, 422)
   
    assert response == %{"error" => "Unable to authenticate"} 
  end

  defp create_user do
    %User{}
    |> User.registration_changeset(@valid_attrs)
    |> Repo.insert!
  end

  defp create_session(conn, email, password) do
    post(conn, "/api/login", email: email, password: password)
    |> json_response(201)
  end

end