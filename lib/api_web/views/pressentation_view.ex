defmodule ApiWeb.PresentationView do
  use Api.Web, :view

  def render("posts.json", %{posts: posts}) do
    %{data: posts}
  end
end
