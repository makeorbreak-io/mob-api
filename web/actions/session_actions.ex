defmodule Api.SessionActions do
  use Api.Web, :action

  alias Api.{User, Repo, UserActions}
  alias Comeonin.Bcrypt
  alias Guardian.{Plug, Permissions}

  def current_user(conn) do
    Plug.current_resource(conn)
    |> UserActions.preload_user_data
  end

  def create(email, password) do
    user = Repo.get_by(User, email: String.downcase(email))
    |> UserActions.preload_user_data

    user
    |> check_password(password)
    |> sign_user(user)
  end

  def delete(conn) do
    revoke_claims(conn)
  end

  defp check_password(nil, _password), do: false
  defp check_password(user, password) do
    Bcrypt.checkpw(password, user.password_hash)
  end

  defp sign_user(false, _user), do: :wrong_credentials
  defp sign_user(true, user) do
    {:ok, jwt, _} = Guardian.encode_and_sign(user, :token, perms: %{"#{user.role}": Permissions.max})
    {:ok, jwt, user}
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Plug.claims(conn)

    Plug.current_token(conn)
    |> Guardian.revoke!(claims)

    conn
  end
end
