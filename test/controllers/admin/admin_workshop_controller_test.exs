defmodule Api.Admin.WorkshopControllerTest do
  use Api.ConnCase

  alias Api.{Workshop, User,}
  
  @valid_attrs %{
    slug: "some-content",
    name: "some content",
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

  test "endpoints are availale for admin users", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_workshop_path(conn, :index))

    assert json_response(conn, 200)["data"] == []
  end

  test "endpoints are locked for non admin users", %{conn: conn} do
    user = Repo.insert! %User{}

    {:ok, jwt, _} =
      Guardian.encode_and_sign(user, :token, perms: %{participant: Guardian.Permissions.max})

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(admin_workshop_path(conn, :index))

    assert json_response(conn, 401)
    assert json_response(conn, 401)["error"] == "Unauthorized"
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
      "participant_limit" => workshop.participant_limit,
      "year" => workshop.year,
      "speaker_image" => workshop.speaker_image,
      "banner_image" => workshop.banner_image
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

  test "updates workshop", %{conn: conn, jwt: jwt} do
    workshop = Repo.insert!(%Workshop{} |> Map.merge(@valid_attrs))

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_workshop_path(conn, :update, workshop), workshop: %{slug: "awesome-workshop"})

    assert json_response(conn, 200)["data"]["slug"]
    assert Repo.get_by(Workshop, slug: "awesome-workshop")
  end

  test "deletes chosen workshop", %{conn: conn, jwt: jwt} do
    workshop = Repo.insert!(%Workshop{} |> Map.merge(@valid_attrs))

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_workshop_path(conn, :delete, workshop))
    
    assert response(conn, 204)
    refute Repo.get_by(Workshop, slug: @valid_attrs.slug)
  end
end
