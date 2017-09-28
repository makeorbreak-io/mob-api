defmodule Api.Accounts do
  import Ecto.Query, warn: false

  alias Api.{Mailer, Repo}
  alias Api.Accounts.User

  alias Api.{Mailer}
  alias ApiWeb.{UserHelper, Invite, Email, CompetitionActions}
  alias Comeonin.Bcrypt
  alias Guardian.{Plug, Permissions}

  def current_user(conn) do
    Plug.current_resource(conn)
    |> preload_user_data
  end

  def create_session(email, password) do
    Repo.get_by(User, email: email)
    |> check_password(password)
    |> sign_user
  end

  def delete_session(conn) do
    revoke_claims(conn)
  end

  def list_users do
    Enum.map(Repo.all(User), fn(user) -> preload_user_data(user) end)
  end

  def get_user(id) do
    Repo.get!(User, id)
    |> preload_user_data
  end

  def create_user(user_params) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        from(i in Invite, where: i.email == ^user.email, update: [
          set: [invitee_id: ^user.id]
        ]) |> Repo.update_all([])

        Email.registration_email(user) |> Mailer.deliver_later

        {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :token)

        {:ok, jwt, preload_user_data(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_user(current_user, id, user_params) do
    user = Repo.get!(User, id)

    changeset = apply(User, String.to_atom("#{current_user.role}_changeset"),
      [user, user_params])

    case Repo.update(changeset) do
      {:ok, user} -> {:ok, preload_user_data(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_user(current_user, id) do
    user = Repo.get!(User, id)

    if user.id == current_user.id do
      {Repo.delete(user)}
    else
      {:unauthorized, :unauthorized}
    end
  end

  def delete_any_user(id) do
    user = Repo.get!(User, id)
    Repo.delete!(user)
  end

  def toggle_checkin(id, value) do
    case CompetitionActions.voting_status do
      :started -> :already_started
      _ ->
        user = Repo.get!(User, id)

        changeset = User.admin_changeset(user, %{checked_in: value})

        case Repo.update(changeset) do
          {:ok, user} ->
            value && (Email.checkin_email(user) |> Mailer.deliver_later)
            {:ok, preload_user_data(user)}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def preload_user_data(user) do
    user = user |> Repo.preload([
      :workshops,
      invitations: [:host, :team, :invitee],
      teams: [
        team: [
          :invites,
          members: [:user],
        ]
      ],
    ])

    # Change this condition when years are added to teams
    membership = List.first(user.teams)

    Map.put(user, :team, membership)
  end

  def get_auth_token(email) do
    Repo.get_by(User, email: email)
    |> add_pwd_recovery_data()
  end

  def recover_password(token, new_password) do
    Repo.get_by(User, pwd_recovery_token: token)
    |> maybe_update_password(new_password)
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
    {:ok, jwt, preload_user_data(user)}
  end

  defp revoke_claims(conn) do
    {:ok, claims} = Plug.claims(conn)

    Plug.current_token(conn)
    |> Guardian.revoke!(claims)

    conn
  end

  defp add_pwd_recovery_data(nil), do: :user_not_found
  defp add_pwd_recovery_data(user) do
    changeset = User.changeset(user, %{
      pwd_recovery_token: UserHelper.generate_token(),
      pwd_recovery_token_expiration: UserHelper.calculate_token_expiration()
    })

    case Repo.update(changeset) do
      {:ok, user} ->
        Email.recover_password_email(user) |> Mailer.deliver_later
        {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp maybe_update_password(nil, _), do: :invalid_token
  defp maybe_update_password(user, new_password) do
    now = DateTime.utc_now

    if DateTime.compare(now, user.pwd_recovery_token_expiration) == :lt do
      changeset = User.registration_changeset(user, %{password: new_password})

      Repo.update(changeset)
    else
      :expired_token
    end
  end
end
