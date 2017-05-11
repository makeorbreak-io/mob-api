defmodule Api.SessionController do
  use Api.Web, :controller

  alias Api.{User, Repo}

  def create(conn, %{"email" => email, "password" => password}) do
    user = get_user(email)

    user
    |> check_password(password)
    |> handle_check_password(conn, user)
  end

  def delete(conn, _) do
    conn
    |> revoke_claims
    |> render(Api.SessionView, "session.json", data: %{})
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> render(Api.ErrorView, "error.json", error: "Authentication required")
  end

  defp get_user(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  defp check_password(nil, _password), do: false
  defp check_password(user, password) do
    Comeonin.Bcrypt.checkpw(password, user.password_hash)
  end

  defp handle_check_password(true, conn, user) do
    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

    conn
    |> put_status(:created)
    |> render(Api.SessionView, "session.json", data: %{jwt: jwt, user: user})
  end
  defp handle_check_password(false, conn, _user) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(Api.ErrorView, "error.json", error: "Unable to authenticate")
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Guardian.Plug.claims(conn)
    
    Guardian.Plug.current_token(conn)
    |> Guardian.revoke!(claims)
    conn
  end
end