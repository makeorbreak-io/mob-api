defmodule Api.UserController do
  use Api.Web, :controller

  alias Api.{UserActions, SessionView, ChangesetView}

  plug :scrub_params, "user" when action in [:create, :update]
  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.SessionController] when action in [:update, :delete]

  def index(conn, _params) do
    render(conn, "index.json", users: UserActions.all)
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", user: UserActions.get(id))
  end

  def create(conn, %{"user" => user_params}) do
    case UserActions.create(user_params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, user))
        |> render(SessionView, "session.json", data: %{jwt: jwt, user: user})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserActions.update(conn, id, user_params) do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case UserActions.delete(conn, id) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Api.ChangesetView, "error.json", changeset: changeset)
      {:unauthorized} ->
        conn
        |> put_status(401)
        |> render(Api.ErrorView, "error.json", error: "Unauthorized")
    end
  end
end
