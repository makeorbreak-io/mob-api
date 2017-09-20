defmodule ApiWeb.BlogPostController do
  use Api.Web, :controller

  alias ApiWeb.{BlogPostActions}

  def index(conn, _params) do
    render(conn, "index.json", blogposts: BlogPostActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", blogpost: BlogPostActions.get(id))
  end
end
