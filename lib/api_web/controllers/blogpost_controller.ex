defmodule ApiWeb.BlogPostController do
  use Api.Web, :controller

  alias ApiWeb.{BlogPostActions}

  def index(conn, _params) do
    render(conn, "index.json", workshops: BlogPostActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: BlogPostActions.get(id))
  end
end
