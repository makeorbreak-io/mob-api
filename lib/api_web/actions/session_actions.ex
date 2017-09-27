defmodule ApiWeb.SessionActions do
  use Api.Web, :action

  alias ApiWeb.{User, Repo, UserActions}
  alias Comeonin.Bcrypt
  alias Guardian.{Plug, Permissions}

  def current_user(conn) do
    Plug.current_resource(conn)
    |> UserActions.preload_user_data
  end

  def create(email, password) do
    Repo.get_by(User, email: email)
    |> check_password(password)
    |> sign_user
  end

  def delete(conn) do
    revoke_claims(conn)
  end

  defp check_password(nil, _password), do: {:error, :wrong_credentials}
  defp check_password(user, password) do
    Bcrypt.checkpw(password, user.password_hash) && {:ok, user} || {:error, :wrong_credentials}
  end

  defp sign_user({:error, error}), do: error
  defp sign_user({:ok, user}) do
    {:ok, jwt, _} = Guardian.encode_and_sign(
      user,
      :token,
      perms: %{"#{user.role}": Permissions.max},
    )
    {:ok, jwt, UserActions.preload_user_data(user)}
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Plug.claims(conn)

    Plug.current_token(conn)
    |> Guardian.revoke!(claims)

    conn
  end
end
