defmodule ApiWeb.PresentationController do
  use Api.Web, :controller

  alias ApiWeb.MediumActions

  def get_latest_posts(conn, %{"count" => count}) do
    render(conn, "posts.json", posts: MediumActions.get_latest_posts(count))
  end
end
