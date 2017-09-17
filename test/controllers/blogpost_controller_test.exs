defmodule ApiWeb.BlogPostControllerTest do
  use ApiWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    user = create_user()
    blogpost = create_blogpost(user)

    conn = get conn, blog_post_path(conn, :index)
    assert json_response(conn, 200)["data"] == [
      %{
        "slug" => blogpost.slug,
        "title" => blogpost.title,
        "category" => blogpost.category,
      }
    ]
  end

  test "shows chosen blogpost", %{conn: conn} do
    user = create_user()
    blogpost = create_blogpost(user)

    conn = get conn, blog_post_path(conn, :show, blogpost)
    assert json_response(conn, 200)["data"] == %{
        "slug" => blogpost.slug,
        "title" => blogpost.title,
        "content" => blogpost.content,
        "category" => blogpost.category,
        "banner_image" => blogpost.banner_image,
        "published_at" => blogpost.published_at,
        "user" => %{
          "display_name" => "#{user.first_name} #{user.last_name}",
          "gravatar_hash" => UserHelper.gravatar_hash(user),
          "first_name" => user.first_name,
          "last_name" => user.last_name,
          "id" => user.id,
          "tshirt_size" => user.tshirt_size
        },
    }
  end
end
