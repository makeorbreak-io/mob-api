defmodule ApiWeb.BlogPostView do
  use Api.Web, :view

  alias ApiWeb.{UserView}

  def render("index.json", %{blogposts: blogposts}) do
    %{data: render_many(blogposts, __MODULE__, "blogpost_short.json")}
  end

  def render("show.json", %{blogpost: blogpost}) do
    %{data: render_one(blogpost, __MODULE__, "blogpost.json")}
  end

  def render("blogpost.json", %{blogpost: blogpost}) do
    %{
      slug: blogpost.slug,
      title: blogpost.title,
      category: blogpost.category,
      content: blogpost.content,
      banner_image: blogpost.banner_image,
      published_at: blogpost.published_at,
      user: if Ecto.assoc_loaded?(blogpost.user) do
        render_one(blogpost.user, UserView, "user_short.json")
      end,
    }
  end

  def render("blogpost_short.json", %{blogpost: blogpost}) do
    %{
      slug: blogpost.slug,
      name: blogpost.title,
      short_speaker: blogpost.category
    }
  end
end
