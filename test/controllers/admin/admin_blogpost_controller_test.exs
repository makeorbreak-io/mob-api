defmodule ApiWeb.Admin.BlogPostControllerTest do
  use ApiWeb.ConnCase

  alias ApiWeb.{BlogPost}

  @valid_attrs %{
    slug: "some-content",
    title: "some content",
    category: "MOB17",
    content: "lorem ipsum"
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

  test "creates blogpost when data is valid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_blog_post_path(conn, :create), blogpost: @valid_attrs)

    assert json_response(conn, 201)["data"]["slug"]
    assert Repo.get_by(BlogPost, slug: @valid_attrs.slug)
  end

  test "doesn't create blogpost when data is invalid", %{conn: conn, jwt: jwt} do
    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(admin_blog_post_path(conn, :create), blogpost: @invalid_attrs)

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates blogpost if data is valid", %{conn: conn, jwt: jwt, admin: admin} do
    blogpost = create_blogpost(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_blog_post_path(conn, :update, blogpost), blogpost: %{slug: "awesome-blogpost"})

    assert json_response(conn, 200)["data"]["slug"]
    assert Repo.get_by(BlogPost, slug: "awesome-blogpost")
  end

  test "doesn't update blogpost if data is invalid", %{conn: conn, jwt: jwt, admin: admin} do
    blogpost = create_blogpost(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(admin_blog_post_path(conn, :update, blogpost), blogpost: %{slug: nil})

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen blogpost", %{conn: conn, jwt: jwt, admin: admin} do
    blogpost = create_blogpost(admin)

    conn = conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> delete(admin_blog_post_path(conn, :delete, blogpost))

    assert response(conn, 204)
    refute Repo.get_by(BlogPost, slug: @valid_attrs.slug)
  end
end
