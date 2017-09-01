defmodule Api.AdminUserControllerTest do
  use Api.ConnCase

  alias Api.{User, WorkshopAttendance}

  @valid_attrs %{
    email: "user@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword",
    role: "admin"
  }

  @invalid_attrs %{}

  setup %{conn: conn} do
    admin = create_admin
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Guardian.Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "endpoints are availale for admin users", %{conn: conn, admin: admin, jwt: jwt} do
    team = create_team(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_user_path(conn, :index))

    assert json_response(conn, 200)["data"] == [%{
      "id" => admin.id,
      "first_name" => admin.first_name,
      "last_name" => admin.last_name,
      "email" => admin.email,
      "role" => admin.role,
      "display_name" => "#{admin.first_name} #{admin.last_name}",
      "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
      "birthday" => admin.birthday,
      "employment_status" => admin.employment_status,
      "college" => admin.college,
      "company" => admin.company,
      "github_handle" => admin.github_handle,
      "twitter_handle" => admin.twitter_handle,
      "linkedin_url" => admin.linkedin_url,
      "bio" => admin.bio,
      "inserted_at" => NaiveDateTime.to_iso8601(admin.inserted_at),
      "updated_at" => NaiveDateTime.to_iso8601(admin.updated_at),
      "team" => %{
        "id" => team.id,
        "name" => team.name,
        "applied" => team.applied,
        "role" => "owner",
      },
      "tshirt_size" => nil,
    }]
  end

  test "endpoints are locked for non admin users", %{conn: conn} do
    user = Repo.insert!(%User{})

    {:ok, jwt, _} =
      Guardian.encode_and_sign(user, :token, perms: %{participant: Guardian.Permissions.max})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_user_path(conn, :index))

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Unauthorized"
  end

  test "shows user", %{conn: conn, admin: admin, jwt: jwt} do
    team = create_team(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_user_path(conn, :show, admin))

    assert json_response(conn, 200)["data"] == %{
      "id" => admin.id,
      "first_name" => admin.first_name,
      "last_name" => admin.last_name,
      "email" => admin.email,
      "role" => admin.role,
      "display_name" => "#{admin.first_name} #{admin.last_name}",
      "gravatar_hash" => "fd876f8cd6a58277fc664d47ea10ad19",
      "birthday" => admin.birthday,
      "employment_status" => admin.employment_status,
      "college" => admin.college,
      "company" => admin.company,
      "github_handle" => admin.github_handle,
      "twitter_handle" => admin.twitter_handle,
      "linkedin_url" => admin.linkedin_url,
      "bio" => admin.bio,
      "inserted_at" => NaiveDateTime.to_iso8601(admin.inserted_at),
      "updated_at" => NaiveDateTime.to_iso8601(admin.updated_at),
      "team" => %{
        "id" => team.id,
        "name" => team.name,
        "applied" => team.applied,
        "role" => "owner",
      },
      "tshirt_size" => nil,
    }
  end

  test "updates user when data is valid", %{conn: conn, jwt: jwt} do
    user = Repo.insert! %User{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_user_path(conn, :update, user), user: @valid_attrs)

    updated_user = Repo.get_by(User, email: "user@example.com")

    assert json_response(conn, 200)["data"]["id"]
    assert updated_user.role == "admin"
  end

  test "doesn't update user when data is invalid", %{conn: conn, jwt: jwt} do
    user = Repo.insert! %User{}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_user_path(conn, :update, user), user: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes user", %{conn: conn, jwt: jwt} do
    user = Repo.insert! %User{}
    create_team(user)
    workshop = create_workshop
    Repo.insert! %WorkshopAttendance{user_id: user.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_user_path(conn, :delete, user))

    assert response(conn, 204)
    refute Repo.get(User, user.id)
  end
end
