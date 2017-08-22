defmodule Api.SessionController do
  use Api.Web, :controller

  alias Api.{User, UserActions, Repo, SessionView, ErrorView, UserView}
  alias Comeonin.Bcrypt
  alias Guardian.Plug

  def me(conn, _params) do
    case Plug.current_resource(conn) do
      %{id: id} -> 
        user = UserActions.get(id)
        |> Repo.preload([:workshops, team: [:members], invitations: [:host, :team, :invitee]])

        render(conn, UserView, "me.json", user: user)
      nil ->
        conn
        |> put_status(401)
        |> render(ErrorView, "error.json", error: "Authentication required")
    end
  end

  def create(conn, %{"email" => email, "password" => password}) do
    user =  Repo.get_by(User, email: String.downcase(email))
    |> Repo.preload([:workshops, team: [:members], invitations: [:host, :team, :invitee]])

    user
    |> check_password(password)
    |> handle_check_password(conn, user)
  end

  def delete(conn, _) do
    conn
    |> revoke_claims
    |> render(SessionView, "session.json", data: %{})
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> render(ErrorView, "error.json", error: "Authentication required")
  end

  def unauthorized(conn, _params) do
    conn
    |> put_status(401)
    |> render(ErrorView, "error.json", error: "Unauthorized")
  end

  defp check_password(nil, _password), do: false
  defp check_password(user, password) do
    Bcrypt.checkpw(password, user.password_hash)
  end

  defp handle_check_password(true, conn, user) do
    {:ok, jwt, _full_claims} =
      Guardian.encode_and_sign(user, :token, perms: %{"#{user.role}": Guardian.Permissions.max})

    conn
    |> put_status(:created)
    |> render(SessionView, "session.json", data: %{jwt: jwt, user: user})
  end
  defp handle_check_password(false, conn, _user) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "error.json", error: "Wrong email or password")
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Plug.claims(conn)

    token = Plug.current_token(conn)

    token
    |> Guardian.revoke!(claims)
    conn
  end
end
