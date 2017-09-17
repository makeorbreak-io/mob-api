defmodule ApiWeb.Admin.BlogPostController do
  use Api.Web, :controller

  alias ApiWeb.{BlogPostActions, Controller.Errors}
  alias Guardian.Plug.{EnsureAuthenticated, EnsurePermissions}

  plug :scrub_params, "blogpost" when action in [:create, :update]
  plug EnsureAuthenticated, [handler: Errors]
  plug EnsurePermissions, [handler: Errors, admin: ~w(full)]

  def create(conn, %{"blogpost" => blogpost_params}) do
    case BlogPostActions.create(blogpost_params) do
      {:ok, blogpost} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", blogpost_path(conn, :show, blogpost))
        |> render("show.json", blogpost: blogpost)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "blogpost" => blogpost_params}) do
    case BlogPostActions.update(id, blogpost_params) do
      {:ok, blogpost} ->
        render(conn, "show.json", blogpost: blogpost)
      {:error, changeset} -> Errors.changeset(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    BlogPostActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end
