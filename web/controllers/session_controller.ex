defmodule Api.SessionController do
  use Api.Web, :controller

  alias Api.{User, UserActions, Repo, SessionView, ErrorView, UserView, ErrorController}
  alias Comeonin.Bcrypt
  alias Guardian.{Plug, Permissions}

  plug Guardian.Plug.EnsureAuthenticated,
    [handler: Api.ErrorController] when action in [:me]

  def me(conn, _params) do
    %{id: id} = Plug.current_resource(conn)

    user = UserActions.get(id)
    |> Repo.preload([:workshops, invitations: [:host, :team, :invitee]])
    |> UserActions.add_current_team

    render(conn, UserView, "me.json", user: user)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    user =  Repo.get_by(User, email: String.downcase(email))
    |> UserActions.add_current_team

    user
    |> check_password(password)
    |> handle_check_password(conn, user)
  end

  def delete(conn, _) do
    conn
    |> revoke_claims
    |> render(SessionView, "session.json", data: %{})
  end

  defp check_password(nil, _password), do: false
  defp check_password(user, password) do
    Bcrypt.checkpw(password, user.password_hash)
  end

  defp handle_check_password(true, conn, user) do
    {:ok, jwt, _full_claims} =
      Guardian.encode_and_sign(user, :token, perms: %{"#{user.role}": Permissions.max})

    conn
    |> put_status(:created)
    |> render(SessionView, "session.json", data: %{jwt: jwt, user: user})
  end

  defp handle_check_password(false, conn, _user) do
    ErrorController.handle_error(conn, :unprocessable_entity, "Wrong email or password")
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Plug.claims(conn)

    token = Plug.current_token(conn)
    |> Guardian.revoke!(claims)

    conn
  end
end
