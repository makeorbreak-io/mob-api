defmodule Api.WorkshopControllerTest do
  use Api.ConnCase

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, workshop_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
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
      "participant_limit" => workshop.participant_limit,
      "year" => workshop.year,
      "speaker_image" => workshop.speaker_image,
      "banner_image" => workshop.banner_image
    }
  end
end