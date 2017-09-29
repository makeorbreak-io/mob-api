defmodule ApiWeb.Admin.WorkshopControllerTest do
  use ApiWeb.ConnCase

  alias Api.{Workshops.Workshop, Workshops.Attendance}
  import Api.Accounts.User, only: [display_name: 1, gravatar_hash: 1]

  @valid_attrs %{
    slug: "some-content",
    name: "some content",
  }
  @invalid_attrs %{}

  setup %{conn: conn} do
    admin = create_admin()
    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Guardian.Permissions.max})

    {:ok, %{
      admin: admin,
      jwt: jwt,
      conn: put_req_header(conn, "content-type", "application/json")
    }}
  end

  test "endpoints are availale for admin users", %{conn: conn, jwt: jwt} do
    workshop = create_workshop()
    attendee = create_user()
    attendance = Repo.insert! %Attendance{user_id: attendee.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_workshop_path(conn, :index))

    assert json_response(conn, 200)["data"] == [
      %{
        "slug" => workshop.slug,
        "name" => workshop.name,
        "summary" => workshop.summary,
        "description" => workshop.description,
        "speaker" => workshop.speaker,
        "participants" => 1,
        "participant_limit" => workshop.participant_limit,
        "year" => workshop.year,
        "speaker_image" => workshop.speaker_image,
        "banner_image" => workshop.banner_image,
        "short_speaker" => workshop.short_speaker,
        "short_date" => workshop.short_date,
        "attendees" => [%{
          "id" => attendee.id,
          "email" => attendee.email,
          "display_name" => display_name(attendee),
          "gravatar_hash" => gravatar_hash(attendee),
          "first_name" => attendee.first_name,
          "last_name" => attendee.last_name,
          "tshirt_size" => attendee.tshirt_size,
          "checked_in" => attendance.checked_in
        }]
      }
    ]
  end

  test "endpoints are locked for non admin users", %{conn: conn} do
    user = create_user()

    {:ok, jwt, _} =
      Guardian.encode_and_sign(user, :token, perms: %{participant: Guardian.Permissions.max})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_workshop_path(conn, :index))

    assert json_response(conn, 401)
    assert json_response(conn, 401)["errors"] == "Unauthorized"
  end

  test "shows workshop", %{conn: conn, jwt: jwt} do
    workshop = Repo.insert!(%Workshop{} |> Map.merge(@valid_attrs))

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_workshop_path(conn, :show, workshop))

    assert json_response(conn, 200)["data"] == %{
      "slug" => workshop.slug,
      "name" => workshop.name,
      "summary" => workshop.summary,
      "description" => workshop.description,
      "speaker" => workshop.speaker,
      "participants" => 0,
      "participant_limit" => workshop.participant_limit,
      "year" => workshop.year,
      "speaker_image" => workshop.speaker_image,
      "banner_image" => workshop.banner_image,
      "short_speaker" => workshop.short_speaker,
      "short_date" => workshop.short_date,
      "attendees" => []
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn, jwt: jwt} do
    assert_error_sent 404, fn ->
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(admin_workshop_path(conn, :show, "random-slug"))
    end
  end

  test "creates workshop when data is valid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_workshop_path(conn, :create), workshop: @valid_attrs)

    assert json_response(conn, 201)["data"]["slug"]
    assert Repo.get_by(Workshop, slug: @valid_attrs.slug)
  end

  test "doesn't create workshop when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_workshop_path(conn, :create), workshop: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates workshop if data is valid", %{conn: conn, jwt: jwt} do
    workshop = create_workshop()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_workshop_path(conn, :update, workshop), workshop: %{slug: "awesome-workshop"})

    assert json_response(conn, 200)["data"]["slug"]
    assert Repo.get_by(Workshop, slug: "awesome-workshop")
  end

  test "doesn't update workshop if data is invalid", %{conn: conn, jwt: jwt} do
    workshop = create_workshop()

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_workshop_path(conn, :update, workshop), workshop: %{slug: nil})

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen workshop", %{conn: conn, jwt: jwt} do
    workshop = Repo.insert!(%Workshop{} |> Map.merge(@valid_attrs))

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_workshop_path(conn, :delete, workshop))

    assert response(conn, 204)
    refute Repo.get_by(Workshop, slug: @valid_attrs.slug)
  end

  test "checks in user in workshop", %{conn: conn, jwt: jwt} do
    user = create_user()
    workshop = create_workshop()
    attendance = Repo.insert! %Attendance{user_id: user.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_workshop_path(conn, :checkin, workshop, user))

    assert json_response(conn, 200)["data"] == %{
      "slug" => workshop.slug,
      "name" => workshop.name,
      "summary" => workshop.summary,
      "description" => workshop.description,
      "speaker" => workshop.speaker,
      "participants" => 1,
      "participant_limit" => workshop.participant_limit,
      "year" => workshop.year,
      "speaker_image" => workshop.speaker_image,
      "banner_image" => workshop.banner_image,
      "short_speaker" => workshop.short_speaker,
      "short_date" => workshop.short_date,
      "attendees" => [%{
        "id" => user.id,
        "email" => user.email,
        "display_name" => display_name(user),
        "gravatar_hash" => gravatar_hash(user),
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "tshirt_size" => user.tshirt_size,
        "checked_in" => !attendance.checked_in
      }]
    }

    attendance = Repo.get_by(Attendance, user_id: user.id, workshop_id: workshop.id)
    assert attendance.checked_in == true
  end

  test "removes user checkin in workshop", %{conn: conn, jwt: jwt} do
    user = create_user()
    workshop = create_workshop()
    attendance = Repo.insert! %Attendance{
      user_id: user.id,
      workshop_id: workshop.id,
      checked_in: true
    }

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_workshop_path(conn, :remove_checkin, workshop, user))

    assert json_response(conn, 200)["data"] == %{
      "slug" => workshop.slug,
      "name" => workshop.name,
      "summary" => workshop.summary,
      "description" => workshop.description,
      "speaker" => workshop.speaker,
      "participants" => 1,
      "participant_limit" => workshop.participant_limit,
      "year" => workshop.year,
      "speaker_image" => workshop.speaker_image,
      "banner_image" => workshop.banner_image,
      "short_speaker" => workshop.short_speaker,
      "short_date" => workshop.short_date,
      "attendees" => [%{
        "id" => user.id,
        "email" => user.email,
        "display_name" => display_name(user),
        "gravatar_hash" => gravatar_hash(user),
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "tshirt_size" => user.tshirt_size,
        "checked_in" => !attendance.checked_in
      }]
    }

    attendance = Repo.get_by(Attendance, user_id: user.id, workshop_id: workshop.id)
    assert attendance.checked_in == false
  end
end
