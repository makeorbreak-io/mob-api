defmodule Api.WorkshopControllerTest do
  use Api.ConnCase
  use Bamboo.Test, shared: true

  alias Api.{WorkshopAttendance, Email}

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

  test "lists all entries on index", %{conn: conn} do
    workshop = create_workshop

    conn = get conn, workshop_path(conn, :index)
    assert json_response(conn, 200)["data"] == [
      %{
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
        "short_date" => workshop.short_date
      }
    ]
  end

  test "shows chosen workshop", %{conn: conn} do
    workshop = create_workshop
  
    conn = get conn, workshop_path(conn, :show, workshop)
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
      "short_date" => workshop.short_date
    }
  end

  test "user can join workshops if there are vacancies", %{conn: conn, jwt: jwt, user: user} do
    workshop = create_workshop

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(workshop_path(conn, :join, workshop))

    assert response(conn, 201)
    assert_delivered_email Email.joined_workshop_email(user, workshop)
  end

  test "user can't join workshop if it's full", %{conn: conn, jwt: jwt} do
    workshop = create_workshop
    workshop_attendee = create_user(%{
      email: "example@email.com",
      first_name: "Jane",
      last_name: "doe",
      password: "thisisapassword"
    })

    Repo.insert! %WorkshopAttendance{user_id: workshop_attendee.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(workshop_path(conn, :join, workshop))

    assert json_response(conn, 422)["errors"] == "Workshop is already full"
  end

  test "user can delete attendance if he's a member", %{conn: conn, user: user, jwt: jwt} do
    workshop = create_workshop

    Repo.insert! %WorkshopAttendance{user_id: user.id, workshop_id: workshop.id}

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(workshop_path(conn, :leave, workshop))

    assert response(conn, 204)
  end

  test "user can't delete attendance if he's not a member", %{conn: conn, jwt: jwt} do
    workshop = create_workshop

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(workshop_path(conn, :leave, workshop))

    assert response(conn, 422)
  end
end