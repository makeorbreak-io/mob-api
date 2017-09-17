defmodule ApiWeb.Admin.BlogPostView do
  use Api.Web, :view

  alias ApiWeb.{BlogPostView}

  def render("show.json", %{blogpost: blogpost}) do
    %{data: render_one(blogpost, BlogPostView, "blogpost.json")}
  end
end
