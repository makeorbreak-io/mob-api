defmodule Api.SessionControllerTest do
  use Api.ConnCase

  alias Api.{WorkshopAttendance}

  @valid_credentials %{
    email: "johndoe@example.com",
    password: "thisisapassword"
  }
  @invalid_credentials %{
    email: "johndoe@example.com",
    password: "wrong"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "user can login", %{conn: conn} do
    user = create_user
    team = create_team(user)

    conn = post(conn, session_path(conn, :create, @valid_credentials))

    assert json_response(conn, 201)["data"]["user"] == %{
      "bio" => user.bio,
      "birthday" => user.birthday,
      "college" => user.college,
      "company" => user.company,
      "display_name" => "#{user.first_name} #{user.last_name}",
      "email" => user.email,
      "employment_status" => nil,
      "first_name" => user.first_name,
      "github_handle" => nil,
      "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
      "id" => user.id,
      "invitations" => [],
      "last_name" => user.last_name,
      "linkedin_url" => user.linkedin_url,
      "role" => user.role,
      "team" => %{
        "name" => team.name,
        "applied" => team.applied,
        "id" => team.id,
        "invites" => [],
        "members" => [%{
          "id" => user.id,
          "display_name" => "#{user.first_name} #{user.last_name}",
          "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
          "role" => "owner"
        }],
        "role" => "owner",
        "project" => nil
      },
      "tshirt_size" => user.tshirt_size,
      "twitter_handle" => user.twitter_handle,
      "workshops" => []
    }
  end

  test "deletes a session", %{conn: conn} do
    user = create_user
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete("/api/logout")
    |> json_response(200)
  end

  test "jwt checking works", %{conn: conn} do
    user = create_user
    team = create_team(user)
    workshop = create_workshop
    Repo.insert! %WorkshopAttendance{user_id: user.id, workshop_id: workshop.id}

    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
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
      "team" => %{
        "role" => "owner",
        "name" => team.name,
        "applied" => team.applied,
        "id" => team.id,
        "invites" => [],
        "members" => [%{
          "id" => user.id,
          "display_name" => "#{user.first_name} #{user.last_name}",
          "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
          "role" => "owner"
        }],
        "project" => nil
      },
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
    conn = conn
    |> get(session_path(conn, :me))

    assert json_response(conn, 401)["errors"] == "Authentication required"
  end

  test "fails authorization", %{conn: conn} do
    create_user

    conn = post(conn, session_path(conn, :create, @invalid_credentials))

    assert json_response(conn, 422)["errors"] == "Wrong email or password"
  end
end
