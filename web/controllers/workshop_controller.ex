defmodule Api.WorkshopController do
  use Api.Web, :controller

  alias Api.{WorkshopActions,}

  def index(conn, _params) do
    render(conn, "index.json", workshops: WorkshopActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", workshop: WorkshopActions.get(id))
  end
end