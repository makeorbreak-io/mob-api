defmodule Api.UserController do
  use Api.Web, :controller

  alias Api.{UserActions, SessionView, ChangesetView}

  plug :scrub_params, "user" when action in [:create, :update]

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
    case UserActions.update(id, user_params, "participant") do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    UserActions.delete(id)
    send_resp(conn, :no_content, "")
  end
end
