defmodule Api.SessionControllerTest do
  use Api.ConnCase

  alias Api.{WorkshopAttendance}

  test "creates a session", %{conn: conn} do
    create_user

    response = create_session(conn, "johndoe@example.com", "thisisapassword")

    data = response["data"]
    
    assert data["jwt"]
    assert data["user"]["id"]
    assert data["user"]["email"]
  end

  test "deletes a session", %{conn: conn} do
    create_user
    session_response = create_session(conn, "johndoe@example.com", "thisisapassword")

    conn
    |> put_req_header("authorization", "Bearer #{session_response["data"]["jwt"]}")
    |> delete("/api/logout")
    |> json_response(200)
  end

  test "jwt checking works", %{conn: conn} do
    user = create_user
    workshop = create_workshop
    Repo.insert! %WorkshopAttendance{user_id: user.id, workshop_id: workshop.id}

    response = create_session(conn, "johndoe@example.com", "thisisapassword")
    
    conn = conn
    |> put_req_header("authorization", "Bearer #{response["data"]["jwt"]}")
    |> get(session_path(conn, :me))

    assert json_response(conn, 200)["data"] == %{
      "id" => user.id,
      "email" => user.email,
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
      "team" => nil,
      "invitations" => [],
      "role" => user.role,
      "tshirt_size" => nil,
      "workshops" => [%{
        "slug" => workshop.slug,
        "name" => workshop.name,
        "short_speaker" => workshop.short_speaker
      }]
    }
  end

  test "jwt checking returns 401 without token", %{conn: conn} do
    response = conn    
    |> get("api/me")
    |> json_response(401)

    assert response["error"] == "Authentication required"
  end

  test "fails authorization", %{conn: conn} do
    create_user

    conn = post conn, "/api/login", email: "johndoe@example.com", password: "wrong"
    response = json_response(conn, 422)
   
    assert response == %{"error" => "Unable to authenticate"} 
  end
end